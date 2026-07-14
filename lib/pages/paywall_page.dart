import 'package:flutter/cupertino.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tutor_app/billing/billing_service.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/theme/app_dialogs.dart';

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
  BillingStatus? _status;
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
      final BillingStatus status = await _billing.fetchStatus(widget.token);
      final Offerings? offerings = await _billing.loadOfferings();
      if (!mounted) {
        return;
      }
      setState(() {
        _status = status;
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
    switch (productId) {
      case BillingService.weeklyProductId:
        return '— / ${context.l10n.planWeekly}';
      case BillingService.yearlyProductId:
        return '— / ${context.l10n.planYearly}';
      default:
        return '— / ${context.l10n.planMonthly}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.premium),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _busy ? null : _restore,
          child: Text(l10n.restorePurchases),
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: <Widget>[
                  Text(
                    l10n.paywallTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _reasonText(l10n),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  if (_status != null && !_status!.isPremium) ...<Widget>[
                    const SizedBox(height: 16),
                    _usageCard(l10n, _status!),
                  ],
                  const SizedBox(height: 22),
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
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton.filled(
                    onPressed: _busy ? null : _purchase,
                    child: _busy
                        ? const CupertinoActivityIndicator()
                        : Text(l10n.continueToPremium),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.paywallLegal,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _usageCard(AppLocalizations l10n, BillingStatus status) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.freePlanUsage,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.usageStudents(
              status.studentsUsed,
              status.studentsLimit ?? 4,
            ),
          ),
          Text(
            l10n.usageSchedule(
              status.scheduleLessonsUsed,
              status.scheduleLessonsLimit ?? 24,
            ),
          ),
          Text(
            l10n.usageJournal(
              status.journalLessonsUsed,
              status.journalLessonsLimit ?? 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planTile({
    required String productId,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    final bool selected = _selectedProductId == productId;
    return GestureDetector(
      onTap: _busy
          ? null
          : () {
              setState(() {
                _selectedProductId = productId;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey4.resolveFrom(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: selected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey,
            ),
            const SizedBox(width: 12),
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
                        ),
                      ),
                      if (badge != null) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
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
            Text(
              _priceLabel(productId),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
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
