import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/blood_models.dart';
import '../../core/models/user_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';
import 'cnic_binding_screen.dart';
import '../seeker/create_request_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String phone;
  final bool isSeeker;
  const ProfileSetupScreen({super.key, required this.phone, required this.isSeeker});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Abdul Hayy Khan');
  final TextEditingController _ageController = TextEditingController(text: '22');
  final TextEditingController _cnicController = TextEditingController(text: '42101-1234567-1');

  String _gender = 'M';
  String _selectedDistrict = 'Karachi South';
  BloodGroup _selectedBloodGroup = BloodGroup.oNegative;

  final List<String> _karachiDistricts = [
    'Karachi South',
    'Karachi East',
    'Karachi Central',
    'Karachi West',
    'Korangi',
    'Malir',
    'Keamari',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    ref.read(userProvider.notifier).updateProfile(
      fullName: _nameController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      district: _selectedDistrict,
      cnic: _cnicController.text.trim(),
    );

    if (widget.isSeeker) {
      ref.read(userProvider.notifier).switchRole(UserRole.seeker);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
      );
    } else {
      // If Donor, take them to CNIC Identity Binding
      ref.read(userProvider.notifier).switchRole(UserRole.donor);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CnicBindingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quick Profile Setup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
              const Text(
                'Please provide your basic details to help us match you quickly when every second counts.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Full Name
              const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Abdul Hayy Khan',
                ),
              ),
              const SizedBox(height: 16),

              // Age & Gender Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Age', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'e.g., 24'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: ['M', 'F', 'O'].map((g) {
                            final isSelected = _gender == g;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _gender = g),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryLightRed : Colors.white,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryRed : AppColors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.primaryRed : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Blood Group Selection
              const Text('Blood Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BloodGroup.values.map((bg) {
                  final isSelected = _selectedBloodGroup == bg;
                  return ChoiceChip(
                    label: Text(bg.label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textDark)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryRed,
                    backgroundColor: const Color(0xFFF3F4F6),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedBloodGroup = bg);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Primary District (Karachi)
              const Text('Primary District (Karachi)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedDistrict,
                decoration: const InputDecoration(),
                items: _karachiDistricts.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDistrict = val);
                },
              ),
              const SizedBox(height: 16),

              // CNIC (Optional for seeker, required for verified donor)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CNIC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    widget.isSeeker ? 'Optional' : 'Required for Donor',
                    style: TextStyle(fontSize: 11, color: widget.isSeeker ? AppColors.textMuted : AppColors.primaryRed, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '42101-1234567-1',
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Providing CNIC adds a "Verified" badge to your requests & unlocks instant dispatch.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Profile Button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
