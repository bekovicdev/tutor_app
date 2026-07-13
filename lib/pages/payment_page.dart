import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/create_payment_page.dart';
import 'package:tutor_app/payments/payment_service.dart';
import 'package:tutor_app/students/student_service.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

enum _PaymentTab { overview, monthly, receivables, prepaid, payments }

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    required this.token,
    super.key,
  });

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
      final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
        _loadSafely('overview', _paymentService.overview, recordError),
        _loadSafely('monthly analytics', () => _paymentService.monthly(months: 6), recordError),
        _loadSafely('receivables', _paymentService.receivables, recordError),
        _loadSafely('prepaid analytics', _paymentService.prepaidAnalytics, recordError),
        _loadSafely('payments', () => _paymentService.listPayments(perPage: 50), recordError),
      ]);
      overview = results[0] as PaymentsOverview?;
      monthly = (results[1] as List<MonthlyAnalyticsPoint>?) ??
          <MonthlyAnalyticsPoint>[];
      receivables = results[2] as ReceivablesAnalytics?;
      prepaid = results[3] as PrepaidAnalytics?;
      payments =
          (results[4] as List<Payment>?) ?? <Payment>[];
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
    } catch (_) {
      recordError('Failed to load $label.');
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
        _dailyError = 'Failed to load daily chart.';
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
          days[day - 1] =
              point.copyWith(prepaidAmount: point.prepaidAmount + amount);
        default:
          days[day - 1] =
              point.copyWith(unpaidAmount: point.unpaidAmount + amount);
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
        days[day - 1] =
            point.copyWith(refunded: point.refunded + payment.amount);
      } else {
        days[day - 1] =
            point.copyWith(collected: point.collected + payment.amount);
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
    bool confirmed = false;
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Payment'),
          content: Text(
            'Remove ${_formatNum(payment.amount)} payment? '
            'Linked lesson may return to unpaid.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                confirmed = true;
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!confirmed) {
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
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Payment'),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Payment'),
        border: appNavigationBarBorder,
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
    const List<(_PaymentTab, String)> tabs = <(_PaymentTab, String)>[
      (_PaymentTab.overview, 'Overview'),
      (_PaymentTab.monthly, 'Monthly'),
      (_PaymentTab.receivables, 'Receivables'),
      (_PaymentTab.prepaid, 'Prepaid'),
      (_PaymentTab.payments, 'Payments'),
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
    final PaymentsOverview? overview = _overview;
    if (overview == null) {
      return const Center(child: Text('No overview data.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _metricCard(
                label: 'Receivables',
                value: _money(overview.receivablesAmount, overview.currency),
                subtitle: '${overview.receivablesLessonCount} lessons',
                color: CupertinoColors.systemOrange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: 'Settled',
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
                label: 'Cash net',
                value: _money(overview.cashNet, overview.currency),
                subtitle:
                    '+${_formatNum(overview.cashCollected)} / -${_formatNum(overview.cashRefunded)}',
                color: CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: 'Prepaid',
                value: _money(overview.prepaidAmount, overview.currency),
                subtitle: '${overview.prepaidLessonCount} lessons',
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
              const Text(
                'Lesson settlement',
                style: TextStyle(fontWeight: FontWeight.w700),
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
                  _statusChip('Unpaid', overview.unpaid),
                  _statusChip('Paid', overview.paid),
                  _statusChip('Prepaid', overview.prepaid),
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
              const Text(
                'Earned',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _rowMetric('Paid', overview.paidAmount, overview.currency),
              _rowMetric('Prepaid', overview.prepaidEarnedAmount, overview.currency),
              _rowMetric('Settled', overview.settledAmount, overview.currency),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTab() {
    final DateTime now = DateTime.now();
    final bool canGoNext = _chartMonth.year < now.year ||
        (_chartMonth.year == now.year && _chartMonth.month < now.month);
    final MonthlyAnalyticsPoint? summary = _selectedMonthSummary;
    _DailyChartPoint? selectedDayPoint;
    if (_selectedDay != null &&
        _selectedDay! >= 1 &&
        _selectedDay! <= _dailyPoints.length) {
      selectedDayPoint = _dailyPoints[_selectedDay! - 1];
    }

    num maxTotal = 0;
    for (final _DailyChartPoint point in _dailyPoints) {
      final num total =
          point.paidAmount + point.prepaidAmount + point.unpaidAmount;
      if (total > maxTotal) {
        maxTotal = total;
      }
    }
    if (maxTotal <= 0) {
      maxTotal = 1;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minimumSize: Size.zero,
                    onPressed:
                        _isLoadingDaily ? null : () => _shiftChartMonth(-1),
                    child: const Icon(CupertinoIcons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      _monthTitle(_chartMonthKey),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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
                      color: canGoNext
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                  height: 220,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: 40,
                        child: _chartYAxis(maxTotal),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder:
                              (BuildContext context, BoxConstraints constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: math.max(
                                  constraints.maxWidth,
                                  _dailyPoints.length * 18.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: _dailyPoints.map((_DailyChartPoint point) {
                                    final bool selected =
                                        point.day == _selectedDay;
                                    return Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          setState(() {
                                            _selectedDay = point.day;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 1,
                                          ),
                                          child: Column(
                                            children: <Widget>[
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: _dailyBar(
                                                    point: point,
                                                    maxTotal: maxTotal,
                                                    maxHeight:
                                                        constraints.maxHeight -
                                                            28,
                                                    selected: selected,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${point.day}',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: selected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: selected
                                                      ? CupertinoColors
                                                          .activeBlue
                                                      : CupertinoColors
                                                          .systemGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: const <Widget>[
                  _LegendDot(color: CupertinoColors.activeGreen, label: 'Paid'),
                  _LegendDot(
                    color: CupertinoColors.systemPurple,
                    label: 'Prepaid',
                  ),
                  _LegendDot(
                    color: CupertinoColors.systemOrange,
                    label: 'Unpaid',
                  ),
                ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${_monthTitle(_chartMonthKey)} ${selectedDayPoint.day}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Net ${_formatNum(selectedDayPoint.collected - selectedDayPoint.refunded)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _rowMetric('Paid', selectedDayPoint.paidAmount, 'TRY'),
                _rowMetric('Prepaid', selectedDayPoint.prepaidAmount, 'TRY'),
                _rowMetric('Unpaid', selectedDayPoint.unpaidAmount, 'TRY'),
                const SizedBox(height: 8),
                Text(
                  'Cash +${_formatNum(selectedDayPoint.collected)} / -${_formatNum(selectedDayPoint.refunded)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
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
                  '${_monthTitle(_chartMonthKey)} totals',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                _rowMetric('Paid', summary.paidAmount, 'TRY'),
                _rowMetric('Prepaid', summary.prepaidAmount, 'TRY'),
                _rowMetric('Unpaid', summary.unpaidAmount, 'TRY'),
                _rowMetric('Settled', summary.settledAmount, 'TRY'),
                const SizedBox(height: 8),
                Text(
                  'Cash +${_formatNum(summary.collected)} / -${_formatNum(summary.refunded)} · Net ${_formatNum(summary.net)}',
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

  Widget _chartYAxis(num maxTotal) {
    final List<String> labels = <String>[
      _compactNum(maxTotal),
      _compactNum(maxTotal * 0.5),
      '0',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: labels
            .map(
              (String label) => Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _dailyBar({
    required _DailyChartPoint point,
    required num maxTotal,
    required double maxHeight,
    required bool selected,
  }) {
    final double paidH =
        maxHeight * (point.paidAmount / maxTotal).clamp(0.0, 1.0);
    final double prepaidH =
        maxHeight * (point.prepaidAmount / maxTotal).clamp(0.0, 1.0);
    final double unpaidH =
        maxHeight * (point.unpaidAmount / maxTotal).clamp(0.0, 1.0);
    final double totalH = paidH + prepaidH + unpaidH;
    final bool hasValue =
        point.paidAmount + point.prepaidAmount + point.unpaidAmount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: selected ? 10 : 7,
      height: totalH < 2 && hasValue ? 2 : totalH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (unpaidH > 0)
            Container(height: unpaidH, color: CupertinoColors.systemOrange),
          if (prepaidH > 0)
            Container(height: prepaidH, color: CupertinoColors.systemPurple),
          if (paidH > 0)
            Container(height: paidH, color: CupertinoColors.activeGreen),
        ],
      ),
    );
  }

  String _monthTitle(String month) {
    const List<String> names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month.length >= 7) {
      final int? m = int.tryParse(month.substring(5, 7));
      final String year = month.substring(0, 4);
      if (m != null && m >= 1 && m <= 12) {
        return '${names[m - 1]} $year';
      }
    }
    return month;
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
    final ReceivablesAnalytics? data = _receivables;
    if (data == null) {
      return const Center(child: Text('No receivables data.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        _metricCard(
          label: 'Total receivables',
          value: _money(data.totalAmount, 'TRY'),
          subtitle: '${data.lessonCount} unpaid lessons',
          color: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 12),
        _sectionHeader('By student'),
        ...data.byStudent.map(_breakdownTile),
        const SizedBox(height: 12),
        _sectionHeader('By group'),
        if (data.byGroup.isEmpty)
          const Text(
            'No group receivables.',
            style: TextStyle(color: CupertinoColors.systemGrey),
          )
        else
          ...data.byGroup.map(_breakdownTile),
        const SizedBox(height: 12),
        _sectionHeader('Unpaid lessons'),
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
                  child: const Text('Mark paid'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPrepaidTab() {
    final PrepaidAnalytics? data = _prepaid;
    if (data == null) {
      return const Center(child: Text('No prepaid data.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _metricCard(
                label: 'Scheduled',
                value: '${data.scheduledCount}',
                subtitle: 'prepaid lessons',
                color: CupertinoColors.systemPurple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                label: 'Completed',
                value: '${data.completedCount}',
                subtitle: 'prepaid lessons',
                color: CupertinoColors.activeGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sectionHeader('Unallocated credits'),
        if (data.unallocatedCredits.isEmpty)
          const Text(
            'No unallocated prepaid credits.',
            style: TextStyle(color: CupertinoColors.systemGrey),
          )
        else
          ...data.unallocatedCredits.map(_paymentTile),
      ],
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'No payments yet.',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
            CupertinoButton(
              onPressed: _openCreatePayment,
              child: const Text('Record payment'),
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
            child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
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
                  '${item.lessonCount} lessons'
                  '${item.oldestLessonDate != null ? ' · oldest ${item.oldestLessonDate}' : ''}',
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
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
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
        Text(label, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${bucket.count}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        Text(_formatNum(bucket.amount), style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
      ],
    );
  }

  Widget _paymentTile(Payment payment) {
    final Color accent = _kindColor(payment.kind);
    final String title = payment.student?.name.isNotEmpty == true
        ? payment.student!.name
        : (payment.group?.name.isNotEmpty == true
            ? payment.group!.name
            : payment.kind);

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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(
                  '${payment.kind}'
                  '${payment.method != null ? ' · ${payment.method}' : ''}'
                  '${payment.paidAt != null ? ' · ${_shortDate(payment.paidAt!)}' : ''}',
                  style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey2),
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
                child: const Text(
                  'Delete',
                  style: TextStyle(fontSize: 12, color: CupertinoColors.systemRed),
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

  String _money(num amount, String currency) => '${_formatNum(amount)} $currency';

  String _formatNum(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _shortDate(String value) =>
      value.length >= 10 ? value.substring(0, 10) : value;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
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
