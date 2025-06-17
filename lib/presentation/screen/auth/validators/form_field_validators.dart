class FormFieldValidators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return "Please enter your full name";
    return null;
  }

  static String? validateUserName(String? value) {
    if (value == null || value.isEmpty) return "Please enter your username";
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Please enter your email address";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address (e.g., example@email.com)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Please enter your password";
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Please enter your phone number";
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number (e.g., +1234567890)';
    }
    return null;
  }
}
