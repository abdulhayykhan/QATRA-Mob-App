import 'package:flutter/material.dart';
import '../../core/models/blood_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/role_switch_sheet.dart';
import 'slip_upload_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  BloodGroup _selectedGroup = BloodGroup.oNegative;
  BloodComponent _selectedComponent = BloodComponent.prbc;
  int _units = 2;
  Hospital _selectedHospital = Hospital.karachiHospitals[0]; // JPMC
  UrgencyLevel _selectedUrgency = UrgencyLevel.high;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Emergency Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blood Group Required
              const Text('Blood Group Required', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                ),
                itemCount: BloodGroup.values.length,
                itemBuilder: (context, index) {
                  final group = BloodGroup.values[index];
                  final isSelected = _selectedGroup == group;
                  return InkWell(
                    onTap: () => setState(() => _selectedGroup = group),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryRed : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryDarkRed : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        group.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // Component Type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Component Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BloodComponent.values.map((comp) {
                  final isSelected = _selectedComponent == comp;
                  return ChoiceChip(
                    label: Text(comp.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textDark)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryRed,
                    backgroundColor: const Color(0xFFF3F4F6),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedComponent = comp);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Units Required Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Units Required', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () {
                            if (_units > 1) setState(() => _units--);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$_units Bags',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18, color: AppColors.primaryRed),
                          onPressed: () {
                            if (_units < 10) setState(() => _units++);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Hospital / Location Selector
              const Text('Hospital / Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Hospital>(
                initialValue: _selectedHospital,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.primaryRed),
                ),
                items: Hospital.karachiHospitals.map((hosp) {
                  return DropdownMenuItem(
                    value: hosp,
                    child: Text(
                      hosp.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedHospital = val);
                },
              ),
              const SizedBox(height: 22),

              // Urgency Level Selection
              const Text('Urgency Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedUrgency = UrgencyLevel.high),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedUrgency == UrgencyLevel.high ? const Color(0xFFFFEBEE) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedUrgency == UrgencyLevel.high ? AppColors.primaryRed : AppColors.border,
                            width: _selectedUrgency == UrgencyLevel.high ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_rounded, color: AppColors.primaryRed, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'High Priority',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedUrgency == UrgencyLevel.high ? AppColors.primaryDarkRed : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('Needed in 2 Hours', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedUrgency = UrgencyLevel.standard),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedUrgency == UrgencyLevel.standard ? const Color(0xFFFFF3E0) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedUrgency == UrgencyLevel.standard ? AppColors.standardUrgency : AppColors.border,
                            width: _selectedUrgency == UrgencyLevel.standard ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: AppColors.standardUrgency, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Standard',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedUrgency == UrgencyLevel.standard ? Colors.deepOrange : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('Needed in 24 Hours', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Proceed to Slip Verification Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SlipUploadScreen(
                        bloodGroup: _selectedGroup,
                        component: _selectedComponent,
                        units: _units,
                        hospital: _selectedHospital,
                        urgency: _selectedUrgency,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Proceed to Slip Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
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
