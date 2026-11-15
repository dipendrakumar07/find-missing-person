import 'package:flutter/material.dart';
import '../models/missing_person.dart';

class StatusBadge extends StatelessWidget {
  final PersonStatus status;
  final bool isUrgent;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isUrgent = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    IconData icon;
    String label;

    if (status == PersonStatus.found) {
      bg = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
      icon = Icons.check_circle_rounded;
      label = 'Found / Safe';
    } else if (isUrgent) {
      bg = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF991B1B);
      icon = Icons.warning_rounded;
      label = 'Urgent Alert';
    } else if (status == PersonStatus.possibleMatch) {
      bg = const Color(0xFFFEF3C7);
      textColor = const Color(0xFF92400E);
      icon = Icons.visibility_rounded;
      label = 'Possible Match';
    } else {
      bg = const Color(0xFFE0F2FE);
      textColor = const Color(0xFF0369A1);
      icon = Icons.search_rounded;
      label = 'Missing';
    }

    final double fontSize = isSmall ? 11 : 12;
    final double iconSize = isSmall ? 13 : 15;
    final EdgeInsets padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
