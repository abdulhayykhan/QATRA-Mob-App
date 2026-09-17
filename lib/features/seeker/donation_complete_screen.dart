import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/blood_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';

class DonationCompleteScreen extends ConsumerStatefulWidget {
  final EmergencyRequest request;
  const DonationCompleteScreen({super.key, required this.request});

  @override
  ConsumerState<DonationCompleteScreen> createState() => _DonationCompleteScreenState();
}

class _DonationCompleteScreenState extends ConsumerState<DonationCompleteScreen> {
  int _rating = 5;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: 'May Allah reward the donor for arriving promptly at ${widget.request.hospital.name} and saving our patient!',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _confirmClosure() {
    ref.read(emergencyRequestsRepositoryProvider).fulfillRequest(widget.request.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency request marked as fulfilled & closed.'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Emergency Closure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shield with Heart Icon
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLightRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: AppColors.primaryRed, size: 44),
              ),
              const SizedBox(height: 16),
              const Text(
                'Emergency Request Complete',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'Thank you for coordinating life-saving speed.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLightRed,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.request.bloodGroup.label,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.request.unitsRequired} Units Fulfilled',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'at ${widget.request.hospital.name}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Response Speed Rating
              const Text(
                'How was the response speed?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your feedback helps us optimize future emergency dispatches.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 36,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Optional Thank-You Note
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Optional Thank-You Note', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write a message to the donors...',
                ),
              ),
              const SizedBox(height: 36),

              // Confirm Fulfillment & Close Request Button
              ElevatedButton(
                onPressed: _confirmClosure,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Confirm Fulfillment & Close Request',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
