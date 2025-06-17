class Utils {
  static String formattedPhoneNumber(String phoneNumber) {
    if (phoneNumber.isNotEmpty) return "";
    return phoneNumber.replaceAll(
        RegExp(r'\s+'),
        "".trim()
    );
  }
}