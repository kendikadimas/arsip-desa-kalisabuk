import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/auth.dart';

void main() async {
  final path = 'assets/credentials.json';
  final file = File(path);
  if (!file.existsSync()) {
    print('File not found at $path');
    return;
  }

  try {
    final content = file.readAsStringSync();
    print('Content loaded, length: ${content.length}');

    final decoded = jsonDecode(content);
    print('Decoded type: ${decoded.runtimeType}');

    // Explicit test of the problematic call
    print('Attempting ServiceAccountCredentials.fromJson(decoded)...');
    final credentials = ServiceAccountCredentials.fromJson(decoded);
    print('Success! Credentials email: ${credentials.email}');

    // Test with raw string too
    print('Attempting ServiceAccountCredentials.fromJson(string)...');
    final credentials2 = ServiceAccountCredentials.fromJson(content);
    print('Success with string! Email: ${credentials2.email}');
  } catch (e, stack) {
    print('ERROR CAUGHT: $e');
    print(stack);
  }
}
