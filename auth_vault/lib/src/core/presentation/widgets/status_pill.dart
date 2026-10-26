import 'package:flutter/material.dart';
import '../../../common/constants/colors.dart';
import '../../../common/constants/dimen.dart';
import 'text.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool fill;
  const StatusPill({
    super.key,
    required this.label,
    this.color = UIColors.primary,
    this.fill = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fill ? color.withValues(alpha: 0.15) : UIColors.canvasSoft,
        borderRadius: BorderRadius.circular(Dimen.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: AppText.mono(
        label.toUpperCase(),
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
