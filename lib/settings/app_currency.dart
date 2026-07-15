import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A supported display currency (label only — no FX conversion).
class AppCurrencyOption {
  const AppCurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;

  String get displayLabel => '$symbol · $code';
}

/// App-wide currency preference. Default: USD.
abstract final class AppCurrency {
  static const String defaultCode = 'USD';
  static const String _prefsKey = 'settings.currency';

  static const List<AppCurrencyOption> options = <AppCurrencyOption>[
    AppCurrencyOption(code: 'USD', symbol: r'$', name: 'US Dollar'),
    AppCurrencyOption(code: 'EUR', symbol: '€', name: 'Euro'),
    AppCurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound'),
    AppCurrencyOption(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
    AppCurrencyOption(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
    AppCurrencyOption(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    AppCurrencyOption(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    AppCurrencyOption(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
    AppCurrencyOption(code: 'CAD', symbol: r'C$', name: 'Canadian Dollar'),
    AppCurrencyOption(code: 'AUD', symbol: r'A$', name: 'Australian Dollar'),
    AppCurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    AppCurrencyOption(code: 'CNY', symbol: 'CN¥', name: 'Chinese Yuan'),
    AppCurrencyOption(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    AppCurrencyOption(code: 'BRL', symbol: r'R$', name: 'Brazilian Real'),
    AppCurrencyOption(code: 'MXN', symbol: r'MX$', name: 'Mexican Peso'),
    AppCurrencyOption(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
    AppCurrencyOption(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
    AppCurrencyOption(code: 'PLN', symbol: 'zł', name: 'Polish Zloty'),
    AppCurrencyOption(code: 'KZT', symbol: '₸', name: 'Kazakhstani Tenge'),
    AppCurrencyOption(code: 'AZN', symbol: '₼', name: 'Azerbaijani Manat'),
  ];

  static final Map<String, AppCurrencyOption> _byCode = <String, AppCurrencyOption>{
    for (final AppCurrencyOption o in options) o.code: o,
  };

  static String _code = defaultCode;

  static String get code => _code;

  static AppCurrencyOption get current =>
      _byCode[_code] ?? _byCode[defaultCode]!;

  static Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_prefsKey)?.trim().toUpperCase();
    if (stored != null && _byCode.containsKey(stored)) {
      _code = stored;
    } else {
      _code = defaultCode;
    }
  }

  static Future<void> setCode(String code) async {
    final String normalized = code.trim().toUpperCase();
    if (!_byCode.containsKey(normalized)) {
      return;
    }
    _code = normalized;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, normalized);
  }

  static AppCurrencyOption? optionFor(String? code) {
    if (code == null) {
      return null;
    }
    return _byCode[code.trim().toUpperCase()];
  }

  static String symbolFor(String? code) {
    return optionFor(code)?.symbol ?? current.symbol;
  }

  static String resolveCode(String? preference) {
    if (preference != null && _byCode.containsKey(preference)) {
      return preference;
    }
    return defaultCode;
  }
}

/// Provides the selected currency code to the widget tree.
class AppCurrencyScope extends InheritedWidget {
  const AppCurrencyScope({
    required this.code,
    required super.child,
    super.key,
  });

  final String code;

  static AppCurrencyScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppCurrencyScope>();
  }

  static String codeOf(BuildContext context) {
    return maybeOf(context)?.code ?? AppCurrency.code;
  }

  static String symbolOf(BuildContext context) {
    return AppCurrency.symbolFor(codeOf(context));
  }

  @override
  bool updateShouldNotify(AppCurrencyScope oldWidget) => code != oldWidget.code;
}
