import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/program_page.dart';
import 'package:tutor_app/theme/ios26_theme.dart';
import 'package:tutor_app/widgets/settings_nav_button.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    required this.token,
    this.onOpenSettings,
    super.key,
  });

  final String token;
  final void Function(BuildContext context)? onOpenSettings;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final LessonService _lessonService;

  DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  Map<String, int> _lessonCountByDay = <String, int>{};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService(token: widget.token);
    _loadMonth();
  }

  String _formatDate(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _monthStart(DateTime month) =>
      DateTime(month.year, month.month, 1);

  DateTime _monthEnd(DateTime month) =>
      DateTime(month.year, month.month + 1, 0);

  Future<void> _loadMonth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final DateTime start = _monthStart(_visibleMonth);
      final DateTime end = _monthEnd(_visibleMonth);
      final List<Lesson> lessons = await _lessonService.calendar(
        startDate: _formatDate(start),
        endDate: _formatDate(end),
        source: LessonSource.schedule,
      );
      if (!mounted) {
        return;
      }
      final Map<String, int> counts = <String, int>{};
      for (final Lesson lesson in lessons) {
        if (lesson.status == 'cancelled') {
          continue;
        }
        final String raw = lesson.date.trim();
        final String key =
            raw.length >= 10 ? raw.substring(0, 10) : raw;
        counts[key] = (counts[key] ?? 0) + 1;
      }
      setState(() {
        _lessonCountByDay = counts;
      });
    } on LessonServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
    _loadMonth();
  }

  void _goToToday() {
    final DateTime today = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(today.year, today.month);
    });
    _loadMonth();
  }

  List<DateTime?> _daysInGrid() {
    final DateTime first = _monthStart(_visibleMonth);
    final int leading = first.weekday - DateTime.monday;
    final int daysInMonth = _monthEnd(_visibleMonth).day;
    final List<DateTime?> cells = <DateTime?>[];
    for (int i = 0; i < leading; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  Future<void> _openDay(DateTime day) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) => ProgramPage(
          token: widget.token,
          day: day,
        ),
      ),
    );
    if (changed == true) {
      await _loadMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateTime today = DateTime.now();
    final List<DateTime?> cells = _daysInGrid();
    final String monthTitle =
        intl.DateFormat.yMMMM(locale).format(_visibleMonth);
    final List<String> weekdayLabels = List<String>.generate(7, (int i) {
      final DateTime day =
          DateTime(2024, 1, 1).add(Duration(days: i));
      return intl.DateFormat.E(locale).format(day);
    });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.calendar),
        border: appNavigationBarBorderOf(context),
        leading: widget.onOpenSettings == null
            ? null
            : SettingsNavButton(
                onPressed: () => widget.onOpenSettings!(context),
              ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _goToToday,
          child: Text(l10n.today),
        ),
      ),
      child: SafeArea(
        child: _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(_errorMessage!),
                    CupertinoButton(
                      onPressed: _loadMonth,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              )
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Row(
                      children: <Widget>[
                        CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: () => _shiftMonth(-1),
                          child: const Icon(
                            CupertinoIcons.chevron_left,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            monthTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: () => _shiftMonth(1),
                          child: const Icon(
                            CupertinoIcons.chevron_right,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: weekdayLabels
                          .map(
                            (String label) => Expanded(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (_isLoading)
                    const Expanded(
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: cells.length,
                        itemBuilder: (BuildContext context, int index) {
                          final DateTime? day = cells[index];
                          if (day == null) {
                            return const SizedBox.shrink();
                          }
                          final bool isToday = _isSameDay(day, today);
                          final String key = _formatDate(day);
                          final int lessonCount = _lessonCountByDay[key] ?? 0;

                          return GestureDetector(
                            onTap: () => _openDay(day),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppBrand.primary.withValues(alpha: 0.12)
                                    : CupertinoColors.systemBackground
                                        .resolveFrom(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isToday
                                      ? AppBrand.primary
                                      : CupertinoColors.separator
                                          .resolveFrom(context)
                                          .withValues(alpha: 0.6),
                                  width: isToday ? 1.4 : 0.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isToday
                                          ? AppBrand.primary
                                          : CupertinoColors.label
                                              .resolveFrom(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (lessonCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppBrand.primary
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$lessonCount',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppBrand.primary
                                              .resolveFrom(context),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 16),
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
    );
  }
}
