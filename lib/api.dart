import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  final String message;
  final bool premiumRequired;
  ApiException(this.message, {this.premiumRequired = false});
  @override
  String toString() => message;
}

class RemoteConfig {
  final int wordLimit;
  final List<int> lockedModes;
  const RemoteConfig(this.wordLimit, this.lockedModes);

  static const fallback =
      RemoteConfig(AppConfig.defaultWordLimit, AppConfig.defaultLockedModes);
}

class ParaphraseApi {
  /// Asks the server for the word limit and which modes are locked.
  /// Falls back to safe defaults if anything goes wrong.
  static Future<RemoteConfig> fetchConfig() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.apiUrl}/app-config'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return RemoteConfig.fallback;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final limit = (body['word_limit'] as num?)?.toInt() ??
          AppConfig.defaultWordLimit;
      final locked = ((body['locked_modes'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList();
      return RemoteConfig(limit, locked);
    } catch (_) {
      return RemoteConfig.fallback;
    }
  }

  static Future<String> paraphrase({
    required String text,
    required String language,
    required int mode,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/paraphrase'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'text': text, 'language': language, 'mode': mode}),
          )
          .timeout(const Duration(seconds: 90));

      Map<String, dynamic> body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException(
            'The server sent an unexpected reply (code ${res.statusCode}). Please try again.');
      }

      if (res.statusCode == 200 && body['success'] == true) {
        return (body['content'] ?? '').toString();
      }
      final msg = body['message']?.toString();
      if (res.statusCode == 403) {
        throw ApiException(msg ?? 'This mode needs a Premium plan.',
            premiumRequired: true);
      }
      if (res.statusCode == 429) {
        throw ApiException('Too many requests. Please wait a minute and try again.');
      }
      throw ApiException(msg ?? 'Something went wrong. Please try again.');
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('The request took too long. Please try again.');
    } catch (_) {
      throw ApiException('Something went wrong. Please try again.');
    }
  }
}
