import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tutor_app/notifications/fcm_service.dart';
import 'package:tutor_app/auth/auth_service.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

enum AuthMode { login, register }

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.authService,
    required this.onAuthenticated,
    this.initialMode = AuthMode.login,
    super.key,
  });

  final AuthService authService;
  final Future<void> Function(AuthSession session) onAuthenticated;
  final AuthMode initialMode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late AuthMode _mode;
  bool _isLoading = false;
  final FcmService _fcmService = FcmService();
  int _registerStep = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _individualCostController =
      TextEditingController();
  final TextEditingController _groupCostController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _phoneController.dispose();
    _individualCostController.dispose();
    _groupCostController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final AppLocalizations l10n = context.l10n;
    final bool isRegister = _mode == AuthMode.register;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l10n.appTitle)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 8),
            Text(
              isRegister ? l10n.createAccountTitle : l10n.welcomeTitle,
              style: theme.textTheme.navLargeTitleTextStyle.copyWith(
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.authSubtitle,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            if (isRegister)
              _buildRegisterStepCard(context)
            else
              _buildLoginCard(context),
            const SizedBox(height: 18),
            if (!isRegister)
              SizedBox(
                height: 50,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : Text(l10n.login),
                ),
              ),
            if (isRegister) _buildRegisterActions(),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(child: _separatorLine(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    l10n.orContinueWith,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
                Expanded(child: _separatorLine(context)),
              ],
            ),
            const SizedBox(height: 12),
            _oauthButton(
              context: context,
              icon: FontAwesomeIcons.google,
              label: l10n.continueWithGoogle,
              backgroundColor: CupertinoColors.white,
              foregroundColor: CupertinoColors.black,
              onPressed: _isLoading ? null : () => _startOAuth('google'),
            ),
            const SizedBox(height: 10),
            _oauthButton(
              context: context,
              icon: FontAwesomeIcons.apple,
              label: l10n.continueWithApple,
              backgroundColor: CupertinoColors.black,
              foregroundColor: CupertinoColors.white,
              onPressed: _isLoading ? null : () => _startOAuth('apple'),
            ),
            const SizedBox(height: 16),
            if (isRegister)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    l10n.alreadyHaveAccount,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.only(left: 6, right: 0),
                    minSize: 0,
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                builder: (BuildContext context) => AuthPage(
                                  authService: widget.authService,
                                  onAuthenticated: widget.onAuthenticated,
                                  initialMode: AuthMode.login,
                                ),
                              ),
                            );
                          },
                    child: Text(l10n.login),
                  ),
                ],
              ),
            if (!isRegister)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    l10n.dontHaveAccount,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.only(left: 6, right: 0),
                    minSize: 0,
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                              return;
                            }
                            Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                builder: (BuildContext context) => AuthPage(
                                  authService: widget.authService,
                                  onAuthenticated: widget.onAuthenticated,
                                  initialMode: AuthMode.register,
                                ),
                              ),
                            );
                          },
                    child: Text(l10n.register),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return _authCard(
      context,
      children: <Widget>[
        _field(
          controller: _emailController,
          placeholder: l10n.email,
          prefixIcon: CupertinoIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _passwordController,
          placeholder: l10n.password,
          prefixIcon: CupertinoIcons.lock,
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildRegisterStepCard(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (_registerStep == 0) {
      return _authCard(
        context,
        title: l10n.stepOf(1, 3),
        children: <Widget>[
          _field(
            controller: _nameController,
            placeholder: l10n.name,
            prefixIcon: CupertinoIcons.person,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _field(
            controller: _emailController,
            placeholder: l10n.email,
            prefixIcon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _field(
            controller: _phoneController,
            placeholder: l10n.phone,
            prefixIcon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
        ],
      );
    }

    if (_registerStep == 1) {
      return _authCard(
        context,
        title: l10n.stepOf(2, 3),
        children: <Widget>[
          _field(
            controller: _passwordController,
            placeholder: l10n.password,
            prefixIcon: CupertinoIcons.lock,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _field(
            controller: _passwordConfirmationController,
            placeholder: l10n.passwordConfirmation,
            prefixIcon: CupertinoIcons.lock_shield,
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),
        ],
      );
    }

    return _authCard(
      context,
      title: l10n.stepOf(3, 3),
      children: <Widget>[
        _field(
          controller: _individualCostController,
          placeholder: l10n.individualLessonCostOptional,
          prefixIcon: CupertinoIcons.money_dollar_circle,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _groupCostController,
          placeholder: l10n.groupLessonCostOptional,
          prefixIcon: CupertinoIcons.money_dollar_circle_fill,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildRegisterActions() {
    final AppLocalizations l10n = context.l10n;
    final bool isLastStep = _registerStep == 2;
    return Row(
      children: <Widget>[
        if (_registerStep > 0)
          Expanded(
            child: SizedBox(
              height: 50,
              child: CupertinoButton(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.secondarySystemBackground,
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _registerStep -= 1;
                        });
                      },
                child: Text(l10n.back),
              ),
            ),
          ),
        if (_registerStep > 0) const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _isLoading
                  ? null
                  : () {
                      if (isLastStep) {
                        _submit();
                        return;
                      }
                      _goToNextRegisterStep();
                    },
              child: _isLoading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : Text(isLastStep ? l10n.createAccount : l10n.next),
            ),
          ),
        ),
      ],
    );
  }

  Widget _authCard(
    BuildContext context, {
    required List<Widget> children,
    String? title,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _oauthButton({
    required BuildContext context,
    required FaIconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback? onPressed,
  }) {
    final bool isGoogle = label.contains('Google');
    final Color borderColor = isGoogle
        ? CupertinoColors.systemGrey4.resolveFrom(context)
        : CupertinoColors.black;

    return SizedBox(
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          borderRadius: BorderRadius.circular(12),
          onPressed: onPressed,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 22,
                child: Center(
                  child: FaIcon(icon, size: 18, color: foregroundColor),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _separatorLine(BuildContext context) {
    return Container(
      height: 1,
      color: CupertinoColors.systemGrey4.resolveFrom(context),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String placeholder,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextInputAction? textInputAction,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(prefixIcon, size: 18, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
    );
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (_mode == AuthMode.login) {
      if (email.isEmpty || password.isEmpty) {
        await _showMessage(context.l10n.emailPasswordRequired);
        return;
      }
    } else {
      if (_nameController.text.trim().isEmpty) {
        await _showMessage(context.l10n.nameRequired);
        return;
      }
      if (_passwordConfirmationController.text.isEmpty) {
        await _showMessage(context.l10n.passwordConfirmationRequired);
        return;
      }
      if (email.isEmpty || password.isEmpty) {
        await _showMessage(context.l10n.emailPasswordRequired);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      late final AuthSession session;
      final String? fcmToken = await _fcmService.getDeviceToken();
      if (_mode == AuthMode.login) {
        session = await widget.authService.login(
          email: email,
          password: password,
          fcmToken: fcmToken,
        );
      } else {
        session = await widget.authService.register(
          RegisterRequest(
            name: _nameController.text.trim(),
            email: email,
            password: password,
            passwordConfirmation: _passwordConfirmationController.text,
            phone: _phoneController.text.trim(),
            individualLessonCost: _toDoubleOrNull(
              _individualCostController.text,
            ),
            groupLessonCost: _toDoubleOrNull(_groupCostController.text),
            fcmToken: fcmToken,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      await widget.onAuthenticated(session);
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).popUntil((
        Route<dynamic> route,
      ) {
        return route.isFirst;
      });
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
        await _showMessage(context.l10n.couldNotOpenOAuth);
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
      await _showMessage(context.l10n.oauthCouldNotStart);
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

  Future<void> _goToNextRegisterStep() async {
    if (_registerStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        await _showMessage(context.l10n.nameRequired);
        return;
      }
      if (_emailController.text.trim().isEmpty) {
        await _showMessage(context.l10n.emailRequired);
        return;
      }
    }

    if (_registerStep == 1) {
      if (_passwordController.text.isEmpty) {
        await _showMessage(context.l10n.passwordRequired);
        return;
      }
      if (_passwordConfirmationController.text.isEmpty) {
        await _showMessage(context.l10n.passwordConfirmationRequired);
        return;
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _registerStep += 1;
    });
  }

  Future<void> _showMessage(String message) {
    return showAppAlert<void>(
      context: context,
      title: context.l10n.authTitle,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }
}
