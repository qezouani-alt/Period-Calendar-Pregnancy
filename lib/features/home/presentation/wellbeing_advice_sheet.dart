import 'package:flutter/material.dart';
import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/wellbeing_advice_service.dart';

Future<void> showWellbeingAdvice(
  BuildContext context,
  WellbeingAdvice advice,
) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (_) => Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.lg,
      AppSpace.sm,
      AppSpace.lg,
      AppSpace.xxl,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Row(
          children: [
            const Icon(Icons.favorite_outline, color: AppColors.berry),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                advice.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(advice.message, style: Theme.of(context).textTheme.bodyLarge),
        if (advice.careNote != null) ...[
          const SizedBox(height: AppSpace.md),
          SurfaceCard(
            color: AppColors.warning.withValues(alpha: .10),
            child: Text(
              advice.careNote!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: AppSpace.md),
        Text(advice.source, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppSpace.lg),
        PrimaryButton(
          label: 'Got it',
          icon: Icons.check,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  ),
);
