import 'package:flutter/cupertino.dart';
import 'package:tutor_app/auth/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum AuthMode { login, register }

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.authService,
    required this.onAuthenticated,
    super.key,
  });

  final AuthService authService;
  final Future<void> Function(AuthSession session) onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthMode _mode = AuthMode.login;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _individualCostController = TextEditingController();
  final TextEditingController _groupCostController = TextEditingController();
  final TextEditingController _fcmTokenController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _phoneController.dispose();
    _individualCostController.dispose();
    _groupCostController.dispose();
    _fcmTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Tutor App'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 8),
            CupertinoSlidingSegmentedControl<AuthMode>(
              groupValue: _mode,
              children: const <AuthMode, Widget>{
                AuthMode.login: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Login'),
                ),
                AuthMode.register: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Register'),
                ),
              },
              onValueChanged: (AuthMode? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _mode = value;
                });
              },
            ),
            const SizedBox(height: 20),
            if (_mode == AuthMode.register) ...<Widget>[
              _field(
                controller: _nameController,
                placeholder: 'Name',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
            ],
            _field(
              controller: _emailController,
              placeholder: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _passwordController,
              placeholder: 'Password',
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            if (_mode == AuthMode.register) ...<Widget>[
              const SizedBox(height: 12),
              _field(
                controller: _passwordConfirmationController,
                placeholder: 'Password Confirmation',
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _phoneController,
                placeholder: 'Phone (optional)',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _individualCostController,
                placeholder: 'Individual Lesson Cost (optional)',
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _groupCostController,
                placeholder: 'Group Lesson Cost (optional)',
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _fcmTokenController,
                placeholder: 'FCM Token (optional)',
                textInputAction: TextInputAction.done,
              ),
            ],
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : Text(_mode == AuthMode.login ? 'Login' : 'Create Account'),
            ),
            if (_mode == AuthMode.login) ...<Widget>[
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: _isLoading ? null : () => _startOAuth('google'),
                child: const Text('Continue with Google'),
              ),
              CupertinoButton(
                onPressed: _isLoading ? null : () => _startOAuth('apple'),
                child: const Text('Continue with Apple'),
              ),
              const Text(
                'Set backend redirect to: app://auth-callback?token=...',
                textAlign: TextAlign.center,
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextInputAction? textInputAction,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
    );
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      await _showMessage('Email and password are required.');
      return;
    }

    if (_mode == AuthMode.register) {
      if (_nameController.text.trim().isEmpty) {
        await _showMessage('Name is required.');
        return;
      }
      if (_passwordConfirmationController.text.isEmpty) {
        await _showMessage('Password confirmation is required.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      late final AuthSession session;
      if (_mode == AuthMode.login) {
        session = await widget.authService.login(
          email: email,
          password: password,
        );
      } else {
        session = await widget.authService.register(
          RegisterRequest(
            name: _nameController.text.trim(),
            email: email,
            password: password,
            passwordConfirmation: _passwordConfirmationController.text,
            phone: _phoneController.text.trim(),
            individualLessonCost: _toDoubleOrNull(_individualCostController.text),
            groupLessonCost: _toDoubleOrNull(_groupCostController.text),
            fcmToken: _fcmTokenController.text.trim(),
          ),
        );
      }
      if (!mounted) {
        return;
      }
      await widget.onAuthenticated(session);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      await _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startOAuth(String provider) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final String url = await widget.authService.oauthRedirectUrl(provider);
      final Uri uri = Uri.parse(url);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        await _showMessage('Could not open OAuth page.');
      }
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      await _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _showMessage('OAuth flow could not be started.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double? _toDoubleOrNull(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  Future<void> _showMessage(String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Auth'),
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
  }
}
