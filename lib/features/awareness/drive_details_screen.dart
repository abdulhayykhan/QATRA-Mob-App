import 'package:flutter/material.dart';
import '../../core/models/user_models.dart';
import '../../core/theme/app_theme.dart';

class DriveDetailsScreen extends StatefulWidget {
  final DriveEvent drive;
  const DriveDetailsScreen({super.key, required this.drive});

  @override
  State<DriveDetailsScreen> createState() => _DriveDetailsScreenState();
}

class _DriveDetailsScreenState extends State<DriveDetailsScreen> {
  bool _isRegistered = false;
  String _selectedRole = 'Donor'; // 'Donor' or 'Volunteer'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Blood Drive Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campus Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.drive.universityCampus,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryDarkRed),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.drive.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Organized by ${widget.drive.organizer}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Date, Time & Venue Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.calendar_today_rounded, 'Date & Time', widget.drive.time),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.location_on_rounded, 'Venue', widget.drive.venue),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.track_changes_rounded, 'Target Collection', '${widget.drive.targetUnits} Blood Units'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('About This Drive', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                widget.drive.description,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              if (!_isRegistered) ...[
                // Role Selection
                const Text('Register As', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: ['Donor', 'Volunteer'].map((r) {
                    final isSel = _selectedRole == r;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = r),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primaryLightRed : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? AppColors.primaryRed : AppColors.border, width: isSel ? 2 : 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            r,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSel ? AppColors.primaryDarkRed : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Confirm Registration Button
                ElevatedButton(
                  onPressed: () => setState(() => _isRegistered = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Confirm Registration as $_selectedRole', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ] else ...[
                // Registered QR Pass Card (Wireframe Screen 23 / Section 6.4)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Registration Confirmed!',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registered as $_selectedRole • Pass ID: QATRA-DUET-88',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                      ),
                      const SizedBox(height: 16),

                      // Simulated QR Code
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, size: 100, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Show this QR pass at the entrance on drive day for 1-second check-in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryRed),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
