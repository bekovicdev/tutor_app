import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/create_payment_page.dart';
import 'package:tutor_app/payments/payment_service.dart';
import 'package:tutor_app/students/student_service.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

enum _PaymentTab { overview, monthly, receivables, prepaid, payments }

class PaymentPage extends StatefulWidget {
  const PaymentPage({required this.token, super.key});

  final String token;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final PaymentService _paymentService;
  late final StudentService _studentService;
  late final LessonService _lessonService;

  _PaymentTab _tab = _PaymentTab.overview;
  bool _isLoading = true;
  String? _errorMessage;

  PaymentsOverview? _overview;
  List<MonthlyAnalyticsPoint> _monthly = <MonthlyAnalyticsPoint>[];
  ReceivablesAnalytics? _receivables;
  PrepaidAnalytics? _prepaid;
  List<Payment> _payments = <Payment>[];
  DateTime _chartMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<_DailyChartPoint> _dailyPoints = <_DailyChartPoint>[];
  int? _selectedDay;
  bool _isLoadingDaily = false;
  String? _dailyError;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(token: widget.token);
    _studentService = StudentService(token: widget.token);
    _lessonService = LessonService(token: widget.token);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? firstError;
    void recordError(String message) {
      firstError ??= message;
    }

    PaymentsOverview? overview;
    List<MonthlyAnalyticsPoint> monthly = <MonthlyAnalyticsPoint>[];
    ReceivablesAnalytics? receivables;
    PrepaidAnalytics? prepaid;
    List<Payment> payments = <Payment>[];

    try {
      final List<Object?> results = await Future.wait<Object?>(
        <Future<Object?>>[
          _loadSafely('overview', _paymentService.overview, recordError),
          _loadSafely(
            'monthly analytics',
            () => _paymentService.monthly(months: 6),
            recordError,
          ),
          _loadSafely('receivables', _paymentService.receivables, recordError),
          _loadSafely(
            'prepaid analytics',
            _paymentService.prepaidAnalytics,
            recordError,
          ),
          _loadSafely(
            'payments',
            () => _paymentService.listPayments(perPage: 50),
            recordError,
          ),
        ],
      );
      overview = results[0] as PaymentsOverview?;
      monthly =
          (results[1] as List<MonthlyAnalyticsPoint>?) ??
          <MonthlyAnalyticsPoint>[];
      receivables = results[2] as ReceivablesAnalytics?;
      prepaid = results[3] as PrepaidAnalytics?;
      payments = (results[4] as List<Payment>?) ?? <Payment>[];
    } finally {
      if (mounted) {
        setState(() {
          _overview = overview;
          _monthly = monthly;
          _receivables = receivables;
          _prepaid = prepaid;
          _payments = payments;
          _errorMessage = firstError;
          _isLoading = false;
        });
        await _loadDailyChart(_chartMonth);
      }
    }
  }

  Future<T?> _loadSafely<T>(
    String label,
    Future<T> Function() request,
    void Function(String message) recordError,
  ) async {
    try {
      return await request();
    } on PaymentServiceException catch (error) {
      recordError(error.message);
      return null;
    } catch (error) {
      recordError(context.l10n.failedToLoad(label, error.toString()));
      return null;
    }
  }

  Future<void> _loadDailyChart(DateTime month) async {
    final DateTime start = DateTime(month.year, month.month);
    final DateTime end = DateTime(month.year, month.month + 1, 0);
    final String from = _ymd(start);
    final String to = _ymd(end);

    setState(() {
      _chartMonth = start;
      _isLoadingDaily = true;
      _dailyError = null;
      _selectedDay = null;
    });

    try {
      List<Lesson> lessons = <Lesson>[];
      List<Payment> payments = <Payment>[];
      String? error;

      try {
        lessons = await _lessonService.listLessons(
          startDate: from,
          endDate: to,
          source: LessonSource.journal,
          sortBy: 'date',
          sortDirection: 'asc',
        );
      } on LessonServiceException catch (e) {
        error ??= e.message;
      }

      try {
        payments = await _paymentService.listPayments(
          from: from,
          to: to,
          perPage: 100,
          sortBy: 'paid_at',
          sortDirection: 'asc',
        );
      } on PaymentServiceException catch (e) {
        error ??= e.message;
      }

      final List<_DailyChartPoint> days = _buildDailyPoints(
        daysInMonth: end.day,
        lessons: lessons,
        payments: payments,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _dailyPoints = days;
        _isLoadingDaily = false;
        _dailyError = error;
        final int today = DateTime.now().day;
        if (start.year == DateTime.now().year &&
            start.month == DateTime.now().month) {
          _selectedDay = today.clamp(1, end.day);
        } else {
          final int firstActive = days.indexWhere(
            (_DailyChartPoint p) => p.hasActivity,
          );
          _selectedDay = firstActive >= 0 ? days[firstActive].day : 1;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dailyPoints = _emptyDays(end.day);
        _isLoadingDaily = false;
        _dailyError = context.l10n.failedToLoadDailyChart;
      });
    }
  }

  List<_DailyChartPoint> _emptyDays(int daysInMonth) {
    return List<_DailyChartPoint>.generate(
      daysInMonth,
      (int i) => _DailyChartPoint(day: i + 1),
    );
  }

  List<_DailyChartPoint> _buildDailyPoints({
    required int daysInMonth,
    required List<Lesson> lessons,
    required List<Payment> payments,
  }) {
    final List<_DailyChartPoint> days = _emptyDays(daysInMonth);

    for (final Lesson lesson in lessons) {
      if (lesson.status == 'cancelled' || lesson.isFree == true) {
        continue;
      }
      final int? day = _dayFromDate(lesson.date);
      if (day == null || day < 1 || day > daysInMonth) {
        continue;
      }
      final num amount = num.tryParse(lesson.price ?? '') ?? 0;
      final _DailyChartPoint point = days[day - 1];
      switch (lesson.resolvedPaymentStatus) {
        case PaymentStatus.paid:
          days[day - 1] = point.copyWith(paidAmount: point.paidAmount + amount);
        case PaymentStatus.prepaid:
          days[day - 1] = point.copyWith(
            prepaidAmount: point.prepaidAmount + amount,
          );
        default:
          days[day - 1] = point.copyWith(
            unpaidAmount: point.unpaidAmount + amount,
          );
      }
    }

    for (final Payment payment in payments) {
      final String? paidAt = payment.paidAt;
      if (paidAt == null || paidAt.isEmpty) {
        continue;
      }
      final int? day = _dayFromDate(paidAt);
      if (day == null || day < 1 || day > daysInMonth) {
        continue;
      }
      final _DailyChartPoint point = days[day - 1];
      if (payment.kind == PaymentKind.refund) {
        days[day - 1] = point.copyWith(
          refunded: point.refunded + payment.amount,
        );
      } else {
        days[day - 1] = point.copyWith(
          collected: point.collected + payment.amount,
        );
      }
    }

    return days;
  }

  int? _dayFromDate(String value) {
    if (value.length < 10) {
      return null;
    }
    return int.tryParse(value.substring(8, 10));
  }

  String _ymd(DateTime date) {
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String get _chartMonthKey {
    final String m = _chartMonth.month.toString().padLeft(2, '0');
    return '${_chartMonth.year}-$m';
  }

  MonthlyAnalyticsPoint? get _selectedMonthSummary {
    for (final MonthlyAnalyticsPoint point in _monthly) {
      if (point.month.startsWith(_chartMonthKey)) {
        return point;
      }
    }
    return null;
  }

  Future<void> _shiftChartMonth(int delta) async {
    if (_isLoadingDaily) {
      return;
    }
    final DateTime next = DateTime(_chartMonth.year, _chartMonth.month + delta);
    await _loadDailyChart(next);
  }

  Future<void> _openCreatePayment() async {
    final bool? created = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) => CreatePaymentPage(
          paymentService: _paymentService,
          studentService: _studentService,
          lessonService: _lessonService,
        ),
      ),
    );
    if (created == true) {
      await _load();
    }
  }

  Future<void> _deletePayment(Payment payment) async {
    final bool? confirmed = await showAppAlert<bool>(
      context: context,
      title: context.l10n.deletePayment,
      message: context.l10n.deletePaymentConfirm(_formatNum(payment.amount)),
      actions: <AppAlertAction>[
        AppAlertAction(
          label: context.l10n.cancel,
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: context.l10n.delete,
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(true),
        ),
      ],
    );
    if (confirmed != true) {
      return;
    }

    try {
      await _paymentService.deletePayment(payment.id);
      await _load();
    } on PaymentServiceException catch (error) {
      await _showMessage(error.message);
    }
  }

  Future<void> _markLessonPaid(ReceivableLesson lesson) async {
    try {
      await _paymentService.markLessonPayment(
        lessonId: lesson.id,
        request: LessonPaymentRequest(
          paymentStatus: PaymentStatus.paid,
          amount: lesson.amount,
          method: PaymentMethod.cash,
          recordPayment: true,
        ),
      );
      await _load();
    } on PaymentServiceException catch (error) {
      await _showMessage(error.message);
    }
  }

  Future<void> _showMessage(String message) {
    return showAppAlert<void>(
      context: context,
      title: context.l10n.payment,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(context.l10n.payment),
        border: appNavigationBarBorderOf(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _isLoading ? null : _openCreatePayment,
              child: const Icon(CupertinoIcons.add),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _isLoading ? null : _load,
              child: const Icon(CupertinoIcons.refresh),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _buildTabBar(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final AppLocalizations l10n = context.l10n;
    final List<(_PaymentTab, String)> tabs = <(_PaymentTab, String)>[
      (_PaymentTab.overview, l10n.overview),
      (_PaymentTab.monthly, l10n.monthly),
      (_PaymentTab.receivables, l10n.receivables),
      (_PaymentTab.prepaid, l10n.prepaid),
      (_PaymentTab.payments, l10n.payments),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (BuildContext context, int index) {
            final (_PaymentTab tab, String label) = tabs[index];
            final bool selected = _tab == tab;
            return CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              color: selected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                setState(() {
                  _tab = tab;
                });
              },
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? CupertinoColors.white
                      : CupertinoColors.label.resolveFrom(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case _PaymentTab.overview:
        return _buildOverviewTab();
      case _PaymentTab.monthly:
        return _buildMonthlyTab();
      case _PaymentTab.receivables:
        return _buildReceivablesTab();
      case _PaymentTab.prepaid:
        return _buildPrepaidTab();
      case _PaymentTab.payments:
        return _buildPaymentsTab();
    }
  }

  Widget _buildOverviewTab() {
    final AppLocalizations l10n = context.l10n;
    final PaymentsOverview? overview = _overview;
    if (overview == null) {
      return Center(child: Text(l10n.noOverviewData));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _metricCard(
                label: l10n.receivables,
                value: _money(overview.receivablesAmount, overview.currency),
                subtitle: l10n.lessonsCount(overview.receivablesLessonCount),
                color: CupertinoColors.systemOrange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: l10n.settled,
                value: _money(overview.settledAmount, overview.currency),
                subtitle:
                    '${overview.collectionRatePercent.toStringAsFixed(0)}% rate',
                color: CupertinoColors.activeGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _metricCard(
                label: l10n.net,
                value: _money(overview.cashNet, overview.currency),
                subtitle: l10n.cashLine(
                  _formatNum(overview.cashCollected),
                  _formatNum(overview.cashRefunded),
                ),
                color: CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: l10n.prepaid,
                value: _money(overview.prepaidAmount, overview.currency),
                subtitle: l10n.lessonsCount(overview.prepaidLessonCount),
                color: CupertinoColors.systemPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.lessonSettlement,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Billable: ${overview.billableCount} · Free: ${overview.freeCount}',
                style: const TextStyle(color: CupertinoColors.systemGrey),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _statusChip(l10n.unpaid, overview.unpaid),
                  _statusChip(l10n.paid, overview.paid),
                  _statusChip(l10n.prepaid, overview.prepaid),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.earned,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _rowMetric(l10n.paid, overview.paidAmount, overview.currency),
              _rowMetric(
                l10n.prepaid,
                overview.prepaidEarnedAmount,
                overview.currency,
              ),
              _rowMetric(
                l10n.settled,
                overview.settledAmount,
                overview.currency,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTab() {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final bool canGoNext =
        _chartMonth.year < now.year ||
        (_chartMonth.year == now.year && _chartMonth.month < now.month);
    final MonthlyAnalyticsPoint? summary = _selectedMonthSummary;
    _DailyChartPoint? selectedDayPoint;
    if (_selectedDay != null &&
        _selectedDay! >= 1 &&
        _selectedDay! <= _dailyPoints.length) {
      selectedDayPoint = _dailyPoints[_selectedDay! - 1];
    }

    num maxCollected = 0;
    num monthCollected = 0;
    for (final _DailyChartPoint point in _dailyPoints) {
      monthCollected += point.collected;
      if (point.collected > maxCollected) {
        maxCollected = point.collected;
      }
    }
    if (maxCollected <= 0) {
      maxCollected = 1;
    }

    final DateTime monthStart = _chartMonth;
    final DateTime monthEnd = DateTime(
      _chartMonth.year,
      _chartMonth.month + 1,
      0,
    );
    final String rangeLabel =
        '${_shortMonthDay(monthStart)} – ${_shortMonthDay(monthEnd)}';
    final String monthLabel = _monthTitle(_chartMonthKey);
    final Color chartColor = CupertinoTheme.of(context).primaryColor;
    final Brightness brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    final bool isDark = brightness == Brightness.dark;
    final Color chartBg = isDark
        ? const Color(0xFF111214)
        : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final Color chartBorder = isDark
        ? const Color(0xFF2A2C31)
        : CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.45);
    final Color primaryText = isDark
        ? const Color(0xFFE8E9ED)
        : CupertinoColors.label.resolveFrom(context);
    final Color secondaryText = isDark
        ? const Color(0xFF8B8F98)
        : CupertinoColors.secondaryLabel.resolveFrom(context);
    final Color mutedIcon = isDark
        ? const Color(0xFFB0B3BA)
        : CupertinoColors.secondaryLabel.resolveFrom(context);
    final Color disabledIcon = isDark
        ? const Color(0xFF555861)
        : CupertinoColors.tertiaryLabel.resolveFrom(context);
    final Color gridColor =
        isDark ? const Color(0xFF3A3D44) : const Color(0xFFD1D1D6);
    final Color pointHalo = isDark ? const Color(0xFF111214) : chartBg;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: chartBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: chartBorder),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minimumSize: Size.zero,
                    onPressed: _isLoadingDaily
                        ? null
                        : () => _shiftChartMonth(-1),
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      color: mutedIcon,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: primaryText,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minimumSize: Size.zero,
                    onPressed: !_isLoadingDaily && canGoNext
                        ? () => _shiftChartMonth(1)
                        : null,
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: canGoNext ? primaryText : disabledIcon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rangeLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.collectedLabel(_formatGrouped(monthCollected)),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 16),
              if (_dailyError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _dailyError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ),
              if (_isLoadingDaily)
                const SizedBox(
                  height: 220,
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else
                SizedBox(
                  height: 230,
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (TapDownDetails details) {
                              if (_dailyPoints.isEmpty) {
                                return;
                              }
                              final double chartWidth =
                                  constraints.maxWidth - 44; // y-axis gutter
                              final double x = details.localPosition.dx;
                              if (x > chartWidth || x < 0) {
                                return;
                              }
                              final int index = _dailyPoints.length == 1
                                  ? 0
                                  : ((x / chartWidth) *
                                            (_dailyPoints.length - 1))
                                        .round()
                                        .clamp(0, _dailyPoints.length - 1);
                              setState(() {
                                _selectedDay = _dailyPoints[index].day;
                              });
                            },
                            child: CustomPaint(
                              size: Size(constraints.maxWidth, 230),
                              painter: _RevenueAreaChartPainter(
                                points: _dailyPoints
                                    .map(
                                      (_DailyChartPoint p) =>
                                          p.collected.toDouble(),
                                    )
                                    .toList(),
                                maxValue: maxCollected.toDouble(),
                                selectedIndex: (_selectedDay ?? 1) - 1,
                                lineColor: chartColor,
                                gridColor: gridColor,
                                labelColor: secondaryText,
                                pointHaloColor: pointHalo,
                                xLabels: _chartXLabels(_dailyPoints.length),
                                yLabels: <String>[
                                  _compactNum(maxCollected),
                                  _compactNum(maxCollected * 2 / 3),
                                  _compactNum(maxCollected / 3),
                                  '0',
                                ],
                              ),
                            ),
                          );
                        },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (selectedDayPoint != null)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _dayMonthLabel(selectedDayPoint.day),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _rowMetricColored(
                  l10n.collected,
                  selectedDayPoint.collected,
                  'TRY',
                  chartColor,
                ),
                _rowMetric(
                  l10n.paidLessons,
                  selectedDayPoint.paidAmount,
                  'TRY',
                ),
                _rowMetric(
                  l10n.prepaidLessons,
                  selectedDayPoint.prepaidAmount,
                  'TRY',
                ),
                _rowMetric(l10n.unpaid, selectedDayPoint.unpaidAmount, 'TRY'),
                if (selectedDayPoint.refunded > 0)
                  _rowMetric(l10n.refunded, selectedDayPoint.refunded, 'TRY'),
              ],
            ),
          ),
        if (summary != null) ...<Widget>[
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.monthTotals(monthLabel),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                _rowMetric(l10n.paid, summary.paidAmount, 'TRY'),
                _rowMetric(l10n.prepaid, summary.prepaidAmount, 'TRY'),
                _rowMetric(l10n.unpaid, summary.unpaidAmount, 'TRY'),
                _rowMetric(l10n.settled, summary.settledAmount, 'TRY'),
                const SizedBox(height: 8),
                Text(
                  l10n.cashNetLine(
                    _formatNum(summary.collected),
                    _formatNum(summary.refunded),
                    _formatNum(summary.net),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<String> _chartXLabels(int days) {
    if (days <= 0) {
      return <String>[];
    }
    if (days == 1) {
      return <String>['1 ${_shortMonthName(_chartMonth.month)}'];
    }
    final List<int> ticks = <int>{
      0,
      ((days - 1) / 4).round(),
      ((days - 1) / 2).round(),
      ((days - 1) * 3 / 4).round(),
      days - 1,
    }.toList()..sort();
    return ticks
        .map(
          (int index) => '${index + 1} ${_shortMonthName(_chartMonth.month)}',
        )
        .toList();
  }

  String _shortMonthDay(DateTime date) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    return intl.DateFormat.MMMd(locale).format(date);
  }

  String _shortMonthName(int month) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    return intl.DateFormat.MMM(
      locale,
    ).format(DateTime(_chartMonth.year, month));
  }

  String _formatGrouped(num value) {
    final String raw = _formatNum(value);
    final List<String> parts = raw.split('.');
    final String intPart = parts[0];
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final int fromEnd = intPart.length - i;
      out.write(intPart[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        out.write(' ');
      }
    }
    if (parts.length > 1) {
      out.write('.${parts[1]}');
    }
    return out.toString();
  }

  Widget _rowMetricColored(
    String label,
    num amount,
    String currency,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            _money(amount, currency),
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  String _monthTitle(String month) {
    if (month.length >= 7) {
      final int? m = int.tryParse(month.substring(5, 7));
      final int? year = int.tryParse(month.substring(0, 4));
      if (m != null && m >= 1 && m <= 12) {
        final String locale = Localizations.localeOf(context).toLanguageTag();
        return intl.DateFormat.yMMMM(
          locale,
        ).format(DateTime(year ?? _chartMonth.year, m));
      }
    }
    return month;
  }

  String _dayMonthLabel(int day) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    return intl.DateFormat.MMMd(
      locale,
    ).format(DateTime(_chartMonth.year, _chartMonth.month, day));
  }

  String _compactNum(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
    }
    return _formatNum(value);
  }

  Widget _buildReceivablesTab() {
    final AppLocalizations l10n = context.l10n;
    final ReceivablesAnalytics? data = _receivables;
    if (data == null) {
      return Center(child: Text(l10n.noReceivablesData));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        _metricCard(
          label: '${l10n.total} ${l10n.receivables.toLowerCase()}',
          value: _money(data.totalAmount, 'TRY'),
          subtitle: l10n.unpaidLessonsCount(data.lessonCount),
          color: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 12),
        _sectionHeader(l10n.byStudent),
        ...data.byStudent.map(_breakdownTile),
        const SizedBox(height: 12),
        _sectionHeader(l10n.byGroup),
        if (data.byGroup.isEmpty)
          Text(
            l10n.noGroupReceivables,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          )
        else
          ...data.byGroup.map(_breakdownTile),
        const SizedBox(height: 12),
        _sectionHeader(l10n.unpaidLessons),
        ...data.lessons.map((ReceivableLesson lesson) {
          return _card(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        lesson.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${lesson.date} · '
                        '${lesson.studentName ?? lesson.groupName ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatNum(lesson.amount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 8),
                  onPressed: () => _markLessonPaid(lesson),
                  child: Text(l10n.markPaid),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPrepaidTab() {
    final AppLocalizations l10n = context.l10n;
    final PrepaidAnalytics? data = _prepaid;
    if (data == null) {
      return Center(child: Text(l10n.noPrepaidData));
    }
    final num unallocatedTotal = data.unallocatedCredits.fold<num>(
      0,
      (num sum, Payment payment) => sum + payment.amount,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        Text(
          l10n.prepaidWalletHint,
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),
        _metricCard(
          label: l10n.unallocatedCreditTotal,
          value: _formatNum(unallocatedTotal),
          subtitle: 'TRY',
          color: CupertinoColors.systemPurple,
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _metricCard(
                label: l10n.scheduled,
                value: '${data.scheduledCount}',
                subtitle: l10n.prepaidLessons,
                color: CupertinoColors.systemPurple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: l10n.completed,
                value: '${data.completedCount}',
                subtitle: l10n.prepaidLessons,
                color: CupertinoColors.activeGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sectionHeader(l10n.unallocatedCredits),
        if (data.unallocatedCredits.isEmpty)
          Text(
            l10n.noUnallocatedPrepaid,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          )
        else
          ...data.unallocatedCredits.map(
            (Payment payment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _applyCreditPayment(payment),
                child: _paymentTile(payment),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _applyCreditPayment(Payment credit) async {
    final AppLocalizations l10n = context.l10n;
    final int? studentId = credit.studentId ?? credit.student?.id;
    if (studentId == null) {
      await _showMessage(l10n.selectStudentOrLesson);
      return;
    }

    List<Lesson> unpaid = <Lesson>[];
    try {
      unpaid = await _lessonService.listLessons(
        studentId: studentId,
        source: LessonSource.journal,
        paymentStatus: PaymentStatus.unpaid,
        sortBy: 'date',
        sortDirection: 'asc',
      );
      unpaid = unpaid
          .where(
            (Lesson lesson) =>
                lesson.isFree != true &&
                lesson.status != 'cancelled' &&
                lesson.resolvedPaymentStatus == PaymentStatus.unpaid,
          )
          .toList();
    } on LessonServiceException catch (error) {
      await _showMessage(error.message);
      return;
    }

    if (unpaid.isEmpty) {
      await _showMessage(l10n.noUnpaidLessons);
      return;
    }

    final Lesson? selected = await showAppActionSheet<Lesson>(
      context: context,
      title: l10n.applyCreditToLesson,
      cancelLabel: l10n.cancel,
      actions: unpaid
          .map(
            (Lesson lesson) => AppSheetAction(
              label:
                  '${lesson.date} · ${lesson.startAt} · ${lesson.displayTitle}',
              onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(lesson),
            ),
          )
          .toList(),
    );
    if (selected == null) {
      return;
    }

    try {
      await _paymentService.markLessonPayment(
        lessonId: selected.id,
        request: LessonPaymentRequest(
          paymentStatus: PaymentStatus.prepaid,
          amount: num.tryParse(selected.price?.replaceAll(',', '.') ?? '') ??
              credit.amount,
          // Credit was already cashed in as an unallocated prepaid payment.
          recordPayment: false,
        ),
      );
      await _showMessage(l10n.creditApplied);
      await _load();
    } on PaymentServiceException catch (error) {
      await _showMessage(error.message);
    }
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              context.l10n.noPaymentsYet,
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
            CupertinoButton(
              onPressed: _openCreatePayment,
              child: Text(context.l10n.recordPayment),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final Payment payment = _payments[index];
        return Dismissible(
          key: ValueKey<int>(payment.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.delete,
              color: CupertinoColors.white,
            ),
          ),
          confirmDismiss: (_) async {
            await _deletePayment(payment);
            return false;
          },
          child: _paymentTile(payment),
        );
      },
    );
  }

  Widget _breakdownTile(ReceivablesBreakdownItem item) {
    final AppLocalizations l10n = context.l10n;
    final String subtitle = item.oldestLessonDate != null
        ? l10n.lessonsOldest(item.lessonCount, item.oldestLessonDate!)
        : l10n.lessonsCount(item.lessonCount);
    return _card(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatNum(item.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      borderRadius: AppGlassTokens.radiusSmall,
      child: child,
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return AppGlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: AppGlassTokens.radiusSmall,
      tint: color.withValues(alpha: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowMetric(String label, num amount, String currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label),
          Text(
            _money(amount, currency),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, StatusAmountBucket bucket) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.systemGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${bucket.count}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Text(
          _formatNum(bucket.amount),
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _paymentTile(Payment payment) {
    final Color accent = _kindColor(payment.kind);
    final String title = payment.student?.name.isNotEmpty == true
        ? payment.student!.name
        : (payment.group?.name.isNotEmpty == true
              ? payment.group!.name
              : _paymentKindLabel(payment.kind));

    return _card(
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_kindIcon(payment.kind), size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${_paymentKindLabel(payment.kind)}'
                  '${payment.method != null ? ' · ${_paymentMethodLabel(payment.method!)}' : ''}'
                  '${payment.paidAt != null ? ' · ${_shortDate(payment.paidAt!)}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.systemGrey2,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${payment.kind == PaymentKind.refund ? '-' : ''}${_formatNum(payment.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: payment.kind == PaymentKind.refund
                      ? CupertinoColors.systemRed
                      : CupertinoColors.label.resolveFrom(context),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => _deletePayment(payment),
                child: Text(
                  context.l10n.delete,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _kindColor(String kind) {
    switch (kind) {
      case PaymentKind.prepaid:
        return CupertinoColors.systemPurple;
      case PaymentKind.refund:
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.activeGreen;
    }
  }

  String _paymentKindLabel(String kind) {
    switch (kind) {
      case PaymentKind.prepaid:
        return context.l10n.kindPrepaid;
      case PaymentKind.refund:
        return context.l10n.kindRefund;
      default:
        return context.l10n.kindLesson;
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case PaymentMethod.transfer:
        return context.l10n.methodTransfer;
      case PaymentMethod.card:
        return context.l10n.methodCard;
      case PaymentMethod.other:
        return context.l10n.methodOther;
      default:
        return context.l10n.methodCash;
    }
  }

  IconData _kindIcon(String kind) {
    switch (kind) {
      case PaymentKind.prepaid:
        return CupertinoIcons.creditcard;
      case PaymentKind.refund:
        return CupertinoIcons.arrow_uturn_left;
      default:
        return CupertinoIcons.money_dollar;
    }
  }

  String _money(num amount, String currency) =>
      '${_formatNum(amount)} $currency';

  String _formatNum(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _shortDate(String value) =>
      value.length >= 10 ? value.substring(0, 10) : value;
}

class _RevenueAreaChartPainter extends CustomPainter {
  _RevenueAreaChartPainter({
    required this.points,
    required this.maxValue,
    required this.selectedIndex,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.pointHaloColor,
    required this.xLabels,
    required this.yLabels,
  });

  final List<double> points;
  final double maxValue;
  final int selectedIndex;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final Color pointHaloColor;
  final List<String> xLabels;
  final List<String> yLabels;

  static const double _rightGutter = 44;
  static const double _bottomGutter = 28;
  static const double _topPad = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || maxValue <= 0) {
      return;
    }

    final double chartW = size.width - _rightGutter;
    final double chartH = size.height - _bottomGutter - _topPad;
    final Rect chartRect = Rect.fromLTWH(0, _topPad, chartW, chartH);

    _drawGrid(canvas, chartRect);
    _drawYLabels(canvas, size, chartRect);
    _drawXLabels(canvas, chartRect);

    final Path linePath = Path();
    final List<Offset> coords = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final double x = points.length == 1
          ? chartRect.left + chartRect.width / 2
          : chartRect.left + (i / (points.length - 1)) * chartRect.width;
      final double y =
          chartRect.bottom -
          (points[i] / maxValue).clamp(0.0, 1.0) * chartRect.height;
      coords.add(Offset(x, y));
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final Path fillPath = Path.from(linePath)
      ..lineTo(coords.last.dx, chartRect.bottom)
      ..lineTo(coords.first.dx, chartRect.bottom)
      ..close();

    final Paint fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(chartRect.left, chartRect.top),
        Offset(chartRect.left, chartRect.bottom),
        <Color>[
          lineColor.withValues(alpha: 0.45),
          lineColor.withValues(alpha: 0.05),
          lineColor.withValues(alpha: 0.0),
        ],
        <double>[0.0, 0.55, 1.0],
      );
    canvas.drawPath(fillPath, fillPaint);

    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(linePath, linePaint);

    final int sel = selectedIndex.clamp(0, coords.length - 1);
    final Offset selected = coords[sel];

    final Paint vLinePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(selected.dx, chartRect.top),
      Offset(selected.dx, chartRect.bottom),
      vLinePaint,
    );

    canvas.drawCircle(selected, 5.5, Paint()..color = pointHaloColor);
    canvas.drawCircle(selected, 4, Paint()..color = lineColor);
  }

  void _drawGrid(Canvas canvas, Rect chartRect) {
    final Paint paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const int hLines = 3;
    for (int i = 0; i <= hLines; i++) {
      final double y = chartRect.top + (chartRect.height / hLines) * i;
      _drawDashedLine(
        canvas,
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        paint,
      );
    }

    if (points.length > 1) {
      final List<int> ticks = _xTickIndexes(points.length);
      for (final int index in ticks) {
        final double x =
            chartRect.left + (index / (points.length - 1)) * chartRect.width;
        _drawDashedLine(
          canvas,
          Offset(x, chartRect.top),
          Offset(x, chartRect.bottom),
          paint,
        );
      }
    }
  }

  void _drawYLabels(Canvas canvas, Size size, Rect chartRect) {
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < yLabels.length; i++) {
      final double t = yLabels.length == 1 ? 0 : i / (yLabels.length - 1);
      final double y = chartRect.top + chartRect.height * t;
      tp.text = TextSpan(
        text: yLabels[i],
        style: TextStyle(
          fontSize: 10,
          color: labelColor,
          fontWeight: FontWeight.w500,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(size.width - tp.width, y - tp.height / 2));
    }
  }

  void _drawXLabels(Canvas canvas, Rect chartRect) {
    if (xLabels.isEmpty || points.length < 2) {
      return;
    }
    final List<int> ticks = _xTickIndexes(points.length);
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    final int count = math.min(ticks.length, xLabels.length);
    for (int i = 0; i < count; i++) {
      final int index = ticks[i];
      final double x =
          chartRect.left + (index / (points.length - 1)) * chartRect.width;
      tp.text = TextSpan(
        text: xLabels[i],
        style: TextStyle(
          fontSize: 10,
          color: labelColor,
          fontWeight: FontWeight.w500,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartRect.bottom + 8));
    }
  }

  List<int> _xTickIndexes(int days) {
    if (days <= 1) {
      return <int>[0];
    }
    final Set<int> ticks = <int>{
      0,
      ((days - 1) / 4).round(),
      ((days - 1) / 2).round(),
      ((days - 1) * 3 / 4).round(),
      days - 1,
    };
    return ticks.toList()..sort();
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const double dash = 3;
    const double gap = 3;
    final double dx = b.dx - a.dx;
    final double dy = b.dy - a.dy;
    final double len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) {
      return;
    }
    final double ux = dx / len;
    final double uy = dy / len;
    double drawn = 0;
    while (drawn < len) {
      final double end = math.min(drawn + dash, len);
      canvas.drawLine(
        Offset(a.dx + ux * drawn, a.dy + uy * drawn),
        Offset(a.dx + ux * end, a.dy + uy * end),
        paint,
      );
      drawn = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueAreaChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.pointHaloColor != pointHaloColor ||
        oldDelegate.xLabels != xLabels ||
        oldDelegate.yLabels != yLabels;
  }
}

class _DailyChartPoint {
  const _DailyChartPoint({
    required this.day,
    this.paidAmount = 0,
    this.prepaidAmount = 0,
    this.unpaidAmount = 0,
    this.collected = 0,
    this.refunded = 0,
  });

  final int day;
  final num paidAmount;
  final num prepaidAmount;
  final num unpaidAmount;
  final num collected;
  final num refunded;

  bool get hasActivity =>
      paidAmount > 0 ||
      prepaidAmount > 0 ||
      unpaidAmount > 0 ||
      collected > 0 ||
      refunded > 0;

  _DailyChartPoint copyWith({
    num? paidAmount,
    num? prepaidAmount,
    num? unpaidAmount,
    num? collected,
    num? refunded,
  }) {
    return _DailyChartPoint(
      day: day,
      paidAmount: paidAmount ?? this.paidAmount,
      prepaidAmount: prepaidAmount ?? this.prepaidAmount,
      unpaidAmount: unpaidAmount ?? this.unpaidAmount,
      collected: collected ?? this.collected,
      refunded: refunded ?? this.refunded,
    );
  }
}
