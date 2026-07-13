import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/create_lesson_page.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({required this.token, super.key});

  final String token;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const double _hourHeight = 48;
  static const double _hourLabelWidth = 40;
  static const int _hoursInDay = 24;

  late final LessonService _lessonService;

  DateTime _weekStart = _mondayOf(DateTime.now());
  List<Lesson> _weekLessons = <Lesson>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService(token: widget.token);
    _loadWeek();
  }

  static DateTime _mondayOf(DateTime date) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String _formatDate(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> get _weekDays =>
      List<DateTime>.generate(7, (int i) => _weekStart.add(Duration(days: i)));

  List<Lesson> _lessonsForDay(DateTime day) {
    final String key = _formatDate(day);
    return _weekLessons
        .where((Lesson lesson) => lesson.date.startsWith(key))
        .toList();
  }

  Future<void> _loadWeek() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final DateTime weekEnd = _weekStart.add(const Duration(days: 6));
      final List<Lesson> lessons = await _lessonService.calendar(
        startDate: _formatDate(_weekStart),
        endDate: _formatDate(weekEnd),
        source: LessonSource.schedule,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _weekLessons = lessons;
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

  void _shiftWeek(int deltaWeeks) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks));
    });
    _loadWeek();
  }

  void _goToToday() {
    setState(() {
      _weekStart = _mondayOf(DateTime.now());
    });
    _loadWeek();
  }

  Future<void> _openCreateLesson() async {
    final bool? created = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) => CreateLessonPage(
          token: widget.token,
          source: LessonSource.schedule,
          initialDate: DateTime.now(),
        ),
      ),
    );
    if (created == true) {
      await _loadWeek();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.schedule),
        border: appNavigationBarBorder,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openCreateLesson,
              child: const Icon(CupertinoIcons.add),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _goToToday,
              child: Text(l10n.today),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _buildWeekNav(),
            _buildDayHeader(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNav() {
    final DateTime weekEnd = _weekStart.add(const Duration(days: 6));
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _shiftWeek(-1),
            child: const Icon(CupertinoIcons.chevron_left, size: 20),
          ),
          Expanded(
            child: Text(
              '${_shortMonthDay(_weekStart)} – ${_shortMonthDay(weekEnd)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _shiftWeek(1),
            child: const Icon(CupertinoIcons.chevron_right, size: 20),
          ),
        ],
      ),
    );
  }

  String _shortMonthDay(DateTime date) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    return intl.DateFormat.MMMd(locale).format(date);
  }

  Widget _buildDayHeader() {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final intl.DateFormat weekdayFormat = intl.DateFormat.E(locale);
    final DateTime today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 8, 6),
      child: Row(
        children: <Widget>[
          const SizedBox(width: _hourLabelWidth),
          ...List<Widget>.generate(7, (int index) {
            final DateTime day = _weekDays[index];
            final bool isToday = _isSameDay(day, today);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isToday
                      ? CupertinoColors.activeBlue.withOpacity(0.12)
                      : CupertinoColors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      weekdayFormat.format(day),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_errorMessage!),
            CupertinoButton(
              onPressed: _loadWeek,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    final double gridHeight = _hoursInDay * _hourHeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16, right: 8),
      child: SizedBox(
        height: gridHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: _hourLabelWidth,
              child: Column(
                children: List<Widget>.generate(_hoursInDay, (int hour) {
                  return SizedBox(
                    height: _hourHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        _formatHourLabel(hour),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            ...List<Widget>.generate(7, (int dayIndex) {
              final DateTime day = _weekDays[dayIndex];
              return Expanded(
                child: _DayColumn(
                  day: day,
                  lessons: _lessonsForDay(day),
                  hourHeight: _hourHeight,
                  hoursInDay: _hoursInDay,
                  onLessonTap: _showLessonDetails,
                  parseColor: _parseHexColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatHourLabel(int hour) {
    return hour.toString().padLeft(2, '0');
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return CupertinoColors.activeBlue;
    }
    final String value = hex.replaceAll('#', '').trim();
    if (value.length != 6) {
      return CupertinoColors.activeBlue;
    }
    final int? rgb = int.tryParse(value, radix: 16);
    if (rgb == null) {
      return CupertinoColors.activeBlue;
    }
    return Color.fromARGB(
      255,
      (rgb >> 16) & 0xFF,
      (rgb >> 8) & 0xFF,
      rgb & 0xFF,
    );
  }

  Future<void> _showLessonDetails(Lesson lesson) async {
    await showAppActionSheet<void>(
      context: context,
      title: lesson.displayTitle,
      message:
          '${lesson.date} · ${lesson.startAt} · ${context.l10n.minutes(lesson.durationMinutes)}\n'
          '${lesson.displaySubtitle}\n'
          '${context.l10n.status}: ${lesson.status}',
      cancelLabel: context.l10n.close,
      actions: const <AppSheetAction>[],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.lessons,
    required this.hourHeight,
    required this.hoursInDay,
    required this.onLessonTap,
    required this.parseColor,
  });

  final DateTime day;
  final List<Lesson> lessons;
  final double hourHeight;
  final int hoursInDay;
  final ValueChanged<Lesson> onLessonTap;
  final Color Function(String? hex) parseColor;

  @override
  Widget build(BuildContext context) {
    final double height = hoursInDay * hourHeight;
    final Color line = CupertinoColors.separator
        .resolveFrom(context)
        .withOpacity(0.55);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: line, width: 0.5)),
      ),
      child: SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            Column(
              children: List<Widget>.generate(hoursInDay, (int hour) {
                return Container(
                  height: hourHeight,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: line, width: 0.5)),
                  ),
                );
              }),
            ),
            ...lessons.map((Lesson lesson) {
              final int start = lesson.startMinutes.clamp(0, 24 * 60);
              final int end = lesson.endMinutes.clamp(0, 24 * 60);
              if (end <= start) {
                return const SizedBox.shrink();
              }
              final double top = start / 60 * hourHeight;
              final double blockHeight = ((end - start) / 60 * hourHeight)
                  .clamp(16.0, height);

              final Color accent = parseColor(lesson.accentColor);
              final bool cancelled = lesson.status == 'cancelled';

              return Positioned(
                top: top,
                left: 1,
                right: 1,
                height: blockHeight,
                child: GestureDetector(
                  onTap: () => onLessonTap(lesson),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cancelled
                          ? CupertinoColors.systemGrey5
                          : accent.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: cancelled ? CupertinoColors.systemGrey3 : accent,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      lesson.displayTitle,
                      maxLines: blockHeight < 28 ? 1 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: cancelled
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.label.resolveFrom(context),
                        decoration: cancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
