import 'dart:async';

import 'package:app_links/app_links.dart';
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Tutor App',
      home: AppRoot(),
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
      // Plugin may be unavailable in hot-reload lifecycle.
      return;
    } catch (_) {
      // Ignore malformed initial links.
    }

    try {
      _deepLinkSub = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _handleDeepLink(uri);
        },
        onError: (_) {
          // Keep app running if plugin stream fails.
        },
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
      await showCupertinoDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('OAuth Error'),
            content: Text(message),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const CupertinoPageScaffold(
        child: SafeArea(
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
    }

    if (_session == null) {
      return AuthPage(
        authService: _authService,
        onAuthenticated: _onAuthenticated,
      );
    }
    return AppShell(
      session: _session!,
      onLogout: _logout,
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    required this.session,
    required this.onLogout,
    super.key,
  });

  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const StudentsPage(),
      const SchedulePage(),
      const JournalPage(),
      const PaymentPage(),
      SettingsPage(
        userName: session.user.name,
        onLogout: onLogout,
      ),
    ];

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
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
        ],
      ),
      tabBuilder: (BuildContext context, int index) => pages[index],
    );
  }
}
