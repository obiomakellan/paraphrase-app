import 'package:flutter/material.dart';

/// Everything you may want to change later lives in this file.
class AppConfig {
  static const String appName = 'ParaphraseTool';
  static const String siteUrl = 'https://www.paraphrasingtool.uk';
  static const String apiUrl = '$siteUrl/api';

  // Used if the server cannot be reached for settings.
  static const int defaultWordLimit = 1000;
  static const List<int> defaultLockedModes = [4, 5];

  static const String pricingUrl = '$siteUrl/pricing';
  static const String aboutUrl = '$siteUrl/about-us';
  static const String contactUrl = '$siteUrl/contact-us';
  static const String privacyUrl = '$siteUrl/privacy-policy';
  static const String termsUrl = '$siteUrl/terms-and-conditions';
}

/// Colors taken from the website (custom.css + logo).
class AppColors {
  static const Color purple = Color(0xFF550289);
  static const Color darkPurple = Color(0xFF33065B);
  static const Color orange = Color(0xFFFD7529);
  static const Color background = Color(0xFFFAFBFD);
  static const Color border = Color(0xFFE6E0EC);
}

class ParaphraseMode {
  final int id; // must match the mode number used by the server
  final String name;
  final String description;
  final String? icon; // asset path
  const ParaphraseMode(this.id, this.name, this.description, this.icon);
}

const List<ParaphraseMode> kModes = [
  ParaphraseMode(1, 'Elegant', 'Polished, refined wording', 'assets/modes/elegant.png'),
  ParaphraseMode(2, 'Basic', 'Small, safe changes', 'assets/modes/basic.png'),
  ParaphraseMode(3, 'Productive', 'Broader rewording', 'assets/modes/productive.png'),
  ParaphraseMode(4, 'Premium', 'Maximum rewriting', 'assets/modes/premium.png'),
  ParaphraseMode(5, 'Enterprise', 'Maximum rewriting for big text', 'assets/modes/enterprise.png'),
  ParaphraseMode(6, 'Humanize', 'Natural, conversational tone', 'assets/modes/enterprise.png'),
];

class AppLanguage {
  final String code; // sent to the server
  final String name;
  const AppLanguage(this.code, this.name);
}

const List<AppLanguage> kLanguages = [
  AppLanguage('en', 'English'),
  AppLanguage('es', 'Spanish'),
  AppLanguage('id', 'Indonesian'),
  AppLanguage('pt', 'Portuguese'),
];
