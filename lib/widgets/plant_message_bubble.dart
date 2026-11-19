import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

class PlantMessageBubble extends StatelessWidget {
  const PlantMessageBubble({
    super.key,
    required this.text,
    this.personaName = 'Plant',
    this.fromPlant = true,
    this.compact = false,
  });

  final String text;
  final String personaName;
  final bool fromPlant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final align =
        fromPlant ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    // White plant bubbles stay readable on the mint scaffold background.
    final bg = fromPlant ? Colors.white : AppColors.primary;
    final fg = fromPlant ? AppColors.text : Colors.white;

    return Column(
      crossAxisAlignment: align,
      children: [
        if (fromPlant && !compact)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              personaName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(fromPlant ? 4 : 18),
              bottomRight: Radius.circular(fromPlant ? 18 : 4),
            ),
            border: fromPlant
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                : null,
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: fg,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}
