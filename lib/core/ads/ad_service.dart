import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

/// Owns consent and the two iOS full-screen ad formats.
class AdService extends ChangeNotifier with WidgetsBindingObserver {
  // Paste your iOS AdMob ad unit IDs here (use IDs containing a slash).
  // The separate AdMob app ID belongs in ios/Runner/Info.plist.
  static const _iosAppOpenId = 'ca-app-pub-2535194044471316/9731512130';
  static const _iosInterstitialId = 'ca-app-pub-2535194044471316/3996893167';

  bool _started = false;
  bool _ready = false;
  bool _showingFullScreen = false;
  bool _loadingOpen = false;
  bool _loadingInterstitial = false;
  bool _privacyOptionsRequired = false;
  bool _disposed = false;
  bool _launchFinished = false;
  final _openLoad = Completer<void>();
  final _interstitialLoad = Completer<void>();

  DateTime? _backgroundedAt;
  DateTime? _openLoadedAt;
  DateTime? _lastFullScreenAt;
  AppOpenAd? _openAd;
  InterstitialAd? _interstitialAd;

  bool get privacyOptionsRequired => _privacyOptionsRequired;
  bool get _supported => !kIsWeb && Platform.isIOS;
  String get _appOpenId => _iosAppOpenId;
  String get _interstitialId => _iosInterstitialId;

  /// Consent is completed before requests. Network loading never holds the
  /// splash indefinitely, and late arrivals are reserved for future breaks.
  Future<void> preloadForLaunch() async {
    await start();
    if (!_ready || _disposed) return;
    await Future.wait([
      if (_appOpenId.isNotEmpty) _openLoad.future,
      if (_interstitialId.isNotEmpty) _interstitialLoad.future,
    ]).timeout(const Duration(seconds: 5), onTimeout: () => <void>[]);
  }

  Future<void> showLaunchAd() async {
    final done = Completer<void>();
    _showAppOpen(onFinished: () => done.complete());
    await done.future;
    _launchFinished = true;
  }

  Future<void> start() async {
    if (_started || !_supported) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    try {
      await _startAfterConsent();
    } catch (error) {
      // Ads are optional; a platform or network failure must not affect health features.
      debugPrint('Ads unavailable: $error');
    }
  }

  Future<void> _startAfterConsent() async {
    // UMP requires a fresh consent-info update on every app launch.
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!updated.isCompleted) updated.complete();
      },
      (error) {
        debugPrint('Ad consent update: ${error.message}');
        if (!updated.isCompleted) updated.complete();
      },
    );
    await updated.future.timeout(const Duration(seconds: 10));
    if (_disposed) return;
    await _refreshPrivacyOptions();
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) debugPrint('Ad consent form: ${error.message}');
    });
    await _refreshPrivacyOptions();
    if (!await ConsentInformation.instance.canRequestAds()) return;

    if (Platform.isIOS) {
      // A native ATT prompt follows the user's choice in the consent form.
      // Denial is respected and never blocks use of the app.
      final status = await Permission.appTrackingTransparency.status;
      if (status.isDenied) {
        await Permission.appTrackingTransparency.request();
      }
    }

    await MobileAds.instance.initialize();
    if (_disposed) return;
    _ready = true;
    _loadAppOpen();
    _loadInterstitial();
  }

  Future<void> _refreshPrivacyOptions() async {
    final required =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    if (!_disposed && _privacyOptionsRequired != required) {
      _privacyOptionsRequired = required;
      notifyListeners();
    }
  }

  Future<void> showPrivacyOptions() async {
    if (!_started) return;
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('Privacy options: ${error.message}');
    });
    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (!canRequestAds) {
      _ready = false;
      _openAd?.dispose();
      _interstitialAd?.dispose();
      _openAd = null;
      _interstitialAd = null;
    } else if (!_ready) {
      await MobileAds.instance.initialize();
      _ready = true;
      _loadAppOpen();
      _loadInterstitial();
    }
  }

  void _loadInterstitial() {
    if (!_ready ||
        _disposed ||
        _interstitialId.isEmpty ||
        _loadingInterstitial ||
        _interstitialAd != null) {
      return;
    }
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          if (!_interstitialLoad.isCompleted) _interstitialLoad.complete();
          if (_disposed || !_ready) {
            ad.dispose();
            return;
          }
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          if (!_interstitialLoad.isCompleted) _interstitialLoad.complete();
          debugPrint('Interstitial load: $error');
        },
      ),
    );
  }

  Future<void> showInterstitialAfterSave() async {
    final finished = Completer<void>();
    showInterstitialAtTabBreak(() => finished.complete());
    await finished.future;
  }

  void showInterstitialAtTabBreak(VoidCallback continueNavigation) {
    final now = DateTime.now();
    final ad = _interstitialAd;
    if (!_ready || _disposed || _showingFullScreen || ad == null) {
      if (ad == null) _loadInterstitial();
      continueNavigation();
      return;
    }
    _interstitialAd = null;
    _showingFullScreen = true;
    _lastFullScreenAt = now;

    var completed = false;
    void finish(InterstitialAd ad) {
      if (completed) return;
      completed = true;
      ad.dispose();
      _showingFullScreen = false;
      continueNavigation();
      _loadInterstitial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial show: $error');
        finish(ad);
      },
    );
    unawaited(
      ad.show().catchError((Object error) {
        debugPrint('Interstitial show: $error');
        finish(ad);
      }),
    );
  }

  void _loadAppOpen() {
    if (!_ready ||
        _disposed ||
        _appOpenId.isEmpty ||
        _loadingOpen ||
        _openAd != null) {
      return;
    }
    _loadingOpen = true;
    AppOpenAd.load(
      adUnitId: _appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingOpen = false;
          if (!_openLoad.isCompleted) _openLoad.complete();
          if (_disposed || !_ready) {
            ad.dispose();
            return;
          }
          _openLoadedAt = DateTime.now();
          _openAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingOpen = false;
          if (!_openLoad.isCompleted) _openLoad.complete();
          debugPrint('App open load: $error');
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_launchFinished) _showAppOpenIfEligible();
    }
  }

  void _showAppOpenIfEligible() {
    if (!_ready || _showingFullScreen) return;
    final now = DateTime.now();
    if (_backgroundedAt == null ||
        now.difference(_backgroundedAt!) < const Duration(seconds: 30) ||
        (_lastFullScreenAt != null &&
            now.difference(_lastFullScreenAt!) < const Duration(minutes: 30))) {
      return;
    }
    _showAppOpen();
  }

  void _showAppOpen({VoidCallback? onFinished}) {
    if (!_ready || _disposed || _showingFullScreen) {
      onFinished?.call();
      return;
    }
    final now = DateTime.now();
    final ad = _openAd;
    if (ad == null) {
      _loadAppOpen();
      onFinished?.call();
      return;
    }
    if (_openLoadedAt == null ||
        now.difference(_openLoadedAt!) >= const Duration(hours: 4)) {
      ad.dispose();
      _openAd = null;
      _loadAppOpen();
      onFinished?.call();
      return;
    }
    _openAd = null;
    _showingFullScreen = true;
    _lastFullScreenAt = now;
    var finished = false;
    void finish(AppOpenAd ad) {
      if (finished) return;
      finished = true;
      ad.dispose();
      _showingFullScreen = false;
      onFinished?.call();
      _loadAppOpen();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App open show: $error');
        finish(ad);
      },
    );
    unawaited(
      ad.show().catchError((Object error) {
        debugPrint('App open show: $error');
        finish(ad);
      }),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _openAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
