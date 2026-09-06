/// Mirrors DogShelter.Model's ValidationPatterns/ValidationMessages so every form (mobile,
/// desktop) enforces the exact same rules the backend does, with the same inline error text,
/// instead of each screen inventing its own regex and wording.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // Backend's ValidationPatterns.Phone (^\d{9}$) - exactly 9 digits, no spaces or separators.
  static final RegExp _phoneRegex = RegExp(r'^\d{9}$');

  static bool isValidEmail(String value) => _emailRegex.hasMatch(value);

  static bool isValidPhone(String value) => _phoneRegex.hasMatch(value);

  static const String emailInvalidMessage = 'Unesite ispravan email, npr. ime@primjer.com';
  static const String phoneInvalidMessage = 'Unesite ispravan broj telefona (9 brojeva, bez razmaka)';

  /// Null when valid, an error message otherwise. Email is required.
  static String? email(String value) {
    if (value.isEmpty) return 'Email je obavezan.';
    if (!isValidEmail(value)) return emailInvalidMessage;
    return null;
  }

  /// Null when valid, an error message otherwise. Telefon is optional - empty passes.
  static String? phone(String value) {
    if (value.isEmpty) return null;
    if (!isValidPhone(value)) return phoneInvalidMessage;
    return null;
  }
}
