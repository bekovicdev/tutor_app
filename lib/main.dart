import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:tutor_app/auth/auth_page.dart';
import 'package:tutor_app/auth/auth_service.dart';
import 'package:tutor_app/auth/auth_storage.dart';
import 'package:tutor_app/pages/journal_page.dart';
import 'package:tutor_app/pages/payment_page.dart';
import 'package:tutor_app/pages/schedule_page.dart';
import 'package:tutor_app/pages/settings_page.dart';
import 'package:tutor_app/pages/students_page.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // App can still run without Firebase; FCM token will be skipped.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Tutor App',
      navigatorObservers: supportsLiquidGlass
          ? <NavigatorObserver>[CNTabBarRouteObserver()]
          : const <NavigatorObserver>[],
      theme: buildAppCupertinoTheme(Brightness.light),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

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
      _deepLinkSub = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _handleDeepLink(uri);
        },
        onError: (_) {},
      );
    } on MissingPluginException {
      // Plugin may be unavailable on current run.
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.host != 'auth-callback') {
      return;
    }

    final String? error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      await _showAuthErrorDialog(error);
      return;
    }

    final String? token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _authenticateWithToken(token);
    } on AuthException catch (authError) {
      await _showAuthErrorDialog(authError.message);
    } catch (_) {
      await _showAuthErrorDialog('OAuth login failed.');
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await showAppAlert<void>(
        context: context,
        title: 'OAuth Error',
        message: message,
        actions: const <AppAlertAction>[
          AppAlertAction(label: 'OK', style: AppAlertStyle.primary),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.platformBrightnessOf(context);
    final CupertinoThemeData theme = buildAppCupertinoTheme(brightness);

    Widget child;
    if (_isCheckingSession) {
      child = const CupertinoPageScaffold(
        child: SafeArea(
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
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
      );
    }

    return CupertinoTheme(data: theme, child: child);
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.session,
    required this.onLogout,
    super.key,
  });

  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  List<Widget> _pages() => <Widget>[
        StudentsPage(token: widget.session.token),
        SchedulePage(token: widget.session.token),
        JournalPage(token: widget.session.token),
        PaymentPage(token: widget.session.token),
        SettingsPage(
          userName: widget.session.user.name,
          onLogout: widget.onLogout,
        ),
      ];

  static const List<BottomNavigationBarItem> _classicTabItems =
      <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.person_2),
      label: 'Students',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.calendar),
      label: 'Schedule',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.book),
      label: 'Journal',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.money_dollar),
      label: 'Payment',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (supportsLiquidGlass) {
      return _buildLiquidGlassShell();
    }
    return _buildClassicShell();
  }

  Widget _buildClassicShell() {
    final List<Widget> pages = _pages();
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(items: _classicTabItems),
      tabBuilder: (BuildContext context, int index) => pages[index],
    );
  }

  Widget _buildLiquidGlassShell() {
    final List<Widget> pages = _pages();
    return CupertinoPageScaffold(
      backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: <Widget>[
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: IndexedStack(
                index: _index,
                children: pages,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: CNTabBar(
                currentIndex: _index,
                onTap: (int value) {
                  setState(() {
                    _index = value;
                  });
                },
                iconSize: 22,
                height: 54,
                items: const <CNTabBarItem>[
                  CNTabBarItem(
                    label: 'Students',
                    icon: CNSymbol('person.2'),
                    activeIcon: CNSymbol('person.2.fill'),
                    customIcon: CupertinoIcons.person_2,
                    activeCustomIcon: CupertinoIcons.person_2_fill,
                  ),
                  CNTabBarItem(
                    label: 'Schedule',
                    icon: CNSymbol('calendar'),
                    customIcon: CupertinoIcons.calendar,
                  ),
                  CNTabBarItem(
                    label: 'Journal',
                    icon: CNSymbol('book'),
                    activeIcon: CNSymbol('book.fill'),
                    customIcon: CupertinoIcons.book,
                    activeCustomIcon: CupertinoIcons.book_fill,
                  ),
                  CNTabBarItem(
                    label: 'Payment',
                    icon: CNSymbol('dollarsign.circle'),
                    activeIcon: CNSymbol('dollarsign.circle.fill'),
                    customIcon: CupertinoIcons.money_dollar_circle,
                    activeCustomIcon: CupertinoIcons.money_dollar_circle_fill,
                  ),
                  CNTabBarItem(
                    label: 'Settings',
                    icon: CNSymbol('gearshape'),
                    activeIcon: CNSymbol('gearshape.fill'),
                    customIcon: CupertinoIcons.settings,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
