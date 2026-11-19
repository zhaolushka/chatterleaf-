import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

class ModeChip extends StatelessWidget {
  const ModeChip({
    super.key,
    required this.isAuto,
    this.onToggle,
  });

  final bool isAuto;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAuto
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAuto ? AppColors.primary : AppColors.accent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAuto ? Icons.auto_mode : Icons.pan_tool_alt,
              size: 16,
              color: isAuto ? AppColors.primary : AppColors.accent,
            ),
            const SizedBox(width: 6),
            Text(
              isAuto ? 'Auto' : 'Manual',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isAuto ? AppColors.primary : AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
