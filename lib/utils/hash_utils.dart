import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class HashUtils {
  static String generateSalt({int length = 16}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String sha256WithSalt(String password, String salt) {
    final data = utf8.encode('$salt:$password');
    final digest = sha256.convert(data);
    return digest.toString(); // hex string
  }

  static bool constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    if (aBytes.length != bBytes.length) return false;
    var diff = 0;
    for (var i = 0; i < aBytes.length; i++) {
      diff |= aBytes[i] ^ bBytes[i];
    }
    return diff == 0;
  }

  static bool verifySha256(String password, String salt, String expectedHexHash) {
    final calc = sha256WithSalt(password, salt);
    return constantTimeEquals(calc, expectedHexHash);
  }
}


