import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_app/l10n/app_localizations.dart';

void main() {
  testWidgets('resolves Turkish from device locale', (WidgetTester tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('tr'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        child: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(l10n.tabStudents, 'Öğrenciler');
    expect(l10n.cancel, 'Vazgeç');
    expect(l10n.call, 'Ara');
  });

  testWidgets('resolves English from device locale', (WidgetTester tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        child: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(l10n.tabStudents, 'Students');
    expect(l10n.cancel, 'Cancel');
    expect(l10n.call, 'Call');
  });

  testWidgets('resolves Russian from device locale', (WidgetTester tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ru'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        child: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(l10n.tabStudents, 'Ученики');
    expect(l10n.cancel, 'Отмена');
    expect(l10n.call, 'Позвонить');
  });

  test('unsupported language falls back to English in resolution callback', () {
    Locale resolve(Locale? locale, Iterable<Locale> supported) {
      if (locale == null) {
        return const Locale('en');
      }
      for (final Locale supportedLocale in supported) {
        if (supportedLocale.languageCode == locale.languageCode) {
          return supportedLocale;
        }
      }
      return const Locale('en');
    }

    expect(
      resolve(const Locale('de'), AppLocalizations.supportedLocales),
      const Locale('en'),
    );
    expect(
      resolve(const Locale('tr', 'TR'), AppLocalizations.supportedLocales),
      const Locale('tr'),
    );
    expect(
      resolve(const Locale('ru', 'RU'), AppLocalizations.supportedLocales),
      const Locale('ru'),
    );
  });
}
