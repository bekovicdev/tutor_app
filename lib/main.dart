import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/auth/auth_page.dart';
import 'package:tutor_app/auth/auth_service.dart';
import 'package:tutor_app/auth/auth_storage.dart';
import 'package:tutor_app/billing/billing_service.dart';
import 'package:tutor_app/firebase_options.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_events.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/notifications/fcm_service.dart';
import 'package:tutor_app/notifications/lesson_reminders.dart';
import 'package:tutor_app/pages/journal_page.dart';
import 'package:tutor_app/pages/payment_page.dart';
import 'package:tutor_app/pages/calendar_page.dart';
import 'package:tutor_app/pages/home_page.dart';
import 'package:tutor_app/pages/settings_page.dart';
import 'package:tutor_app/pages/students_page.dart';
import 'package:tutor_app/payments/payment_service.dart';
import 'package:tutor_app/settings/app_currency.dart';
import 'package:tutor_app/settings/app_settings.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppCurrency.load();
  final bool firebaseReady = await _initFirebase();
  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FcmService.instance.initialize();
  } else {
    debugPrint(
      'Firebase not configured. Add GoogleService-Info.plist / '
      'google-services.json (or run `flutterfire configure`), then rebuild.',
    );
  }
  runApp(const MyApp());
}

Future<bool> _initFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      return true;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return Firebase.apps.isNotEmpty;
  } catch (error) {
    debugPrint('Firebase.initializeApp failed: $error');
    return false;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  AppThemePreference _themePreference = AppThemePreference.system;
  String _currencyCode = AppCurrency.code;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemePreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      applySystemUiOverlay(_resolvedBrightness);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_themePreference == AppThemePreference.system) {
      setState(() {});
      applySystemUiOverlay(_resolvedBrightness);
    }
  }

  Future<void> _loadThemePreference() async {
    final AppThemePreference preference = await AppSettings.themePreference();
    if (!mounted) {
      return;
    }
    setState(() {
      _themePreference = preference;
    });
    applySystemUiOverlay(_resolvedBrightness);
  }

  Future<void> _onThemePreferenceChanged(AppThemePreference value) async {
    setState(() {
      _themePreference = value;
    });
    applySystemUiOverlay(_resolvedBrightness);
    await AppSettings.setThemePreference(value);
  }

  Future<void> _onCurrencyChanged(String code) async {
    await AppCurrency.setCode(code);
    if (!mounted) {
      return;
    }
    setState(() {
      _currencyCode = AppCurrency.code;
    });
  }

  Brightness get _resolvedBrightness {
    final Brightness platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return AppSettings.resolveBrightness(_themePreference, platform);
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = _resolvedBrightness;

    return CupertinoApp(
      onGenerateTitle: (BuildContext context) => context.l10n.appTitle,
      theme: buildAppCupertinoTheme(brightness),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Device language; unsupported → English.
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> supportedLocales) {
            if (locale == null) {
              return const Locale('en');
            }
            for (final Locale supported in supportedLocales) {
              if (supported.languageCode == locale.languageCode) {
                return supported;
              }
            }
            return const Locale('en');
          },
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData media = MediaQuery.of(context);
        final TextStyle rootStyle = CupertinoTheme.of(
          context,
        ).textTheme.textStyle;
        return AppCurrencyScope(
          code: _currencyCode,
          child: MediaQuery(
            data: media.copyWith(platformBrightness: brightness),
            // Keep a stable non-inheriting root style so brightness changes
            // do not lerp inherit:true ↔ inherit:false TextStyles.
            child: DefaultTextStyle(
              style: rootStyle,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: AppRoot(
        themePreference: _themePreference,
        onThemePreferenceChanged: _onThemePreferenceChanged,
        currencyCode: _currencyCode,
        onCurrencyChanged: _onCurrencyChanged,
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({
    required this.themePreference,
    required this.onThemePreferenceChanged,
    required this.currencyCode,
    required this.onCurrencyChanged,
    super.key,
  });

  final AppThemePreference themePreference;
  final ValueChanged<AppThemePreference> onThemePreferenceChanged;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final AuthService _authService = AuthService();
  final AuthStorage _authStorage = AuthStorage();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSub;
  AuthSession? _session;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _restoreSession();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } on MissingPluginException {
      return;
    } catch (_) {
      // Ignore malformed initial links.
    }

    try {
      _deepLinkSub = _appLinks.uriLinkStream.listen((Uri uri) {
        _handleDeepLink(uri);
      }, onError: (_) {});
    } on MissingPluginException {
      // Plugin may be unavailable on current run.
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final bool isAuthCallback =
        uri.host == 'auth-callback' ||
        uri.pathSegments.contains('auth-callback') ||
        (uri.scheme == 'app' && uri.host == 'auth-callback');
    if (!isAuthCallback) {
      return;
    }

    final String? error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      await _showAuthErrorDialog(error);
      return;
    }

    final String? token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }
      await _showAuthErrorDialog(context.l10n.oauthLoginFailed);
      return;
    }

    try {
      await _authenticateWithToken(token);
    } on AuthException catch (authError) {
      await _showAuthErrorDialog(authError.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _showAuthErrorDialog(context.l10n.oauthLoginFailed);
    }
  }

  Future<void> _restoreSession() async {
    final String? token = await _authStorage.readToken();
    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCheckingSession = false;
      });
      return;
    }

    try {
      await _authenticateWithToken(token);
    } catch (_) {
      await _authStorage.clearToken();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
      }
    }
  }

  Future<void> _onAuthenticated(AuthSession session) async {
    await _authStorage.saveToken(session.token);
    await AppSettings.setIndividualLessonCost(
      session.user.individualLessonCost,
    );
    await AppSettings.setGroupLessonCost(session.user.groupLessonCost);
    await BillingService.configure(appUserId: '${session.user.id}');
    try {
      await BillingService().syncFromStore(session.token);
    } catch (_) {}
    await FcmService.instance.syncTokenForSession(token: session.token);
    if (!mounted) {
      return;
    }
    setState(() {
      _session = session;
    });
  }

  Future<void> _authenticateWithToken(String token) async {
    final AuthUser user = await _authService.me(token);
    await _authStorage.saveToken(token);
    await AppSettings.setIndividualLessonCost(user.individualLessonCost);
    await AppSettings.setGroupLessonCost(user.groupLessonCost);
    if (user.notificationsEnabled != null) {
      await AppSettings.setNotificationsEnabled(user.notificationsEnabled!);
    }
    await BillingService.configure(appUserId: '${user.id}');
    try {
      await BillingService().syncFromStore(token);
    } catch (_) {}
    await FcmService.instance.syncTokenForSession(token: token);
    if (!mounted) {
      return;
    }
    setState(() {
      _session = AuthSession(
        token: token,
        user: user,
        message: 'Authenticated',
      );
    });
  }

  Future<void> _logout() async {
    final AuthSession? currentSession = _session;
    if (currentSession == null) {
      return;
    }

    try {
      await _authService.logout(currentSession.token);
    } catch (_) {
      // Even if API logout fails, local token is cleared.
    }
    await _authStorage.clearToken();
    await LessonReminders.instance.cancelAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _session = null;
    });
  }

  Future<void> _showAuthErrorDialog(String message) async {
    if (!mounted) {
      return;
    }

    final String display = _friendlyOAuthMessage(message);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await showAppAlert<void>(
        context: context,
        title: context.l10n.oauthError,
        message: display,
        actions: <AppAlertAction>[
          AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
        ],
      );
    });
  }

  String _friendlyOAuthMessage(String message) {
    final String lower = message.toLowerCase();
    if (lower.contains('invalid_grant') ||
        lower.contains('redirect uri') ||
        lower.contains('redirect_uri')) {
      return context.l10n.oauthInvalidGrantHint;
    }
    // Strip Guzzle ClientException noise if backend somehow forwarded raw text.
    if (lower.contains('client error:') && lower.contains('googleapis.com')) {
      return context.l10n.oauthInvalidGrantHint;
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_isCheckingSession) {
      child = const CupertinoPageScaffold(
        child: SafeArea(child: Center(child: CupertinoActivityIndicator())),
      );
    } else if (_session == null) {
      child = AuthPage(
        authService: _authService,
        onAuthenticated: _onAuthenticated,
      );
    } else {
      child = AppShell(
        session: _session!,
        onLogout: _logout,
        themePreference: widget.themePreference,
        onThemePreferenceChanged: widget.onThemePreferenceChanged,
        currencyCode: widget.currencyCode,
        onCurrencyChanged: widget.onCurrencyChanged,
        onUserUpdated: (AuthUser user) {
          final AuthSession? current = _session;
          if (current == null) {
            return;
          }
          setState(() {
            _session = AuthSession(
              token: current.token,
              user: user,
              message: current.message,
            );
          });
        },
      );
    }

    return child;
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.session,
    required this.onLogout,
    required this.themePreference,
    required this.onThemePreferenceChanged,
    required this.currencyCode,
    required this.onCurrencyChanged,
    this.onUserUpdated,
    super.key,
  });

  final AuthSession session;
  final Future<void> Function() onLogout;
  final AppThemePreference themePreference;
  final ValueChanged<AppThemePreference> onThemePreferenceChanged;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<AuthUser>? onUserUpdated;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  static const int _paymentTabIndex = 4;

  final CupertinoTabController _tabController = CupertinoTabController();
  late final List<Widget> _tabPages;
  int _unpaidLessonCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController.addListener(_onTabChanged);
    LessonEvents.listenable.addListener(_rescheduleReminders);
    unawaited(LessonReminders.instance.sync(widget.session.token));
    _tabPages = <Widget>[
      StudentsPage(token: widget.session.token, onOpenSettings: _openSettings),
      CalendarPage(token: widget.session.token, onOpenSettings: _openSettings),
      HomePage(token: widget.session.token, onOpenSettings: _openSettings),
      JournalPage(token: widget.session.token, onOpenSettings: _openSettings),
      PaymentPage(
        token: widget.session.token,
        onOpenSettings: _openSettings,
        onSettlementsChanged: _refreshPaymentBadge,
      ),
    ];
    _refreshPaymentBadge();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkOverdueLessons());
    });
  }

  String _formatDateKey(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// On app open, ask about any lesson that was scheduled but whose end
  /// time has already passed, so completed/cancelled status stays accurate.
  Future<void> _checkOverdueLessons() async {
    final LessonService lessonService = LessonService(
      token: widget.session.token,
    );
    final DateTime now = DateTime.now();
    final DateTime rangeStart = now.subtract(const Duration(days: 30));

    List<Lesson> lessons;
    try {
      lessons = await lessonService.listLessons(
        status: 'scheduled',
        startDate: _formatDateKey(rangeStart),
        endDate: _formatDateKey(now),
        sortBy: 'date',
        sortDirection: 'asc',
      );
    } catch (_) {
      return;
    }

    final List<Lesson> overdue =
        lessons.where((Lesson lesson) {
          final DateTime? lessonDate = DateTime.tryParse(lesson.date);
          if (lessonDate == null) {
            return false;
          }
          final DateTime endAt = lessonDate.add(
            Duration(minutes: lesson.endMinutes),
          );
          return endAt.isBefore(now);
        }).toList()..sort((Lesson a, Lesson b) {
          final int byDate = a.date.compareTo(b.date);
          if (byDate != 0) {
            return byDate;
          }
          return a.startMinutes.compareTo(b.startMinutes);
        });

    bool anyResolved = false;
    for (final Lesson lesson in overdue) {
      if (!mounted) {
        return;
      }
      final String? decision = await _askLessonCompletion(lesson);
      if (decision == null) {
        continue;
      }
      try {
        await lessonService.updateLesson(
          id: lesson.id,
          body: <String, dynamic>{'status': decision},
        );
        anyResolved = true;
      } catch (_) {
        // Ignore; will be asked again next time the app opens.
      }
    }
    if (anyResolved) {
      LessonEvents.notifyChanged();
    }
    if (anyResolved && mounted) {
      await _refreshPaymentBadge();
    }
  }

  Future<String?> _askLessonCompletion(Lesson lesson) {
    final AppLocalizations l10n = context.l10n;
    final DateTime? lessonDate = DateTime.tryParse(lesson.date);
    final String when = lessonDate == null
        ? lesson.date
        : intl.DateFormat.yMMMEd(
            Localizations.localeOf(context).toLanguageTag(),
          ).add_Hm().format(
            lessonDate.add(Duration(minutes: lesson.startMinutes)),
          );
    return showAppAlert<String>(
      context: context,
      title: l10n.lessonCompletionCheckTitle,
      message: l10n.lessonCompletionCheckMessage(lesson.displayTitle, when),
      barrierDismissible: false,
      actions: <AppAlertAction>[
        AppAlertAction(
          label: l10n.markCompleted,
          style: AppAlertStyle.primary,
          onPressed: (BuildContext dialogContext) =>
              Navigator.of(dialogContext).pop('completed'),
        ),
        AppAlertAction(
          label: l10n.cancelled,
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext dialogContext) =>
              Navigator.of(dialogContext).pop('cancelled'),
        ),
        AppAlertAction(
          label: l10n.askLater,
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext dialogContext) =>
              Navigator.of(dialogContext).pop(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LessonEvents.listenable.removeListener(_rescheduleReminders);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(LessonReminders.instance.sync(widget.session.token));
    }
  }

  void _rescheduleReminders() {
    unawaited(LessonReminders.instance.sync(widget.session.token));
  }

  void _onTabChanged() {
    if (_tabController.index == _paymentTabIndex) {
      _refreshPaymentBadge();
    }
  }

  Future<void> _refreshPaymentBadge() async {
    try {
      final PaymentsOverview overview = await PaymentService(
        token: widget.session.token,
      ).overview();
      if (!mounted) {
        return;
      }
      final int next = overview.unpaid.count;
      if (next == _unpaidLessonCount) {
        return;
      }
      setState(() {
        _unpaidLessonCount = next;
      });
    } catch (_) {
      // Badge is optional; ignore network/store errors.
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => SettingsPage(
          user: widget.session.user,
          token: widget.session.token,
          onLogout: widget.onLogout,
          themePreference: widget.themePreference,
          onThemePreferenceChanged: widget.onThemePreferenceChanged,
          currencyCode: widget.currencyCode,
          onCurrencyChanged: widget.onCurrencyChanged,
          onUserUpdated: widget.onUserUpdated,
        ),
      ),
    );
  }

  Widget _tabIcon(IconData icon, {int badgeCount = 0}) {
    if (badgeCount <= 0) {
      return Icon(icon);
    }
    final String label = badgeCount > 99 ? '99+' : '$badgeCount';
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(icon),
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<BottomNavigationBarItem> _tabItems(AppLocalizations l10n) =>
      <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.person_2),
          activeIcon: const Icon(CupertinoIcons.person_2_fill),
          label: l10n.tabStudents,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.calendar),
          activeIcon: const Icon(CupertinoIcons.calendar_today),
          label: l10n.tabCalendar,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.house),
          activeIcon: const Icon(CupertinoIcons.house_fill),
          label: l10n.tabHome,
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.book),
          activeIcon: const Icon(CupertinoIcons.book_fill),
          label: l10n.tabJournal,
        ),
        BottomNavigationBarItem(
          icon: _tabIcon(
            CupertinoIcons.money_dollar_circle,
            badgeCount: _unpaidLessonCount,
          ),
          activeIcon: _tabIcon(
            CupertinoIcons.money_dollar_circle_fill,
            badgeCount: _unpaidLessonCount,
          ),
          label: l10n.tabPayment,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(items: _tabItems(context.l10n)),
      tabBuilder: (BuildContext context, int index) => _tabPages[index],
    );
  }
}
