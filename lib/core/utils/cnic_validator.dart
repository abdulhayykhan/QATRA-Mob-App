class CnicValidator {
  // Standard Pakistani CNIC format: 5 digits - 7 digits - 1 digit (e.g., 42101-1234567-1)
  static final RegExp cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
  static final RegExp cleanCnicRegex = RegExp(r'^\d{13}$');

  static bool isValid(String? cnic) {
    if (cnic == null || cnic.trim().isEmpty) return false;
    final trimmed = cnic.trim();
    if (cnicRegex.hasMatch(trimmed)) return true;
    final digitsOnly = trimmed.replaceAll('-', '');
    return cleanCnicRegex.hasMatch(digitsOnly);
  }

  static String format(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 5) {
      return digits;
    } else if (digits.length <= 12) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    } else {
      return '${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12, digits.length > 13 ? 13 : digits.length)}';
    }
  }

  static String maskCnic(String cnic) {
    final clean = cnic.replaceAll('-', '');
    if (clean.length != 13) return cnic;
    return '${clean.substring(0, 5)}-XXXXXXX-${clean.substring(12)}';
  }
}
