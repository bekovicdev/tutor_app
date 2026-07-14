import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/create_lesson_page.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';
import 'package:tutor_app/widgets/settings_nav_button.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({
    required this.token,
    this.onOpenSettings,
    super.key,
  });

  final String token;
  final void Function(BuildContext context)? onOpenSettings;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  static const double _hourHeight = 64;
  static const int _startHour = 0;
  static const int _endHour = 24;

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
        border: appNavigationBarBorderOf(context),
        leading: widget.onOpenSettings == null
            ? null
            : SettingsNavButton(
                onPressed: () => widget.onOpenSettings!(context),
              ),
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
                      ? AppBrand.primary
                      : CupertinoColors.secondarySystemGroupedBackground
                            .resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !selected
                      ? Border.all(
                          color: AppBrand.primary,
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
                                  : AppBrand.primary)
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
                  width: 48,
                  child: Column(
                    children: List<Widget>.generate(totalHours, (int index) {
                      final int hour = _startHour + index;
                      return SizedBox(
                        height: _hourHeight,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8, top: 0),
                            child: Text(
                              _formatHour(hour),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
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
        '${_now.hour.toString().padLeft(2, '0')}.${_now.minute.toString().padLeft(2, '0')}';

    return Positioned(
      top: top - 8,
      left: 0,
      right: 0,
      height: 16,
      child: IgnorePointer(
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
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
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
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
        .clamp(32.0, timelineHeight);

    final Color accent = _parseHexColor(lesson.accentColor);
    final bool cancelled = lesson.status == 'cancelled';
    final bool completed = lesson.status == 'completed';
    final Brightness brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    final bool isDark = brightness == Brightness.dark;

    final Color surface = cancelled
        ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7))
        : Color.alphaBlend(
            accent.withValues(alpha: isDark ? 0.22 : 0.12),
            isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
          );
    final Color titleColor = cancelled
        ? CupertinoColors.secondaryLabel.resolveFrom(context)
        : CupertinoColors.label.resolveFrom(context);
    final Color metaColor = cancelled
        ? CupertinoColors.tertiaryLabel.resolveFrom(context)
        : accent;

    return Positioned(
      top: top + 2,
      left: 6,
      right: 2,
      height: height - 4,
      child: GestureDetector(
        onTap: () => _showLessonDetails(lesson),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: cancelled
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  width: 4,
                  color: cancelled
                      ? CupertinoColors.systemGrey3.resolveFrom(context)
                      : accent,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      10,
                      height < 40 ? 6 : 8,
                      10,
                      height < 40 ? 6 : 8,
                    ),
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final AppLocalizations l10n = context.l10n;
                        final String timeRange =
                            '${_formatClock(lesson.startMinutes)}–${_formatClock(lesson.endMinutes)}';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    lesson.displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15,
                                      color: titleColor,
                                      decoration: cancelled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (completed || cancelled) ...<Widget>[
                                  const SizedBox(width: 6),
                                  _statusPill(
                                    label: cancelled
                                        ? l10n.cancelled
                                        : l10n.completed,
                                    color: cancelled
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.activeGreen,
                                  ),
                                ],
                              ],
                            ),
                            if (constraints.maxHeight >= 30) ...<Widget>[
                              const SizedBox(height: 3),
                              Text(
                                timeRange,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                  color: metaColor,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                            if (constraints.maxHeight >= 48 &&
                                lesson.displaySubtitle !=
                                    lesson.displayTitle) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                lesson.displaySubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.1,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                            if (constraints.maxHeight >= 62 &&
                                lesson.isGroup &&
                                lesson.studentNotes.any(
                                  (LessonStudentNote n) =>
                                      n.notes.trim().isNotEmpty,
                                )) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                '${l10n.lessonNotesSummary}: ${lesson.studentNotes.where((LessonStudentNote n) => n.notes.trim().isNotEmpty).length}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.1,
                                  color: CupertinoColors.tertiaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    final int h = hour % 24;
    return '${h.toString().padLeft(2, '0')}.00';
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

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'completed':
        return l10n.completed;
      case 'cancelled':
        return l10n.cancelled;
      case 'scheduled':
      default:
        return l10n.scheduled;
    }
  }

  Future<void> _showLessonDetails(Lesson lesson) async {
    final AppLocalizations l10n = context.l10n;
    final StringBuffer message = StringBuffer()
      ..writeln(
        '${lesson.date} · ${lesson.startAt} · ${l10n.minutes(lesson.durationMinutes)}',
      )
      ..writeln(lesson.displaySubtitle)
      ..write('${l10n.status}: ${_statusLabel(l10n, lesson.status)}');
    if (lesson.notes != null && lesson.notes!.isNotEmpty) {
      message.write('\n${lesson.notes}');
    }
    if (lesson.isGroup && lesson.studentNotes.isNotEmpty) {
      message.write('\n\n${l10n.lessonNotesSummary}:');
      for (final LessonStudentNote note in lesson.studentNotes) {
        final String name = note.studentName ?? '#${note.studentId}';
        if (note.notes.trim().isEmpty) {
          continue;
        }
        message.write('\n· $name: ${note.notes}');
      }
    }
    await showAppActionSheet<void>(
      context: context,
      title: lesson.displayTitle,
      message: message.toString(),
      cancelLabel: l10n.close,
      actions: <AppSheetAction>[
        AppSheetAction(
          label: l10n.editLessonAction,
          onPressed: (BuildContext ctx) async {
            Navigator.of(ctx).pop();
            final bool? changed = await Navigator.of(context).push<bool>(
              CupertinoPageRoute<bool>(
                builder: (BuildContext context) => CreateLessonPage(
                  token: widget.token,
                  source: LessonSource.journal,
                  lesson: lesson,
                ),
              ),
            );
            if (changed == true) {
              await _loadWeek();
            }
          },
        ),
        if (lesson.status == 'scheduled')
          AppSheetAction(
            label: l10n.markCompleted,
            onPressed: (BuildContext ctx) async {
              Navigator.of(ctx).pop();
              await _updateStatus(lesson, 'completed');
            },
          ),
        if (lesson.status != 'cancelled')
          AppSheetAction(
            label: l10n.cancelLesson,
            isDestructive: true,
            onPressed: (BuildContext ctx) async {
              Navigator.of(ctx).pop();
              await _updateStatus(lesson, 'cancelled');
            },
          ),
        AppSheetAction(
          label: l10n.delete,
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
