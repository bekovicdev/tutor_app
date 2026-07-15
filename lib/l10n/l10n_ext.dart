import 'package:flutter/widgets.dart';
import 'package:tutor_app/l10n/app_localizations.dart';
import 'package:tutor_app/settings/app_currency.dart';

export 'package:tutor_app/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Active display currency code from settings.
  String get activeCurrencyCode => AppCurrencyScope.codeOf(this);

  /// Display symbol for the selected currency (ignores API codes).
  String currencyLabel([String? _]) => AppCurrencyScope.symbolOf(this);
}

extension AppMoneyFormatX on AppLocalizations {
  String formatMoney(num amount, [String? code]) {
    final String formatted = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '$formatted ${AppCurrency.symbolFor(code)}';
  }
}
