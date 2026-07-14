import 'package:flutter/cupertino.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tutor_app/billing/billing_service.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({
    required this.token,
    this.reasonCode,
    super.key,
  });

  final String token;
  final String? reasonCode;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  final BillingService _billing = BillingService();
  Offerings? _offerings;
  bool _loading = true;
  bool _busy = false;
  String? _selectedProductId = BillingService.monthlyProductId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final Offerings? offerings = await _billing.loadOfferings();
      if (!mounted) {
        return;
      }
      setState(() {
        _offerings = offerings;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      await _showError(error.toString());
    }
  }

  String _reasonText(AppLocalizations l10n) {
    switch (widget.reasonCode) {
      case 'quota_students':
        return l10n.paywallReasonStudents;
      case 'quota_schedule_lessons':
        return l10n.paywallReasonSchedule;
      case 'quota_journal_lessons':
        return l10n.paywallReasonJournal;
      default:
        return l10n.paywallSubtitle;
    }
  }

  Future<void> _purchase() async {
    final String? productId = _selectedProductId;
    if (productId == null) {
      return;
    }
    final Package? package =
        _billing.packageForProduct(_offerings, productId);
    if (package == null) {
      await _showError(context.l10n.paywallProductsUnavailable);
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      final BillingStatus status = await _billing.purchasePackage(
        token: widget.token,
        package: package,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(status);
    } catch (error) {
      if (!mounted) {
        return;
      }
      await _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
    });
    try {
      final BillingStatus status = await _billing.restore(widget.token);
      if (!mounted) {
        return;
      }
      if (status.isPremium) {
        Navigator.of(context).pop(status);
      } else {
        await _showError(context.l10n.paywallNoPurchases);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      await _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _showError(String message) {
    return showAppAlert<void>(
      context: context,
      title: context.l10n.premium,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }

  String _priceLabel(String productId) {
    final Package? package =
        _billing.packageForProduct(_offerings, productId);
    if (package != null) {
      return package.storeProduct.priceString;
    }
    return '—';
  }

  String _periodLabel(AppLocalizations l10n, String productId) {
    switch (productId) {
      case BillingService.weeklyProductId:
        return l10n.planWeekly;
      case BillingService.yearlyProductId:
        return l10n.planYearly;
      default:
        return l10n.planMonthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Brightness brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    final bool isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: AppSurfaces.scaffold(brightness),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    AppBrand.primary.withValues(alpha: isDark ? 0.22 : 0.16),
                    AppSurfaces.scaffold(brightness).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : Column(
                    children: <Widget>[
                      _topBar(l10n),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          children: <Widget>[
                            _hero(l10n),
                            const SizedBox(height: 28),
                            _features(l10n),
                            const SizedBox(height: 28),
                            Text(
                              l10n.choosePlan,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: AppSurfaces.secondaryLabel(brightness),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _planTile(
                              productId: BillingService.weeklyProductId,
                              title: l10n.planWeekly,
                              subtitle: l10n.planWeeklyHint,
                            ),
                            const SizedBox(height: 10),
                            _planTile(
                              productId: BillingService.monthlyProductId,
                              title: l10n.planMonthly,
                              subtitle: l10n.planMonthlyHint,
                              badge: l10n.popular,
                            ),
                            const SizedBox(height: 10),
                            _planTile(
                              productId: BillingService.yearlyProductId,
                              title: l10n.planYearly,
                              subtitle: l10n.planYearlyHint,
                              badge: l10n.bestValue,
                              emphasize: true,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      _bottomCta(l10n, brightness),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(
              l10n.close,
              style: const TextStyle(fontSize: 17),
            ),
          ),
          const Spacer(),
          Text(
            l10n.premium,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 72),
        ],
      ),
    );
  }

  Widget _hero(AppLocalizations l10n) {
    return Column(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: AppBrand.heroGradient,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppBrand.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.star_fill,
            color: CupertinoColors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.paywallTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _reasonText(l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _features(AppLocalizations l10n) {
    final List<({IconData icon, String label})> items =
        <({IconData icon, String label})>[
      (
        icon: CupertinoIcons.person_2_fill,
        label: l10n.paywallFeatureStudents,
      ),
      (
        icon: CupertinoIcons.calendar,
        label: l10n.paywallFeatureSchedule,
      ),
      (
        icon: CupertinoIcons.book_fill,
        label: l10n.paywallFeatureJournal,
      ),
    ];

    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                height: 0.5,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppBrand.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      items[i].icon,
                      size: 17,
                      color: AppBrand.primaryDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[i].label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 22,
                    color: CupertinoColors.activeGreen.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _planTile({
    required String productId,
    required String title,
    required String subtitle,
    String? badge,
    bool emphasize = false,
  }) {
    final bool selected = _selectedProductId == productId;
    final Brightness brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    final bool isDark = brightness == Brightness.dark;

    final Color borderColor = selected
        ? AppBrand.primary
        : (isDark ? const Color(0x22FFFFFF) : const Color(0x14000000));
    final Color fill = selected
        ? AppBrand.primary.withValues(alpha: isDark ? 0.16 : 0.08)
        : AppSurfaces.card(brightness);

    return GestureDetector(
      onTap: _busy
          ? null
          : () {
              setState(() {
                _selectedProductId = productId;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppBrand.primary : const Color(0x00000000),
                border: Border.all(
                  color: selected
                      ? AppBrand.primary
                      : CupertinoColors.systemGrey3.resolveFrom(context),
                  width: selected ? 0 : 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      CupertinoIcons.checkmark,
                      size: 14,
                      color: CupertinoColors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (badge != null) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: emphasize
                                ? AppBrand.primary
                                : AppBrand.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                              color: emphasize
                                  ? CupertinoColors.white
                                  : AppBrand.primaryDeep,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  _priceLabel(productId),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _periodLabel(context.l10n, productId).toLowerCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomCta(AppLocalizations l10n, Brightness brightness) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: BoxDecoration(
        color: AppSurfaces.scaffold(brightness),
        border: Border(
          top: BorderSide(
            color: AppSurfaces.separator(brightness),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: BorderRadius.circular(14),
              color: AppBrand.primary,
              disabledColor: AppBrand.primary.withValues(alpha: 0.45),
              onPressed: _busy ? null : _purchase,
              child: _busy
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : Text(
                      l10n.continueToPremium,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 6),
            onPressed: _busy ? null : _restore,
            child: Text(
              l10n.restorePurchases,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          Text(
            l10n.paywallLegal,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience opener used by quota gates.
Future<BillingStatus?> openPaywall(
  BuildContext context, {
  required String token,
  String? reasonCode,
}) {
  return Navigator.of(context).push<BillingStatus>(
    CupertinoPageRoute<BillingStatus>(
      builder: (_) => PaywallPage(token: token, reasonCode: reasonCode),
    ),
  );
}
