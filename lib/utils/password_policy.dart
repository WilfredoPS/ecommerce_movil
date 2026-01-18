import 'package:intl/intl.dart';

class PasswordPolicyResult {
  final bool isValid;
  final String? errorMessage;
  const PasswordPolicyResult(this.isValid, [this.errorMessage]);
}

class PasswordPolicy {
  static const int minLength = 10;
  static const int maxLength = 128;
  static const int minLower = 1;
  static const int minUpper = 1;
  static const int minDigits = 1;
  static const int minSymbols = 1;
  static const Duration maxPasswordAge = Duration(days: 90);

  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _symbol = RegExp(r"""[!@#\$%\^&\*\(\)\-\_\=\+\[\]\{\}\\\|;:'",<>\.\?/~`]""");
  static final List<String> _commonPasswords = <String>[
    'password','123456','123456789','qwerty','abc123','111111','123123','admin'
  ];

  static PasswordPolicyResult validate(String password) {
    if (password.length < minLength) {
      return PasswordPolicyResult(false, 'La contraseña debe tener al menos $minLength caracteres.');
    }
    if (password.length > maxLength) {
      return PasswordPolicyResult(false, 'La contraseña no debe exceder $maxLength caracteres.');
    }
    if (_commonPasswords.contains(password.toLowerCase())) {
      return const PasswordPolicyResult(false, 'La contraseña es demasiado común.');
    }
    if (!_lower.hasMatch(password)) {
      return const PasswordPolicyResult(false, 'Debe incluir al menos una letra minúscula.');
    }
    if (!_upper.hasMatch(password)) {
      return const PasswordPolicyResult(false, 'Debe incluir al menos una letra mayúscula.');
    }
    if (!_digit.hasMatch(password)) {
      return const PasswordPolicyResult(false, 'Debe incluir al menos un número.');
    }
    if (!_symbol.hasMatch(password)) {
      return const PasswordPolicyResult(false, 'Debe incluir al menos un símbolo.');
    }
    return const PasswordPolicyResult(true);
  }

  static bool isExpired(DateTime lastChangedAt) {
    final now = DateTime.now();
    return now.difference(lastChangedAt) > maxPasswordAge;
  }

  static String nextExpirationHint(DateTime lastChangedAt) {
    final next = lastChangedAt.add(maxPasswordAge);
    return DateFormat('yyyy-MM-dd').format(next);
  }
}


