import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/user_models.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_state_providers.dart';

class RoleSwitchSheet extends ConsumerWidget {
  const RoleSwitchSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(userProvider).role;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Switch Persona / Flow',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text(
            'Experience QATRA from all 4 user perspectives specified in the PRD & Wireframes:',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _RoleTile(
            role: UserRole.donor,
            title: 'Verified Donor (8 Screens)',
            subtitle: 'Dashboard, Available Toggle, Live Map, Proximity Alert, 90-Day Cooldown',
            icon: Icons.volunteer_activism_rounded,
            isSelected: currentRole == UserRole.donor,
            onTap: () {
              ref.read(userProvider.notifier).switchRole(UserRole.donor);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _RoleTile(
            role: UserRole.seeker,
            title: 'Emergency Seeker (10 Screens)',
            subtitle: 'Create Request, Slip Verification, Radius Broadcast, Matchmaker, Contact Donor',
            icon: Icons.emergency_rounded,
            isSelected: currentRole == UserRole.seeker,
            onTap: () {
              ref.read(userProvider.notifier).switchRole(UserRole.seeker);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _RoleTile(
            role: UserRole.admin,
            title: '24/7 Desk Admin (4 Screens)',
            subtitle: 'Hospital Slip Verification Queue, Verification Status, Fraud Audit & Blacklist',
            icon: Icons.admin_panel_settings_rounded,
            isSelected: currentRole == UserRole.admin,
            onTap: () {
              ref.read(userProvider.notifier).switchRole(UserRole.admin);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _RoleTile(
            role: UserRole.driveOrganizer,
            title: 'Campus Drive Lead (Proxy)',
            subtitle: 'Schedule university drives, attendee QR verification, volunteer roster',
            icon: Icons.campaign_rounded,
            isSelected: currentRole == UserRole.driveOrganizer,
            onTap: () {
              ref.read(userProvider.notifier).switchRole(UserRole.driveOrganizer);
              Navigator.pop(context);
            },
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulated Demo Mode',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Populates mock requests & drives for UI testing',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Switch(
                value: ref.watch(isDemoModeProvider),
                activeThumbColor: AppColors.primaryRed,
                onChanged: (val) {
                  ref.read(isDemoModeProvider.notifier).state = val;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLightRed : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isSelected ? AppColors.primaryRed : const Color(0xFFF3F4F6),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.textDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primaryDarkRed : AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryRed, size: 20),
          ],
        ),
      ),
    );
  }
}
