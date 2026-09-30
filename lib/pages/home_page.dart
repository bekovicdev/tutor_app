import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_events.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/lesson_detail_page.dart';
import 'package:tutor_app/theme/ios26_theme.dart';
import 'package:tutor_app/widgets/settings_nav_button.dart';

/// Dashboard tab shown in the middle of the bottom nav bar. Lets the tutor
/// swipe between yesterday / today / tomorrow and see that day's lessons
/// and quick financial stats at a glance.
class HomePage extends StatefulWidget {
  const HomePage({
    required this.token,
    this.onOpenSettings,
    super.key,
  });

  final String token;
  final void Function(BuildContext context)? onOpenSettings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _yesterdayIndex = 0;
  static const int _todayIndex = 1;
  static const int _tomorrowIndex = 2;

  late final LessonService _lessonService;
  late final PageController _pageController;
  late final List<DateTime> _days;

  final Map<int, List<Lesson>> _lessonsByIndex = <int, List<Lesson>>{};
  final Map<int, String?> _errorByIndex = <int, String?>{};
  final Map<int, bool> _loadingByIndex = <int, bool>{};
  int _currentIndex = _todayIndex;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService(token: widget.token);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    _days = <DateTime>[
      today.subtract(const Duration(days: 1)),
      today,
      today.add(const Duration(days: 1)),
    ];
    _pageController = PageController(initialPage: _todayIndex);
    LessonEvents.listenable.addListener(_onLessonsChangedElsewhere);
    for (int i = 0; i < _days.length; i++) {
      unawaited(_loadDay(i));
    }
  }

  void _onLessonsChangedElsewhere() {
    if (!mounted) {
      return;
    }
    unawaited(_refreshAll());
  }

  @override
  void dispose() {
    LessonEvents.listenable.removeListener(_onLessonsChangedElsewhere);
    _pageController.dispose();
    super.dispose();
  }

  String _formatDateKey(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadDay(int index) async {
    setState(() {
      _loadingByIndex[index] = true;
      _errorByIndex[index] = null;
    });
    try {
      final String key = _formatDateKey(_days[index]);
      final List<Lesson> lessons = await _lessonService.calendar(
        startDate: key,
        endDate: key,
      );
      lessons.sort(
        (Lesson a, Lesson b) => a.startMinutes.compareTo(b.startMinutes),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lessonsByIndex[index] = lessons;
      });
    } on LessonServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorByIndex[index] = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingByIndex[index] = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    for (int i = 0; i < _days.length; i++) {
      await _loadDay(i);
    }
  }

  String _dayLabel(AppLocalizations l10n, int index) {
    switch (index) {
      case _yesterdayIndex:
        return l10n.yesterday;
      case _tomorrowIndex:
        return l10n.tomorrow;
      default:
        return l10n.today;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.tabHome),
        border: appNavigationBarBorderOf(context),
        leading: widget.onOpenSettings == null
            ? null
            : SettingsNavButton(
                onPressed: () => widget.onOpenSettings!(context),
              ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _refreshAll,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _buildDayPips(l10n),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _days.length,
                onPageChanged: (int index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (BuildContext context, int index) =>
                    _buildDayPage(context, l10n, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPips(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(_days.length, (int index) {
          final bool active = index == _currentIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: active
                    ? AppBrand.primary.resolveFrom(context)
                    : CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _dayLabel(l10n, index),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? CupertinoColors.white
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayPage(BuildContext context, AppLocalizations l10n, int index) {
    final bool loading = _loadingByIndex[index] ?? true;
    final String? error = _errorByIndex[index];
    final List<Lesson>? lessons = _lessonsByIndex[index];

    return CustomScrollView(
      slivers: <Widget>[
        CupertinoSliverRefreshControl(onRefresh: () => _loadDay(index)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _buildDateHeader(index),
          ),
        ),
        if (loading && lessons == null)
          const SliverFillRemaining(
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (error != null && lessons == null)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      onPressed: () => _loadDay(index),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...<Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _buildStatsRow(context, l10n, lessons ?? <Lesson>[]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: Text(
                l10n.lessons.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
          if ((lessons ?? <Lesson>[]).isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 28,
                ),
                child: Center(
                  child: Text(
                    l10n.noLessonsForDay,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildLessonRow(context, lessons![i]),
                  ),
                  childCount: lessons?.length ?? 0,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildDateHeader(int index) {
    final DateTime day = _days[index];
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String formatted = intl.DateFormat.yMMMEd(locale).format(day);
    return Text(
      formatted,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    AppLocalizations l10n,
    List<Lesson> lessons,
  ) {
    final List<Lesson> billable = lessons
        .where((Lesson lesson) => lesson.status != 'cancelled' && lesson.isFree != true)
        .toList();
    num income = 0;
    num unpaidAmount = 0;
    for (final Lesson lesson in billable) {
      final num price =
          num.tryParse((lesson.price ?? '0').replaceAll(',', '.')) ?? 0;
      income += price;
      if (lesson.resolvedPaymentStatus == 'unpaid') {
        unpaidAmount += price;
      }
    }
    final int activeCount =
        lessons.where((Lesson lesson) => lesson.status != 'cancelled').length;
    final String currency = context.activeCurrencyCode;

    return Row(
      children: <Widget>[
        Expanded(
          child: _statTile(
            context,
            label: l10n.totalIncome,
            value: l10n.formatMoney(income, currency),
            color: AppBrand.primary.resolveFrom(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            context,
            label: l10n.lessons,
            value: '$activeCount',
            color: CupertinoColors.activeBlue.resolveFrom(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            context,
            label: l10n.unpaidAmount,
            value: l10n.formatMoney(unpaidAmount, currency),
            color: CupertinoColors.systemOrange.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _statTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonRow(BuildContext context, Lesson lesson) {
    final AppLocalizations l10n = context.l10n;
    final bool cancelled = lesson.status == 'cancelled';
    final bool completed = lesson.status == 'completed';
    final Color accent = _parseHexColor(lesson.accentColor);
    final String timeRange =
        '${_formatClock(lesson.startMinutes)}–${_formatClock(lesson.endMinutes)}';
    final num? price = lesson.isFree == true
        ? null
        : num.tryParse((lesson.price ?? '').replaceAll(',', '.'));

    return GestureDetector(
      onTap: () => _openLesson(lesson),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground
              .resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: CupertinoColors.separator
                .resolveFrom(context)
                .withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: cancelled
                    ? CupertinoColors.systemGrey3.resolveFrom(context)
                    : accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    lesson.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration:
                          cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeRange,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (price != null) ...<Widget>[
              Text(
                l10n.formatMoney(price, context.activeCurrencyCode),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
            ],
            if (completed || cancelled)
              Icon(
                completed
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.xmark_circle_fill,
                size: 18,
                color: completed
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLesson(Lesson lesson) async {
    final bool? changed = await openLessonDetailPage(
      context,
      token: widget.token,
      lessonId: lesson.id,
      lesson: lesson,
    );
    if (changed == true) {
      await _refreshAll();
    }
  }

  String _formatClock(int minutes) {
    final int h = (minutes ~/ 60) % 24;
    final int m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}';
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return AppBrand.primary;
    }
    final String value = hex.replaceAll('#', '').trim();
    if (value.length != 6) {
      return AppBrand.primary;
    }
    final int? rgb = int.tryParse(value, radix: 16);
    if (rgb == null) {
      return AppBrand.primary;
    }
    return Color.fromARGB(
      255,
      (rgb >> 16) & 0xFF,
      (rgb >> 8) & 0xFF,
      rgb & 0xFF,
    );
  }
}
