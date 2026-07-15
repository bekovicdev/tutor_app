import 'package:flutter/widgets.dart';
import 'package:tutor_app/l10n/app_localizations.dart';

export 'package:tutor_app/l10n/app_localizations.dart';

/// Display currency symbol — fixed to USD (no FX conversion).
const String kCurrencyLabel = r'$';
const String kCurrencyCode = 'USD';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Always `$` — currency is not localized.
  String currencyLabel([String? _]) => kCurrencyLabel;
}

extension AppMoneyFormatX on AppLocalizations {
  String formatMoney(num amount, [String? _]) {
    final String formatted = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '$formatted $kCurrencyLabel';
  }
}
