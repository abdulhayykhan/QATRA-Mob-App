import 'package:flutter/material.dart';
import '../core/models/blood_models.dart';
import '../core/theme/app_theme.dart';

class BloodGroupBadge extends StatelessWidget {
  final BloodGroup bloodGroup;
  final double size;
  final bool isSelected;

  const BloodGroupBadge({
    super.key,
    required this.bloodGroup,
    this.size = 48,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryRed : AppColors.primaryLightRed,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primaryDarkRed : AppColors.primaryRed.withOpacity(0.3),
          width: isSelected ? 2.5 : 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        bloodGroup.label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.primaryRed,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

class UrgencyBadge extends StatelessWidget {
  final UrgencyLevel urgency;

  const UrgencyBadge({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    final isHigh = urgency == UrgencyLevel.high;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHigh ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHigh ? AppColors.highUrgency.withOpacity(0.4) : AppColors.standardUrgency.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHigh ? Icons.warning_amber_rounded : Icons.access_time_rounded,
            size: 14,
            color: isHigh ? AppColors.highUrgency : AppColors.standardUrgency,
          ),
          const SizedBox(width: 4),
          Text(
            isHigh ? 'High Priority (< 2h)' : 'Standard (< 24h)',
            style: TextStyle(
              color: isHigh ? AppColors.highUrgency : AppColors.standardUrgency,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  final String text;
  const VerifiedBadge({super.key, this.text = 'Verified'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RequestStatusBadge extends StatelessWidget {
  final RequestStatus status;
  const RequestStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF3F4F6);
    Color fg = const Color(0xFF4B5563);

    switch (status) {
      case RequestStatus.pendingVerification:
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFC2410C);
        break;
      case RequestStatus.verified:
      case RequestStatus.broadcasting:
        bg = const Color(0xFFFEF2F2);
        fg = AppColors.primaryRed;
        break;
      case RequestStatus.matched:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        break;
      case RequestStatus.fulfilled:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF15803D);
        break;
      case RequestStatus.cancelled:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
