import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../design_system/app_theme.dart';
import '../widgets/premium_widgets.dart';

Future<void> showPermissionsOnboardingSheet(
  BuildContext context, {
  required Future<void> Function() onComplete,
  required Future<bool> Function() onRequestNotifications,
}) => showModalBottomSheet<void>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _PermissionsOnboardingSheet(
    onComplete: onComplete,
    onRequestNotifications: onRequestNotifications,
  ),
);

class _PermissionsOnboardingSheet extends StatefulWidget {
  const _PermissionsOnboardingSheet({
    required this.onComplete,
    required this.onRequestNotifications,
  });
  final Future<void> Function() onComplete;
  final Future<bool> Function() onRequestNotifications;

  @override
  State<_PermissionsOnboardingSheet> createState() =>
      _PermissionsOnboardingSheetState();
}

class _PermissionsOnboardingSheetState
    extends State<_PermissionsOnboardingSheet> {
  final _statuses = <Permission, PermissionStatus>{};

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .88,
    ),
    padding: const EdgeInsets.fromLTRB(
      AppSpace.lg,
      AppSpace.sm,
      AppSpace.lg,
      AppSpace.xl,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    child: ListView(
      shrinkWrap: true,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          'A few permissions\nfor your private space.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Choose what feels right. These permissions only support features you choose to use, and you can change them in phone settings later.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpace.lg),
        _PermissionRequestCard(
          icon: Icons.notifications_none,
          title: 'Reminders',
          description: 'Private appointment and health reminders.',
          status: _statuses[Permission.notification],
          onRequest: () => _request(Permission.notification),
        ),
        const SizedBox(height: AppSpace.sm),
        _PermissionRequestCard(
          icon: Icons.photo_camera_outlined,
          title: 'Camera',
          description: 'Take a picture of a document for My Documents.',
          status: _statuses[Permission.camera],
          onRequest: () => _request(Permission.camera),
        ),
        const SizedBox(height: AppSpace.sm),
        _PermissionRequestCard(
          icon: Icons.photo_library_outlined,
          title: 'Photos',
          description: 'Choose a document image from your gallery.',
          status: _statuses[Permission.photos],
          onRequest: () => _request(Permission.photos),
        ),
        const SizedBox(height: AppSpace.lg),
        PrimaryButton(label: 'Continue', onPressed: _complete),
        Center(
          child: TextButton(onPressed: _complete, child: const Text('Not now')),
        ),
      ],
    ),
  );

  Future<void> _request(Permission permission) async {
    if (permission == Permission.notification) {
      await widget.onRequestNotifications();
    } else {
      await permission.request();
    }
    final status = await permission.status;
    if (mounted) setState(() => _statuses[permission] = status);
  }

  Future<void> _complete() async {
    await widget.onComplete();
    if (mounted) Navigator.pop(context);
  }
}

class _PermissionRequestCard extends StatelessWidget {
  const _PermissionRequestCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus? status;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final granted = status?.isGranted == true || status?.isLimited == true;
    final blocked = status?.isPermanentlyDenied == true;
    return SurfaceCard(
      onTap: granted
          ? null
          : blocked
          ? () => openAppSettings()
          : onRequest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.berry),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  granted
                      ? 'Allowed'
                      : blocked
                      ? 'Open phone settings to allow'
                      : 'Tap to allow',
                  style: TextStyle(
                    color: granted ? AppColors.success : AppColors.berry,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle : Icons.chevron_right,
            color: granted ? AppColors.success : null,
          ),
        ],
      ),
    );
  }
}
