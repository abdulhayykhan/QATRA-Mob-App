import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FraudAuditScreen extends StatefulWidget {
  const FraudAuditScreen({super.key});

  @override
  State<FraudAuditScreen> createState() => _FraudAuditScreenState();
}

class _FraudAuditScreenState extends State<FraudAuditScreen> {
  final List<Map<String, dynamic>> _flaggedRecords = [
    {
      'id': 'REQ-9942',
      'cnic': '35202-1234567-1',
      'phone': '0300-1234567',
      'mrn': 'MRN-7782A',
      'reason': 'Re-used Slip Image',
      'confidence': '45%',
      'status': 'Flagged',
    },
    {
      'id': 'REQ-9938',
      'cnic': '42201-9876543-2',
      'phone': '0333-9876543',
      'mrn': 'MRN-2219B',
      'reason': 'Mismatched Doctor Stamp',
      'confidence': '62%',
      'status': 'Under Review',
    },
    {
      'id': 'REQ-9915',
      'cnic': '61101-5555555-5',
      'phone': '0345-5555555',
      'mrn': 'MRN-7782A',
      'reason': 'Duplicate MRN Submission',
      'confidence': '95%',
      'status': 'Auto-Blocked',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fraud Audit & Blacklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary KPI Counters (Wireframe Screen 22)
              Row(
                children: [
                  _buildKpiCard('12', 'Flagged Submissions', const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                  const SizedBox(width: 10),
                  _buildKpiCard('4', 'Duplicate MRNs', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                  const SizedBox(width: 10),
                  _buildKpiCard('7', 'Suspended Accounts', const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by CNIC, Phone or Hospital MRN...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Flagged Cases & Policy Violations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),

              ..._flaggedRecords.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item['status'] == 'Auto-Blocked' ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['status'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: item['status'] == 'Auto-Blocked' ? AppColors.primaryRed : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow('CNIC', item['cnic']),
                        const SizedBox(height: 4),
                        _buildDetailRow('MRN', item['mrn']),
                        const SizedBox(height: 4),
                        _buildDetailRow('Violation', item['reason']),
                        const SizedBox(height: 14),

                        // Action Buttons: Blacklist vs Whitelist
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${item['cnic']} blacklisted & suspended.')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(40),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Blacklist CNIC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${item['cnic']} verified & whitelisted.')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Whitelist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              ),
                            ),
                          ],
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

  Widget _buildKpiCard(String count, String label, Color accent, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accent)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textDark, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }
}
