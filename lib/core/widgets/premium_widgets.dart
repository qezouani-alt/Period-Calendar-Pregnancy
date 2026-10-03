import 'dart:ui';
import 'package:flutter/material.dart';
import '../design_system/app_theme.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.onTap,
  });
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(AppRadius.medium),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: .7),
          ),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: [
            BoxShadow(
              color: AppColors.plum.withValues(alpha: .035),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.plum,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}

class GlassBottomNavigation extends StatelessWidget {
  const GlassBottomNavigation({
    super.key,
    required this.index,
    required this.onChanged,
    required this.isPregnancyActive,
  });
  final int index;
  final ValueChanged<int> onChanged;
  final bool isPregnancyActive;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        0,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _nav(context, 0, Icons.home_outlined, 'Home')),
                Expanded(
                  child: isPregnancyActive
                      ? _nav(
                          context,
                          2,
                          Icons.pregnant_woman_rounded,
                          "I'm pregnant",
                        )
                      : _nav(
                          context,
                          1,
                          Icons.calendar_month_outlined,
                          'Period',
                        ),
                ),
                Expanded(
                  child: _nav(context, 3, Icons.smart_toy_outlined, 'Ask AI'),
                ),
                Expanded(
                  child: _nav(context, 4, Icons.menu_book_outlined, 'Learn'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _nav(BuildContext context, int value, IconData icon, String label) {
    final active = value == index;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: active
                    ? AppColors.berry
                    : Theme.of(context).textTheme.bodyMedium!.color,
              ),
              const SizedBox(height: 3),
              _NavLabel(label: label, color: active ? AppColors.berry : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: Theme.of(
          context,
        ).textTheme.labelSmall!.copyWith(color: color, fontSize: 9),
      ),
    ),
  );
}

class PrivacyPill extends StatelessWidget {
  const PrivacyPill({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.plum.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 13, color: AppColors.plum),
        SizedBox(width: 5),
        Text(
          'Private by design',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.plum,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
