import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

class ReadingCard extends StatelessWidget {
  const ReadingCard({
    super.key,
    required this.label,
    required this.valueText,
    required this.icon,
    required this.statusColor,
    this.offline = false,
  });

  final String label;
  final String valueText;
  final IconData icon;
  final Color statusColor;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: statusColor, size: 22),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valueText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            offline ? '$label · offline' : label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
          ),
        ],
      ),
    );
  }
}
