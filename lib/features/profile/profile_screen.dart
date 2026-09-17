import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/blood_models.dart';
import '../../core/models/user_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cnic_validator.dart';
import '../../providers/app_state_providers.dart';
import '../../widgets/role_switch_sheet.dart';
import '../../widgets/status_badges.dart';
import '../auth/cnic_binding_screen.dart';
import '../donor/cooldown_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback? onBackToHome;
  const ProfileScreen({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackToHome,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryRed),
            tooltip: 'Switch Persona',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => const RoleSwitchSheet(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // User Avatar & Name Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primaryLightRed,
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                            child: const Icon(Icons.verified, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.phone,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLightRed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Current Role: ${user.role.label}',
                          style: const TextStyle(color: AppColors.primaryDarkRed, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Profile Attributes Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileRow('Blood Group', user.bloodGroup.label, Icons.water_drop, isBadge: true, bloodGroup: user.bloodGroup),
                      const Divider(height: 20),
                      _buildProfileRow('Email Account', user.email, Icons.email_outlined),
                      const Divider(height: 20),
                      _buildProfileRow('Primary District', user.district, Icons.location_city_rounded),
                      const Divider(height: 20),
                      _buildProfileRow(
                        'CNIC Status',
                        user.isCnicVerified
                            ? (user.cnic != null && user.cnic!.isNotEmpty ? CnicValidator.maskCnic(user.cnic!) : 'Verified')
                            : (user.cnic != null && user.cnic!.isNotEmpty ? 'Pending Review' : 'Unverified'),
                        Icons.badge_outlined,
                        trailingAction: user.isCnicVerified
                            ? const VerifiedBadge(text: 'Verified')
                            : TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CnicBindingScreen()),
                                  );
                                },
                                child: Text(
                                  user.cnic != null && user.cnic!.isNotEmpty ? 'Update CNIC' : 'Verify Now',
                                  style: const TextStyle(color: AppColors.primaryRed, fontSize: 12),
                                ),
                              ),
                      ),
                      const Divider(height: 20),
                      _buildProfileRow('Lives Saved', '${user.livesSaved} Donations', Icons.favorite, valueColor: AppColors.primaryRed),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.timelapse_rounded, color: AppColors.primaryRed),
                      title: const Text('90-Day Donation Cooldown', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(user.isOnCooldown ? '${user.cooldownDaysRemaining} days remaining' : 'Ready to donate', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CooldownScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF2563EB)),
                      title: const Text('24/7 Verification Desk (Staff)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Review uploaded hospital slips and OCR confidence', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        ref.read(userProvider.notifier).switchRole(UserRole.admin);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.support_agent_rounded, color: Color(0xFF15803D)),
                      title: const Text('Alkhidmat Emergency Helpline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Dial 112 or 1021 for 24/7 ambulance & blood support', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        final uri = Uri.parse('tel:1021');
                        try {
                          await launchUrl(uri);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Dialing Alkhidmat Emergency Helpline 1021...')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Switch Persona Modal Button
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => const RoleSwitchSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Switch User Persona (Donor / Seeker / Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Sign Out Button
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(userProvider.notifier).signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: const BorderSide(color: AppColors.primaryRed),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(
    String label,
    String value,
    IconData icon, {
    bool isBadge = false,
    BloodGroup? bloodGroup,
    Widget? trailingAction,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const Spacer(),
        if (trailingAction != null)
          trailingAction
        else if (isBadge && bloodGroup != null)
          BloodGroupBadge(bloodGroup: bloodGroup, size: 32)
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
      ],
    );
  }
}
