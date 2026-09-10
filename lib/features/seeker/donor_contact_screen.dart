import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/blood_models.dart';
import '../../core/theme/app_theme.dart';
import 'donation_complete_screen.dart';

class DonorContactScreen extends StatelessWidget {
  final MatchedDonor donor;
  final EmergencyRequest request;

  const DonorContactScreen({super.key, required this.donor, required this.request});

  Future<void> _makePhoneCall(BuildContext context) async {
    final cleanPhone = donor.phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dialing ${donor.phoneNumber}...')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final cleanPhone = donor.phoneNumber.replaceAll(RegExp(r'[\s\+\-]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=Salam%2C%20I%20am%20coordinating%20with%20you%20via%20QATRA%20for%20the%20blood%20request%20at%20${Uri.encodeComponent(request.hospital.name)}.');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening WhatsApp for donor coordination...')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('QATRA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDarkRed)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Coordinating with ${donor.donorName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${donor.bloodGroup.label} • Accepted Donor',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Dispatch Tracking Steps
              _buildCoordinationStep(
                title: 'Dispatch Accepted',
                subtitle: '${donor.donorName} confirmed availability and is on their way.',
                isDone: true,
              ),
              const SizedBox(height: 14),
              _buildCoordinationStep(
                title: 'Traveling to Hospital',
                subtitle: 'ETA: ${donor.etaMinutes} min • ${donor.distanceKm} km away',
                isDone: true,
              ),
              const SizedBox(height: 14),
              _buildCoordinationStep(
                title: 'Reached Blood Bank & Sample Provided',
                subtitle: 'Awaiting donor arrival and medical screening.',
                isDone: false,
              ),
              const SizedBox(height: 24),

              // Destination Hospital Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.primaryRed, size: 20),
                        SizedBox(width: 8),
                        Text('DESTINATION HOSPITAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      request.hospital.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.hospital.address,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Direct Contact Notice (Zero SMS / Direct Dial)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Direct contact enabled for accepted donor: ${donor.phoneNumber}. No system SMS charges.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary "Contact Donor" Button (tel:)
              ElevatedButton(
                onPressed: () => _makePhoneCall(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Contact Donor (${donor.phoneNumber})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // WhatsApp Coordination Button
              OutlinedButton(
                onPressed: () => _openWhatsApp(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'WhatsApp Coordination Message',
                      style: TextStyle(color: Color(0xFF1EBE5D), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Proceed to Donation Complete
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DonationCompleteScreen(request: request),
                    ),
                  );
                },
                child: const Text(
                  'Mark Donation as Received & Close Request',
                  style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinationStep({
    required String title,
    required String subtitle,
    required bool isDone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: isDone ? AppColors.primaryRed : AppColors.textLight,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDone ? AppColors.textDark : AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
