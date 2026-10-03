import 'package:flutter/material.dart';

import '../../../core/design_system/app_theme.dart';
import '../../ai_agent/domain/luna_message.dart';
import '../../pregnancy/domain/pregnancy_timeline.dart';
import '../../shared/domain/health_mode_service.dart';
import '../../shared/domain/health_models.dart';
import '../data/ai_chef_service.dart';
import '../domain/ai_chef_models.dart';

class AiChefPage extends StatefulWidget {
  const AiChefPage({
    super.key,
    required this.profile,
    required this.healthContext,
  });
  final UserProfile profile;
  final ActiveHealthContext healthContext;
  @override
  State<AiChefPage> createState() => _AiChefPageState();
}

class _AiChefPageState extends State<AiChefPage> with WidgetsBindingObserver {
  final _service = const AiChefService();
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  late final AiChefPreferences _context;
  late List<LunaMessage> _messages;
  bool _sending = false;
  String? _failedText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focus.addListener(_scrollToLatest);
    _context = AiChefPreferences.defaults(
      _stage(),
      pregnancyWeek: widget.healthContext.isPregnancy
          ? PregnancyTimeline.fromDueDate(widget.profile.estimatedDueDate)?.week
          : null,
    );
    _messages = [
      const LunaMessage(
        text:
            'Hello, I’m AI Chef. Tell me what you feel like eating, what you have at home, or any foods you would like to avoid. I can help you make something lovely and practical today.',
        isUser: false,
      ),
    ];
  }

  AiChefStage _stage() {
    if (widget.healthContext.isPregnancy) {
      return AiChefStage.pregnant;
    }
    if (widget.profile.goals.contains(TrackingGoal.conceive)) {
      return AiChefStage.tryingToConceive;
    }
    if (widget.healthContext.isPeriod) {
      return AiChefStage.period;
    }
    return AiChefStage.wellness;
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_focus.hasFocus) _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? message, bool retry = false]) async {
    final text = (message ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    if (!retry) {
      _messages.add(LunaMessage(text: text, isUser: true));
    } else if (_messages.isNotEmpty && _messages.last.isError) {
      _messages.removeLast();
    }
    _input.clear();
    setState(() {
      _sending = true;
      _failedText = null;
    });
    _scrollToLatest();
    try {
      final history = _messages.where((message) => !message.isError).toList();
      if (history.isNotEmpty && history.last.isUser) history.removeLast();
      final reply = await _service.reply(
        userMessage: text,
        history: history,
        context: _context,
      );
      if (mounted) {
        setState(() => _messages.add(LunaMessage(text: reply, isUser: false)));
      }
    } on AiChefException catch (error) {
      if (mounted) {
        setState(() {
          _failedText = text;
          _messages.add(
            LunaMessage(text: error.message, isUser: false, isError: true),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToLatest();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.removeListener(_scrollToLatest);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      surfaceTintColor: Colors.transparent,
      title: const Text('AI Chef'),
      actions: [
        IconButton(
          tooltip: 'Start a new food chat',
          onPressed: _sending
              ? null
              : () => setState(() {
                  _messages = [_messages.first];
                  _failedText = null;
                }),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.lg,
            ),
            children: [
              _chefTable(),
              const SizedBox(height: AppSpace.lg),
              ..._messages.map(_bubble),
              if (_messages.length == 1) ...[
                const SizedBox(height: AppSpace.xs),
                _promptGrid(),
              ],
              if (_sending) _thinkingCard(),
            ],
          ),
        ),
        _composer(),
      ],
    ),
  );

  Widget _chefTable() => Container(
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.rose.withValues(alpha: .55),
          AppColors.lavender.withValues(alpha: .35),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: AppColors.rose.withValues(alpha: .55)),
      borderRadius: BorderRadius.circular(AppRadius.large),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.plum,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR CHEF’S TABLE',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.berry),
              ),
              const SizedBox(height: 3),
              Text(
                'Let’s make today feel delicious.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              Text(
                '${_context.stage.label} • recipes made around your real life',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: .72),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _promptGrid() {
    const prompts = [
      _ChefPrompt(
        title: 'I need a comforting dinner',
        subtitle: 'Warm and gentle',
        icon: Icons.soup_kitchen_outlined,
        request: 'I need a comforting dinner.',
      ),
      _ChefPrompt(
        title: 'What can I make in 20 minutes?',
        subtitle: 'Quick but lovely',
        icon: Icons.timer_outlined,
        request: 'What can I make in 20 minutes?',
      ),
      _ChefPrompt(
        title: 'How can I use chickpeas?',
        subtitle: 'Make pantry magic',
        icon: Icons.eco_outlined,
        request: 'How can I use chickpeas?',
      ),
      _ChefPrompt(
        title: 'Give me a quick breakfast',
        subtitle: 'A softer start',
        icon: Icons.wb_sunny_outlined,
        request: 'Give me a quick breakfast.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A little inspiration',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpace.sm),
        ...prompts.map(
          (prompt) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                onTap: () => _send(prompt.request),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lavender.withValues(alpha: .16),
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.rose.withValues(alpha: .45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          prompt.icon,
                          color: AppColors.berry,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prompt.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              prompt.subtitle,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 19,
                        color: AppColors.berry,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _thinkingCard() => Container(
    margin: const EdgeInsets.only(top: AppSpace.md),
    padding: const EdgeInsets.all(AppSpace.sm),
    decoration: BoxDecoration(
      color: AppColors.rose.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            'AI Chef is preparing something lovely…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.plum,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _composer() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        border: Border(
          top: BorderSide(color: AppColors.line.withValues(alpha: .8)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 5, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCFC),
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: [
            BoxShadow(
              color: AppColors.plum.withValues(alpha: .05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                focusNode: _focus,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: _sending ? null : (_) => _send(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: 'Ask for a recipe, swap, or meal idea…',
                ),
              ),
            ),
            Material(
              color: _sending ? AppColors.muted : AppColors.plum,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Send message to AI Chef',
                onPressed: _sending ? null : _send,
                icon: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _bubble(LunaMessage message) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.md, left: AppSpace.xxl),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.plum,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.medium),
                topRight: Radius.circular(AppRadius.medium),
                bottomLeft: Radius.circular(AppRadius.medium),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Text(
              message.text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md, right: AppSpace.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: message.isError
              ? AppColors.rose.withValues(alpha: .18)
              : const Color(0xFFFFFCFC),
          border: Border.all(
            color: message.isError ? AppColors.rose : AppColors.line,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(AppRadius.large),
            bottomLeft: Radius.circular(AppRadius.large),
            bottomRight: Radius.circular(AppRadius.large),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.plum.withValues(alpha: .035),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: message.isError
                        ? AppColors.rose.withValues(alpha: .5)
                        : AppColors.lavender.withValues(alpha: .35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    message.isError
                        ? Icons.info_outline_rounded
                        : Icons.restaurant_menu_rounded,
                    color: message.isError
                        ? AppColors.critical
                        : AppColors.berry,
                    size: 17,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Chef',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: AppColors.berry),
                    ),
                    Text(
                      message.isError ? 'Kitchen connection' : 'Kitchen notes',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            _chefText(message.text),
            if (message.isError && _failedText != null) ...[
              const SizedBox(height: AppSpace.xs),
              TextButton.icon(
                onPressed: () => _send(_failedText, true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chefText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final stepPattern = RegExp(r'^(\d+)[.)]\s*(.+)$');
    const labels = [
      'meal:',
      'why it suits:',
      'time:',
      'ingredients:',
      'steps:',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final step = stepPattern.firstMatch(line);
        if (step != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.rose,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    step.group(1)!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: AppColors.plum,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    step.group(2)!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        }
        final isLabel = labels.any(
          (label) => line.toLowerCase().startsWith(label),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: Text(
            line,
            style: isLabel
                ? Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.plum)
                : Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
          ),
        );
      }).toList(),
    );
  }
}

class _ChefPrompt {
  const _ChefPrompt({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.request,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String request;
}
