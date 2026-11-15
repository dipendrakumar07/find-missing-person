import 'package:flutter/material.dart';

/// Official Verified Badge - displayed ONLY for verified reports.
class VerifiedBadge extends StatelessWidget {
  final bool isSmall;
  final bool showIconOnly;

  const VerifiedBadge({
    super.key,
    this.isSmall = false,
    this.showIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showIconOnly) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: Color(0xFF059669),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.verified_rounded,
          color: Colors.white,
          size: 14,
        ),
      );
    }

    final double fontSize = isSmall ? 10.5 : 12;
    final double iconSize = isSmall ? 13 : 15;
    final EdgeInsets padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: iconSize,
            color: const Color(0xFF059669),
          ),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: const Color(0xFF065F46),
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Verification Status Badge for Admin Dashboard and Case Status Details
class VerificationStatusBadge extends StatelessWidget {
  final String status; // 'Pending', 'Approved', 'Rejected', 'Verified'
  final bool isSmall;

  const VerificationStatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase().trim();

    Color bg;
    Color textColor;
    Color borderColor;
    IconData icon;
    String label;

    switch (lower) {
      case 'verified':
        bg = const Color(0xFFECFDF5);
        textColor = const Color(0xFF047857);
        borderColor = const Color(0xFF10B981);
        icon = Icons.verified_rounded;
        label = 'Verified';
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFB91C1C);
        borderColor = const Color(0xFFF87171);
        icon = Icons.cancel_outlined;
        label = 'Rejected';
        break;
      case 'pending':
        bg = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFB45309);
        borderColor = const Color(0xFFFBBF24);
        icon = Icons.hourglass_top_rounded;
        label = 'Pending Review';
        break;
      case 'approved':
      default:
        bg = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1D4ED8);
        borderColor = const Color(0xFF60A5FA);
        icon = Icons.check_circle_outline_rounded;
        label = 'Approved';
        break;
    }

    final double fontSize = isSmall ? 10.5 : 12;
    final double iconSize = isSmall ? 13 : 15;
    final EdgeInsets padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 9, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor.withOpacity(0.4),
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
