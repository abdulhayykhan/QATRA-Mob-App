import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';
import '../../widgets/role_switch_sheet.dart';

class DriveManagementScreen extends ConsumerStatefulWidget {
  const DriveManagementScreen({super.key});

  @override
  ConsumerState<DriveManagementScreen> createState() => _DriveManagementScreenState();
}

class _DriveManagementScreenState extends ConsumerState<DriveManagementScreen> {
  final List<Map<String, dynamic>> _attendees = [
    {
      'name': 'Ali Zain (CS-2021)',
      'cnic': 'Verified',
      'screening': 'Passed',
      'status': 'Checked In 10:42 AM',
      'eligible': true,
    },
    {
      'name': 'Fatima Ahmed (BBA-2023)',
      'cnic': 'Verified',
      'screening': 'Pending',
      'status': 'Manual Check-in',
      'eligible': true,
    },
    {
      'name': 'Omar Khan (EE-2020)',
      'cnic': 'Verified',
      'screening': 'Failed (Low Hb)',
      'status': 'Ineligible',
      'eligible': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    final drives = ref.watch(campusDrivesProvider);
    final displayedAttendees = isDemoMode ? _attendees : const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campus Drive Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Metrics Header (Wireframe Screen 23)
              Row(
                children: [
                  _buildMetricCard('${drives.length}', 'Drives Scheduled', Icons.event_note, const Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  _buildMetricCard(isDemoMode ? '420' : '0', 'Pre-Screened Donors', Icons.people_alt, const Color(0xFF7C3AED)),
                  const SizedBox(width: 10),
                  _buildMetricCard(isDemoMode ? '850' : '0', 'Target Collection', Icons.water_drop, AppColors.primaryRed),
                ],
              ),
              const SizedBox(height: 20),

              // Live Attendance & QR Scanner Box (Wireframe Screen 23)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryRed, size: 20),
                              SizedBox(width: 8),
                              Text('Live Attendance & QR Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                            child: const Text('DUET Drive Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Camera Frame for QR Code scanning
                      Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 48, color: AppColors.primaryRed),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Scanned Pass: Ali Zain (DUET-CS-2021) - Check-in Confirmed!'),
                                      backgroundColor: Color(0xFF2E7D32),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(180, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Scan Attendee QR Pass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Attendee Roster Table
              const Text('Pre-Screened Attendee Roster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              if (displayedAttendees.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.person_search_outlined, size: 36, color: AppColors.textLight),
                      SizedBox(height: 8),
                      Text(
                        'No Checked-in Attendees Yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Scan student QR passes or conduct health screenings at the desk to register live attendees.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else
                ...displayedAttendees.map((att) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: att['eligible'] ? const Color(0xFFE8F5E9) : const Color(0xFFFEE2E2),
                            child: Icon(
                              att['eligible'] ? Icons.check : Icons.close,
                              color: att['eligible'] ? const Color(0xFF2E7D32) : AppColors.primaryRed,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(att['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(
                                  'CNIC: ${att['cnic']} • Screening: ${att['screening']}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            att['status'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: att['eligible'] ? const Color(0xFF15803D) : AppColors.primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
