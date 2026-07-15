import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:tutor_app/auth/auth_service.dart';
import 'package:tutor_app/billing/billing_service.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/notifications/fcm_service.dart';
import 'package:tutor_app/pages/paywall_page.dart';
import 'package:tutor_app/settings/app_currency.dart';
import 'package:tutor_app/settings/app_settings.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.user,
    required this.token,
    required this.onLogout,
    required this.themePreference,
    required this.onThemePreferenceChanged,
    required this.currencyCode,
    required this.onCurrencyChanged,
    this.onUserUpdated,
    super.key,
  });

  final AuthUser user;
  final String token;
  final Future<void> Function() onLogout;
  final AppThemePreference themePreference;
  final ValueChanged<AppThemePreference> onThemePreferenceChanged;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<AuthUser>? onUserUpdated;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final BillingService _billingService = BillingService();
  bool _notificationsEnabled = true;
  bool _loadingPrefs = true;
  bool _savingCosts = false;
  BillingStatus? _billingStatus;
  late String _currencyCode;
  final TextEditingController _individualCostController =
      TextEditingController();
  final TextEditingController _groupCostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currencyCode = widget.currencyCode;
    _loadPrefs();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currencyCode != widget.currencyCode) {
      _currencyCode = widget.currencyCode;
    }
  }

  @override
  void dispose() {
    _individualCostController.dispose();
    _groupCostController.dispose();
    super.dispose();
  }

  /// Default lesson costs are whole dollar amounts — no decimals.
  String _costAsIntText(String? raw) {
    if (raw == null) {
      return '';
    }
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final num? value = num.tryParse(trimmed.replaceAll(',', '.'));
    if (value == null || value < 0) {
      return '';
    }
    return value.round().toString();
  }

  Future<void> _loadPrefs() async {
    final bool notifications = await AppSettings.notificationsEnabled();
    String individual = _costAsIntText(widget.user.individualLessonCost);
    String group = _costAsIntText(widget.user.groupLessonCost);
    bool notificationsFromApi = notifications;
    BillingStatus? billing;

    try {
      final AuthUser fresh = await _authService.me(widget.token);
      individual = _costAsIntText(
        fresh.individualLessonCost ?? widget.user.individualLessonCost,
      );
      group = _costAsIntText(
        fresh.groupLessonCost ?? widget.user.groupLessonCost,
      );
      if (fresh.notificationsEnabled != null) {
        notificationsFromApi = fresh.notificationsEnabled!;
        await AppSettings.setNotificationsEnabled(notificationsFromApi);
      }
      await AppSettings.setIndividualLessonCost(
        individual.isEmpty ? null : individual,
      );
      await AppSettings.setGroupLessonCost(group.isEmpty ? null : group);
      widget.onUserUpdated?.call(fresh);
      billing = await _billingService.fetchStatus(widget.token);
    } on AuthException {
      final String? localIndividual = await AppSettings.individualLessonCost();
      final String? localGroup = await AppSettings.groupLessonCost();
      if (individual.isEmpty) {
        individual = _costAsIntText(localIndividual);
      }
      if (group.isEmpty) {
        group = _costAsIntText(localGroup);
      }
    } on BillingException {
      // Optional card; settings still load.
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsEnabled = notificationsFromApi;
      _billingStatus = billing;
      _individualCostController.text = individual;
      _groupCostController.text = group;
      _loadingPrefs = false;
    });
  }

  Future<void> _openPaywall() async {
    final BillingStatus? updated = await openPaywall(
      context,
      token: widget.token,
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _billingStatus = updated;
    });
    widget.onUserUpdated?.call(
      widget.user.copyWith(
        isPremium: updated.isPremium,
        premiumStartAt: updated.premiumStartAt?.toIso8601String(),
        premiumEndAt: updated.premiumEndAt?.toIso8601String(),
      ),
    );
  }

  Future<void> _setNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    try {
      await FcmService.instance.setNotificationsEnabled(
        authToken: widget.token,
        enabled: value,
      );
      final AuthUser updated = widget.user.copyWith(
        notificationsEnabled: value,
      );
      widget.onUserUpdated?.call(updated);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notificationsEnabled = !value;
      });
      await AppSettings.setNotificationsEnabled(!value);
    }
  }

  Future<void> _saveCosts() async {
    if (_savingCosts) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final String individualRaw = _individualCostController.text.trim();
    final String groupRaw = _groupCostController.text.trim();

    int? individual;
    int? group;
    if (individualRaw.isNotEmpty) {
      individual = int.tryParse(individualRaw);
      if (individual == null || individual < 0) {
        await showAppAlert<void>(
          context: context,
          title: l10n.teaching,
          message: l10n.enterValidPrice,
          actions: <AppAlertAction>[
            AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
          ],
        );
        return;
      }
    }
    if (groupRaw.isNotEmpty) {
      group = int.tryParse(groupRaw);
      if (group == null || group < 0) {
        await showAppAlert<void>(
          context: context,
          title: l10n.teaching,
          message: l10n.enterValidPrice,
          actions: <AppAlertAction>[
            AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
          ],
        );
        return;
      }
    }

    final String individualText =
        individual == null ? '' : individual.toString();
    final String groupText = group == null ? '' : group.toString();
    _individualCostController.text = individualText;
    _groupCostController.text = groupText;

    setState(() {
      _savingCosts = true;
    });
    try {
      final AuthUser updated = await _authService.updateProfile(
        token: widget.token,
        individualLessonCost: individual,
        groupLessonCost: group,
        clearIndividualLessonCost: individualText.isEmpty,
        clearGroupLessonCost: groupText.isEmpty,
      );
      await AppSettings.setIndividualLessonCost(
        individualText.isEmpty ? null : individualText,
      );
      await AppSettings.setGroupLessonCost(
        groupText.isEmpty ? null : groupText,
      );
      widget.onUserUpdated?.call(updated);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      await showAppAlert<void>(
        context: context,
        title: l10n.teaching,
        message: error.message,
        actions: <AppAlertAction>[
          AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
        ],
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingCosts = false;
        });
      }
    }
  }

  Future<void> _confirmLogout() async {
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showAppAlert<bool>(
      context: context,
      title: l10n.logoutConfirmTitle,
      message: l10n.logoutConfirmMessage,
      icon: CupertinoIcons.square_arrow_right,
      actions: <AppAlertAction>[
        AppAlertAction(
          label: l10n.cancel,
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext dialogContext) {
            Navigator.of(dialogContext).pop(false);
          },
        ),
        AppAlertAction(
          label: l10n.logout,
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext dialogContext) {
            Navigator.of(dialogContext).pop(true);
          },
        ),
      ],
    );
    if (confirmed == true) {
      await widget.onLogout();
    }
  }

  Future<void> _showEditProfileSoon() async {
    final AppLocalizations l10n = context.l10n;
    await showAppAlert<void>(
      context: context,
      title: l10n.editProfile,
      message: l10n.editProfileComingSoon,
      actions: <AppAlertAction>[
        AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }

  Future<void> _showSupport() async {
    final AppLocalizations l10n = context.l10n;
    await showAppAlert<void>(
      context: context,
      title: l10n.support,
      message: l10n.supportMessage,
      icon: CupertinoIcons.mail,
      actions: <AppAlertAction>[
        AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }

  String _languageLabel(AppLocalizations l10n) {
    final String code = Localizations.localeOf(context).languageCode;
    return switch (code) {
      'tr' => l10n.languageTurkish,
      'en' => l10n.languageEnglish,
      'ru' => l10n.languageRussian,
      _ => code.toUpperCase(),
    };
  }

  String get _currencyValueLabel {
    final AppCurrencyOption option =
        AppCurrency.optionFor(_currencyCode) ?? AppCurrency.current;
    return '${option.symbol} · ${option.code}';
  }

  Future<void> _pickCurrency() async {
    final AppLocalizations l10n = context.l10n;
    await showAppActionSheet<void>(
      context: context,
      title: l10n.currency,
      actions: AppCurrency.options.map((AppCurrencyOption option) {
        final bool selected = option.code == _currencyCode;
        return AppSheetAction(
          label: selected
              ? '✓ ${option.symbol}  ${option.code} — ${option.name}'
              : '${option.symbol}  ${option.code} — ${option.name}',
          onPressed: (BuildContext ctx) {
            setState(() {
              _currencyCode = option.code;
            });
            widget.onCurrencyChanged(option.code);
            Navigator.of(ctx).pop();
          },
        );
      }).toList(),
    );
  }

  String get _initials {
    final String name = widget.user.name.trim();
    if (name.isEmpty) {
      return '?';
    }
    final List<String> parts =
        name.split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    String firstChar(String value) {
      final Runes runes = value.runes;
      if (runes.isEmpty) {
        return '?';
      }
      return String.fromCharCode(runes.first).toUpperCase();
    }

    if (parts.length == 1) {
      return firstChar(parts.first);
    }
    return '${firstChar(parts.first)}${firstChar(parts.last)}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.settings),
        border: appNavigationBarBorderOf(context),
      ),
      child: SafeArea(
        child: _loadingPrefs
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: <Widget>[
                  _profileCard(l10n),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.manageSubscription),
                  _groupedCard(
                    children: <Widget>[
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: (_billingStatus?.isPremium ??
                                widget.user.isPremium == true)
                            ? null
                            : _openPaywall,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Row(
                            children: <Widget>[
                              _iconBadge(
                                CupertinoIcons.star_fill,
                                AppBrand.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      (_billingStatus?.isPremium ??
                                              widget.user.isPremium == true)
                                          ? l10n.premiumActive
                                          : l10n.premiumFree,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: CupertinoColors.label,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!(_billingStatus?.isPremium ??
                                  widget.user.isPremium == true))
                                Text(
                                  l10n.upgradeToPremium,
                                  style: const TextStyle(
                                    color: AppBrand.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.teaching),
                  _groupedCard(
                    children: <Widget>[
                      _costRow(
                        icon: CupertinoIcons.person_fill,
                        iconColor: AppBrand.primary,
                        title: l10n.defaultIndividualCost,
                        controller: _individualCostController,
                        placeholder: '0',
                      ),
                      _divider(),
                      _costRow(
                        icon: CupertinoIcons.person_3_fill,
                        iconColor: const Color(0xFFAF52DE),
                        title: l10n.defaultGroupCost,
                        controller: _groupCostController,
                        placeholder: '0',
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      l10n.teachingDefaultsHint,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.preferences),
                  _groupedCard(
                    children: <Widget>[
                      _switchRow(
                        icon: CupertinoIcons.bell_fill,
                        iconColor: AppBrand.primary,
                        title: l10n.notifications,
                        subtitle: l10n.notificationsSubtitle,
                        value: _notificationsEnabled,
                        onChanged: _setNotifications,
                      ),
                      _divider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                _iconBadge(
                                  CupertinoIcons.moon_stars_fill,
                                  const Color(0xFF5856D6),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.appearance,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CupertinoSlidingSegmentedControl<
                                AppThemePreference>(
                              groupValue: widget.themePreference,
                              onValueChanged: (AppThemePreference? value) {
                                if (value != null) {
                                  widget.onThemePreferenceChanged(value);
                                }
                              },
                              children: <AppThemePreference, Widget>{
                                AppThemePreference.system: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text(l10n.themeSystem),
                                ),
                                AppThemePreference.light: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text(l10n.themeLight),
                                ),
                                AppThemePreference.dark: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text(l10n.themeDark),
                                ),
                              },
                            ),
                          ],
                        ),
                      ),
                      _divider(),
                      _infoRow(
                        icon: CupertinoIcons.globe,
                        iconColor: AppBrand.primary,
                        title: l10n.language,
                        value: _languageLabel(l10n),
                        subtitle: l10n.languageFollowsDevice,
                      ),
                      _divider(),
                      _navRow(
                        icon: CupertinoIcons.money_dollar_circle_fill,
                        iconColor: const Color(0xFF30B0C7),
                        title: l10n.currency,
                        value: _currencyValueLabel,
                        showChevron: true,
                        onTap: _pickCurrency,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.about),
                  _groupedCard(
                    children: <Widget>[
                      _navRow(
                        icon: CupertinoIcons.info_circle_fill,
                        iconColor: CupertinoColors.systemGrey,
                        title: l10n.appVersion,
                        value: '1.0.0',
                      ),
                      _divider(),
                      _navRow(
                        icon: CupertinoIcons.question_circle_fill,
                        iconColor: CupertinoColors.activeGreen,
                        title: l10n.support,
                        showChevron: true,
                        onTap: _showSupport,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.account),
                  _groupedCard(
                    children: <Widget>[
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        onPressed: _confirmLogout,
                        child: Row(
                          children: <Widget>[
                            _iconBadge(
                              CupertinoIcons.square_arrow_right,
                              CupertinoColors.systemRed,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.logout,
                                style: const TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _profileCard(AppLocalizations l10n) {
    final String? provider = widget.user.socialProvider;
    return GestureDetector(
      onTap: _showEditProfileSoon,
      child: AppGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[
                    CupertinoTheme.of(context).primaryColor,
                    CupertinoTheme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                _initials,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.user.name.isEmpty ? l10n.profile : widget.user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  if (provider != null && provider.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      l10n.signedInWith(_prettyProvider(provider)),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            CupertinoColors.tertiaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 18,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  String _prettyProvider(String raw) {
    final String lower = raw.toLowerCase();
    if (lower.contains('google')) {
      return 'Google';
    }
    if (lower.contains('apple')) {
      return 'Apple';
    }
    return raw;
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _groupedCard({required List<Widget> children}) {
    return AppGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.only(left: 54),
      height: 0.5,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 17, color: CupertinoColors.white),
    );
  }

  Widget _costRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required TextEditingController controller,
    required String placeholder,
  }) {
    final Color secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: <Widget>[
          _iconBadge(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 108,
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onEditingComplete: () {
                FocusScope.of(context).unfocus();
                _saveCosts();
              },
              onTapOutside: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                _saveCosts();
              },
              suffix: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  AppCurrency.symbolFor(_currencyCode),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: <Widget>[
          _iconBadge(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: <Widget>[
          _iconBadge(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? value,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onPressed: onTap,
      child: Row(
        children: <Widget>[
          _iconBadge(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          if (value != null)
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          if (showChevron) ...<Widget>[
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ],
      ),
    );
  }
}
