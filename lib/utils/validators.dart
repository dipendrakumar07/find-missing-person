/// Centralized form validation rules for email, phone number, password, and personal details.
class AppValidators {
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  /// Validates an email address checking all conditions:
  /// - Non-empty and not just spaces
  /// - No spaces inside the email
  /// - Exactly one '@' symbol
  /// - Valid username/local part (no leading, trailing, or consecutive dots)
  /// - Valid domain part (contains extension dot, no leading/trailing/consecutive dots)
  /// - Valid Top Level Domain (TLD) of at least 2 alpha characters (.com, .org, etc.)
  /// - Full RFC regex structure
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final email = value.trim();

    if (email.contains(' ')) {
      return 'Email cannot contain spaces';
    }

    final atCount = '@'.allMatches(email).length;
    if (atCount == 0) {
      return 'Email must contain "@" (e.g. name@example.com)';
    }
    if (atCount > 1) {
      return 'Email cannot contain multiple "@" symbols';
    }

    final parts = email.split('@');
    final localPart = parts[0];
    final domainPart = parts[1];

    if (localPart.isEmpty) {
      return 'Missing username before "@"';
    }
    if (localPart.startsWith('.') || localPart.endsWith('.')) {
      return 'Email username cannot start or end with a dot';
    }
    if (localPart.contains('..')) {
      return 'Email username cannot contain consecutive dots';
    }

    if (domainPart.isEmpty) {
      return 'Missing domain after "@" (e.g. example.com)';
    }
    if (!domainPart.contains('.')) {
      return 'Domain must include an extension (e.g. .com, .in)';
    }
    if (domainPart.startsWith('.') || domainPart.endsWith('.')) {
      return 'Domain cannot start or end with a dot';
    }
    if (domainPart.contains('..')) {
      return 'Domain cannot contain consecutive dots';
    }

    final domainParts = domainPart.split('.');
    final tld = domainParts.last;
    if (tld.length < 2 || !RegExp(r'^[a-zA-Z]+$').hasMatch(tld)) {
      return 'Domain extension must be at least 2 letters (e.g. .com, .in)';
    }

    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates a phone/contact number checking all conditions:
  /// - Non-empty (if [isRequired] is true)
  /// - Allowed characters only (digits, +, -, spaces, parentheses)
  /// - "+" country code position (only allowed at the start, at most once)
  /// - Total digits between 10 and 15 (E.164 international standard)
  /// - Not all identical repeating digits (e.g. 0000000000, 9999999999)
  /// - Standard 10-digit number cannot start with 0
  static String? validatePhone(
    String? value, {
    bool isRequired = true,
    String fieldName = 'Phone number',
  }) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return '$fieldName is required';
      return null;
    }

    final phone = value.trim();

    // Check invalid characters
    if (RegExp(r'[^\d+\s\-()]').hasMatch(phone)) {
      return '$fieldName can only contain numbers, spaces, and "+", "-"';
    }

    // Check + placement
    if (phone.contains('+')) {
      if (!phone.startsWith('+')) {
        return 'Country code "+" can only be at the beginning';
      }
      if ('+'.allMatches(phone).length > 1) {
        return 'Phone cannot contain multiple "+" symbols';
      }
    }

    // Extract digits only
    final digitsOnly = phone.replaceAll(RegExp(r'[\s\-()+]'), '');

    if (digitsOnly.length < 10) {
      return '$fieldName must have at least 10 digits';
    }
    if (digitsOnly.length > 15) {
      return '$fieldName cannot exceed 15 digits';
    }

    // Repeated identical dummy numbers (0000000000, 1111111111, etc.)
    if (RegExp(r'^(\d)\1+$').hasMatch(digitsOnly)) {
      return 'Enter a valid active $fieldName (cannot be identical digits)';
    }

    // 10-digit national number cannot start with 0
    if (digitsOnly.length == 10 && digitsOnly.startsWith('0')) {
      return '10-digit $fieldName cannot start with 0';
    }

    return null;
  }

  /// Validates an input that can be either an email OR a phone number.
  /// Used in unified login fields.
  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your mobile number or email address';
    }
    final input = value.trim();

    // If it has '@' or alphabetic characters, validate as email
    if (input.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(input)) {
      return validateEmail(input);
    }

    // Otherwise, validate as phone number
    return validatePhone(input, isRequired: true, fieldName: 'Mobile number');
  }

  /// Validates strong password checking:
  /// - Minimum 8 characters
  /// - At least 1 uppercase letter (A-Z)
  /// - At least 1 lowercase letter (a-z)
  /// - At least 1 numeric digit (0-9)
  /// - At least 1 special character / symbol
  static String? validateStrongPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain at least 1 uppercase letter (A-Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Must contain at least 1 lowercase letter (a-z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must contain at least 1 number (0-9)';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Must contain at least 1 special symbol (!@#\$%...)';
    }
    return null;
  }

  /// Validates a person's full name.
  static String? validateName(String? value, {String fieldName = 'Full name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final name = value.trim();
    if (name.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (RegExp(r'[0-9]').hasMatch(name)) {
      return '$fieldName cannot contain numbers';
    }
    return null;
  }
}

