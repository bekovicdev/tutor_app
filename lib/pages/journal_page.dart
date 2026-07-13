import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/create_lesson_page.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({required this.token, super.key});

  final String token;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  static const double _hourHeight = 72;
  static const int _startHour = 7;
  static const int _endHour = 22;

  late final LessonService _lessonService;
  Timer? _nowTicker;
  DateTime _now = DateTime.now();

  DateTime _weekStart = _mondayOf(DateTime.now());
  DateTime _selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  List<Lesson> _weekLessons = <Lesson>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService(token: widget.token);
    _nowTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
    _loadWeek();
  }

  @override
  void dispose() {
    _nowTicker?.cancel();
    super.dispose();
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

  List<Lesson> get _selectedDayLessons {
    final String key = _formatDate(_selectedDay);
    final List<Lesson> lessons =
        _weekLessons
            .where((Lesson lesson) => lesson.date.startsWith(key))
            .toList()
          ..sort(
            (Lesson a, Lesson b) => a.startMinutes.compareTo(b.startMinutes),
          );
    return lessons;
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
        source: LessonSource.journal,
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
      _selectedDay = _selectedDay.add(Duration(days: 7 * deltaWeeks));
    });
    _loadWeek();
  }

  void _goToToday() {
    final DateTime today = DateTime.now();
    setState(() {
      _weekStart = _mondayOf(today);
      _selectedDay = DateTime(today.year, today.month, today.day);
    });
    _loadWeek();
  }

  Future<void> _openCreateLesson() async {
    final bool? created = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) => CreateLessonPage(
          token: widget.token,
          source: LessonSource.journal,
          initialDate: _selectedDay,
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
        middle: Text(l10n.journal),
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
            _buildWeekHeader(),
            _buildWeekRow(),
            Expanded(child: _buildDayTimeline()),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    final DateTime weekEnd = _weekStart.add(const Duration(days: 6));
    final String label =
        '${_shortMonthDay(_weekStart)} – ${_shortMonthDay(weekEnd)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _shiftWeek(-1),
            child: const Icon(CupertinoIcons.chevron_left),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => _shiftWeek(1),
            child: const Icon(CupertinoIcons.chevron_right),
          ),
        ],
      ),
    );
  }

  String _shortMonthDay(DateTime date) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    return intl.DateFormat.MMMd(locale).format(date);
  }

  Widget _buildWeekRow() {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final intl.DateFormat weekdayFormat = intl.DateFormat.E(locale);
    final DateTime today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        children: List<Widget>.generate(7, (int index) {
          final DateTime day = _weekDays[index];
          final bool selected = _isSameDay(day, _selectedDay);
          final bool isToday = _isSameDay(day, today);
          final int lessonCount = _weekLessons
              .where((Lesson l) => l.date.startsWith(_formatDate(day)))
              .length;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.secondarySystemGroupedBackground
                            .resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !selected
                      ? Border.all(
                          color: CupertinoColors.activeBlue,
                          width: 1.2,
                        )
                      : null,
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      weekdayFormat.format(day),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? CupertinoColors.white
                            : CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? CupertinoColors.white
                            : CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: lessonCount > 0
                            ? (selected
                                  ? CupertinoColors.white
                                  : CupertinoColors.activeBlue)
                            : CupertinoColors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayTimeline() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CupertinoColors.systemGrey),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: _loadWeek,
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final int totalHours = _endHour - _startHour;
    final double timelineHeight = totalHours * _hourHeight;
    final List<Lesson> lessons = _selectedDayLessons;
    final int gridStartMinutes = _startHour * 60;
    final Widget? nowLine = _buildNowLine(gridStartMinutes: gridStartMinutes);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 12, 24),
      child: SizedBox(
        height: timelineHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 52,
                  child: Column(
                    children: List<Widget>.generate(totalHours, (int index) {
                      final int hour = _startHour + index;
                      return SizedBox(
                        height: _hourHeight,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            _formatHour(hour),
                            style: TextStyle(
                              fontSize: 12,
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
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Column(
                        children: List<Widget>.generate(totalHours, (
                          int index,
                        ) {
                          return Container(
                            height: _hourHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: CupertinoColors.separator.resolveFrom(
                                    context,
                                  ),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      ...lessons.map((Lesson lesson) {
                        return _buildLessonBlock(
                          lesson,
                          gridStartMinutes: gridStartMinutes,
                          timelineHeight: timelineHeight,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            if (nowLine != null) nowLine,
          ],
        ),
      ),
    );
  }

  Widget? _buildNowLine({required int gridStartMinutes}) {
    if (!_isSameDay(_selectedDay, _now)) {
      return null;
    }

    final int nowMinutes = _now.hour * 60 + _now.minute;
    final int gridEndMinutes = _endHour * 60;
    if (nowMinutes < gridStartMinutes || nowMinutes > gridEndMinutes) {
      return null;
    }

    final double top = (nowMinutes - gridStartMinutes) / 60 * _hourHeight;
    const Color nowColor = Color(0xFFFF3B30);
    final String label =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

    return Positioned(
      top: top - 8,
      left: 0,
      right: 0,
      height: 16,
      child: IgnorePointer(
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: nowColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: nowColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: nowColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[nowColor, nowColor.withValues(alpha: 0.55)],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: nowColor.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonBlock(
    Lesson lesson, {
    required int gridStartMinutes,
    required double timelineHeight,
  }) {
    final int start = lesson.startMinutes - gridStartMinutes;
    final int end = lesson.endMinutes - gridStartMinutes;
    final int clippedStart = start.clamp(0, (_endHour - _startHour) * 60);
    final int clippedEnd = end.clamp(0, (_endHour - _startHour) * 60);
    if (clippedEnd <= clippedStart) {
      return const SizedBox.shrink();
    }

    final double top = clippedStart / 60 * _hourHeight;
    final double height = ((clippedEnd - clippedStart) / 60 * _hourHeight)
        .clamp(28.0, timelineHeight);

    final Color accent = _parseHexColor(lesson.accentColor);
    final Color bg = accent.withValues(alpha: 0.18);
    final bool cancelled = lesson.status == 'cancelled';
    final bool completed = lesson.status == 'completed';

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: GestureDetector(
        onTap: () => _showLessonDetails(lesson),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: height < 40 ? 4 : 8,
          ),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: cancelled ? CupertinoColors.systemGrey5 : bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cancelled ? CupertinoColors.systemGrey3 : accent,
              width: 1.2,
            ),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final List<Widget> lines = <Widget>[
                Text(
                  lesson.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: cancelled
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.label.resolveFrom(context),
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ];
              if (constraints.maxHeight >= 28) {
                lines.add(const SizedBox(height: 2));
                lines.add(
                  Text(
                    '${lesson.startAt} · ${context.l10n.minutes(lesson.durationMinutes)}'
                    '${completed ? ' · ${context.l10n.done.toLowerCase()}' : ''}'
                    '${lesson.isGroup ? ' · ${context.l10n.group.toLowerCase()}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      color: cancelled
                          ? CupertinoColors.systemGrey2
                          : accent.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              if (constraints.maxHeight >= 44 &&
                  lesson.displaySubtitle != lesson.displayTitle) {
                lines.add(const SizedBox(height: 2));
                lines.add(
                  Text(
                    lesson.displaySubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: lines,
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    final int h12 = hour % 12 == 0 ? 12 : hour % 12;
    final String suffix = hour < 12 ? 'AM' : 'PM';
    return '$h12 $suffix';
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
          '${context.l10n.status}: ${lesson.status}'
          '${lesson.notes != null && lesson.notes!.isNotEmpty ? '\n${lesson.notes}' : ''}',
      cancelLabel: context.l10n.close,
      actions: <AppSheetAction>[
        if (lesson.status == 'scheduled')
          AppSheetAction(
            label: context.l10n.markCompleted,
            onPressed: (BuildContext ctx) async {
              Navigator.of(ctx).pop();
              await _updateStatus(lesson, 'completed');
            },
          ),
        if (lesson.status != 'cancelled')
          AppSheetAction(
            label: context.l10n.cancelLesson,
            isDestructive: true,
            onPressed: (BuildContext ctx) async {
              Navigator.of(ctx).pop();
              await _updateStatus(lesson, 'cancelled');
            },
          ),
        AppSheetAction(
          label: context.l10n.delete,
          isDestructive: true,
          onPressed: (BuildContext ctx) async {
            Navigator.of(ctx).pop();
            await _confirmDelete(lesson);
          },
        ),
      ],
    );
  }

  Future<void> _updateStatus(Lesson lesson, String status) async {
    try {
      await _lessonService.updateLesson(
        id: lesson.id,
        body: <String, dynamic>{'status': status},
      );
      await _loadWeek();
    } on LessonServiceException catch (error) {
      await _showError(error.message);
    }
  }

  Future<void> _confirmDelete(Lesson lesson) async {
    final bool? confirmed = await showAppAlert<bool>(
      context: context,
      title: context.l10n.deleteLesson,
      message: context.l10n.deleteLessonConfirm(lesson.displayTitle),
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
      await _lessonService.deleteLesson(lesson.id);
      await _loadWeek();
    } on LessonServiceException catch (error) {
      await _showError(error.message);
    }
  }

  Future<void> _showError(String message) {
    return showAppAlert<void>(
      context: context,
      title: context.l10n.journal,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }
}
