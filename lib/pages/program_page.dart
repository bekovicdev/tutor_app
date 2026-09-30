import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/create_lesson_page.dart';
import 'package:tutor_app/pages/lesson_detail_page.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({
    required this.token,
    required this.day,
    super.key,
  });

  final String token;
  final DateTime day;

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  static const double _hourHeight = 64;
  static const double _slotHeight = _hourHeight / 2;
  static const double _hourLabelWidth = 52;
  static const int _hoursInDay = 24;
  static const int _slotsInDay = _hoursInDay * 2;
  static const int _snapMinutes = 30;

  late final LessonService _lessonService;
  final ScrollController _gridScrollController = ScrollController();
  final GlobalKey _gridColumnKey = GlobalKey();
  final GlobalKey _gridViewportKey = GlobalKey();

  List<Lesson> _lessons = <Lesson>[];
  bool _isLoading = true;
  String? _errorMessage;
  bool _slotPicking = false;
  int? _pressedSlotIndex;
  Lesson? _draggingLesson;
  int? _dragTargetStartMinutes;
  bool _isRescheduling = false;
  bool _changed = false;

  DateTime get _day => DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
      );

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService(token: widget.token);
    _loadDay();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToWorkHours());
  }

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadDay() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final String dateKey = _formatDate(_day);
      final List<Lesson> lessons = await _lessonService.calendar(
        startDate: dateKey,
        endDate: dateKey,
        source: LessonSource.schedule,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lessons = lessons;
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

  void _scrollToWorkHours() {
    if (!_gridScrollController.hasClients) {
      return;
    }
    final DateTime today = DateTime.now();
    final int focusHour = _day.year == today.year &&
            _day.month == today.month &&
            _day.day == today.day
        ? today.hour.clamp(7, 20)
        : 9;
    final double offset = (focusHour * _hourHeight) -
        (_gridScrollController.position.viewportDimension / 3);
    _gridScrollController.jumpTo(
      offset.clamp(0.0, _gridScrollController.position.maxScrollExtent),
    );
  }

  void _markChanged() {
    _changed = true;
  }

  void _startSlotPicking() {
    setState(() {
      _slotPicking = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gridScrollController.hasClients) {
        return;
      }
      final int focusHour = DateTime.now().hour.clamp(7, 20);
      final double offset = (focusHour * _hourHeight) -
          (_gridScrollController.position.viewportDimension / 3);
      _gridScrollController.animateTo(
        offset.clamp(0.0, _gridScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _cancelSlotPicking() {
    setState(() {
      _slotPicking = false;
      _pressedSlotIndex = null;
    });
  }

  String _startAtForSlot(int slotIndex) {
    final int totalMinutes = slotIndex * 30;
    final int hour = totalMinutes ~/ 60;
    final int minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _onSlotSelected(int slotIndex) async {
    setState(() {
      _slotPicking = false;
      _pressedSlotIndex = null;
    });
    final String startAt = _startAtForSlot(slotIndex);
    final Lesson? created = await Navigator.of(context).push<Lesson>(
      CupertinoPageRoute<Lesson>(
        builder: (BuildContext context) => CreateLessonPage(
          token: widget.token,
          source: LessonSource.schedule,
          initialDate: _day,
          initialStartAt: startAt,
          lockDateTime: true,
        ),
      ),
    );
    if (created != null) {
      _markChanged();
      await _loadDay();
    }
  }

  bool _canDragLesson(Lesson lesson) {
    if (_slotPicking || _isRescheduling) {
      return false;
    }
    return lesson.status == 'scheduled';
  }

  String _formatStartAt(int totalMinutes) {
    final int hour = totalMinutes ~/ 60;
    final int minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int _snapStartMinutes(int rawMinutes, int durationMinutes) {
    final int snapped =
        ((rawMinutes / _snapMinutes).round() * _snapMinutes).clamp(0, 24 * 60);
    final int maxStart = (24 * 60 - durationMinutes).clamp(0, 24 * 60);
    return snapped.clamp(0, maxStart);
  }

  int? _startMinutesFromGlobalPosition(
    Offset globalPosition,
    int durationMinutes,
  ) {
    final RenderBox? gridBox =
        _gridColumnKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null || !gridBox.hasSize) {
      return null;
    }
    final Offset local = gridBox.globalToLocal(globalPosition);
    if (local.dy < 0 || local.dy > gridBox.size.height) {
      return null;
    }
    final int rawMinutes = (local.dy / _hourHeight * 60).round();
    return _snapStartMinutes(rawMinutes, durationMinutes);
  }

  void _beginLessonDrag(Lesson lesson, LongPressStartDetails details) {
    if (!_canDragLesson(lesson)) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _draggingLesson = lesson;
      _dragTargetStartMinutes = _startMinutesFromGlobalPosition(
            details.globalPosition,
            lesson.durationMinutes,
          ) ??
          lesson.startMinutes;
    });
  }

  void _moveLessonDrag(Offset globalPosition) {
    if (_draggingLesson == null) {
      return;
    }
    final int? startMinutes = _startMinutesFromGlobalPosition(
      globalPosition,
      _draggingLesson!.durationMinutes,
    );
    if (startMinutes == null) {
      return;
    }
    setState(() {
      _dragTargetStartMinutes = startMinutes;
    });
    _maybeAutoScroll(globalPosition);
  }

  void _maybeAutoScroll(Offset globalPosition) {
    final RenderBox? viewportBox =
        _gridViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !_gridScrollController.hasClients) {
      return;
    }
    final Offset localInViewport = viewportBox.globalToLocal(globalPosition);
    const double edgeThreshold = 72;
    const double scrollStep = 10;
    final double viewportHeight = viewportBox.size.height;
    double nextOffset = _gridScrollController.offset;
    if (localInViewport.dy < edgeThreshold) {
      nextOffset -= scrollStep;
    } else if (localInViewport.dy > viewportHeight - edgeThreshold) {
      nextOffset += scrollStep;
    } else {
      return;
    }
    _gridScrollController.jumpTo(
      nextOffset.clamp(0.0, _gridScrollController.position.maxScrollExtent),
    );
  }

  Future<void> _finishLessonDrag() async {
    final Lesson? lesson = _draggingLesson;
    final int? targetStartMinutes = _dragTargetStartMinutes;
    setState(() {
      _draggingLesson = null;
      _dragTargetStartMinutes = null;
    });
    if (lesson == null || targetStartMinutes == null) {
      return;
    }
    if (lesson.startMinutes == targetStartMinutes) {
      return;
    }
    await _rescheduleLesson(lesson, targetStartMinutes);
  }

  void _cancelLessonDrag() {
    if (_draggingLesson == null) {
      return;
    }
    setState(() {
      _draggingLesson = null;
      _dragTargetStartMinutes = null;
    });
  }

  Future<void> _rescheduleLesson(
    Lesson lesson,
    int targetStartMinutes,
  ) async {
    setState(() {
      _isRescheduling = true;
    });
    try {
      await _lessonService.updateLesson(
        id: lesson.id,
        body: <String, dynamic>{
          'date': _formatDate(_day),
          'start_at': _formatStartAt(targetStartMinutes),
        },
      );
      if (!mounted) {
        return;
      }
      _markChanged();
      await _loadDay();
    } on LessonServiceException catch (error) {
      if (!mounted) {
        return;
      }
      await showAppAlert<void>(
        context: context,
        title: context.l10n.somethingWentWrong,
        message: error.message,
        actions: <AppAlertAction>[
          AppAlertAction(
            label: context.l10n.ok,
            style: AppAlertStyle.primary,
          ),
        ],
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRescheduling = false;
        });
      }
    }
  }

  String _dayTitle(BuildContext context) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    return intl.DateFormat.yMMMEd(locale).format(_day);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.schedule,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              Text(
                _dayTitle(context),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
          border: appNavigationBarBorderOf(context),
          leading: _slotPicking
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _cancelSlotPicking,
                  child: Text(l10n.cancel),
                )
              : CupertinoNavigationBarBackButton(
                  onPressed: () {
                    Navigator.of(context).pop(_changed);
                  },
                ),
          trailing: _slotPicking
              ? null
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _startSlotPicking,
                  child: const Icon(CupertinoIcons.add),
                ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              if (_slotPicking)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                  child: Text(
                    l10n.selectTimeSlotHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
              Expanded(
                key: _gridViewportKey,
                child: Stack(
                  children: <Widget>[
                    _buildGrid(),
                    if (_isRescheduling)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x11000000),
                          child: Center(child: CupertinoActivityIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
              onPressed: _loadDay,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    final double gridHeight = _slotsInDay * _slotHeight;

    return SingleChildScrollView(
      controller: _gridScrollController,
      padding: const EdgeInsets.fromLTRB(0, 4, 12, 16),
      child: SizedBox(
        height: gridHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: _hourLabelWidth,
              child: Column(
                children: List<Widget>.generate(_slotsInDay, (int slotIndex) {
                  final bool isHourStart = slotIndex.isEven;
                  return SizedBox(
                    height: _slotHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        _formatSlotLabel(slotIndex),
                        style: TextStyle(
                          fontSize: isHourStart ? 10 : 9,
                          fontWeight:
                              isHourStart ? FontWeight.w600 : FontWeight.w500,
                          color: isHourStart
                              ? CupertinoColors.secondaryLabel.resolveFrom(
                                  context,
                                )
                              : CupertinoColors.tertiaryLabel.resolveFrom(
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
                key: _gridColumnKey,
                clipBehavior: Clip.none,
                children: <Widget>[
                  _ProgramDayColumn(
                    lessons: _lessons,
                    pixelsPerHour: _hourHeight,
                    slotHeight: _slotHeight,
                    slotsInDay: _slotsInDay,
                    slotPicking: _slotPicking,
                    pressedSlotIndex: _slotPicking ? _pressedSlotIndex : null,
                    draggingLessonId: _draggingLesson?.id,
                    onSlotTap: _onSlotSelected,
                    onSlotLongPress: _onSlotSelected,
                    onSlotPressStart: (int slotIndex) {
                      setState(() {
                        _pressedSlotIndex = slotIndex;
                      });
                    },
                    onSlotPressEnd: () {
                      if (_pressedSlotIndex == null) {
                        return;
                      }
                      setState(() {
                        _pressedSlotIndex = null;
                      });
                    },
                    onLessonTap: _onLessonTap,
                    onLessonDragStart: _beginLessonDrag,
                    onLessonDragMove: _moveLessonDrag,
                    onLessonDragEnd: () {
                      unawaited(_finishLessonDrag());
                    },
                    onLessonDragCancel: _cancelLessonDrag,
                    canDragLesson: _canDragLesson,
                    parseColor: _parseHexColor,
                  ),
                  if (_draggingLesson != null && _dragTargetStartMinutes != null)
                    _buildDropPreview(
                      lesson: _draggingLesson!,
                      targetStartMinutes: _dragTargetStartMinutes!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropPreview({
    required Lesson lesson,
    required int targetStartMinutes,
  }) {
    final double top = targetStartMinutes / 60 * _hourHeight;
    final double blockHeight = (lesson.durationMinutes / 60 * _hourHeight)
        .clamp(16.0, _slotsInDay * _slotHeight);
    final Color accent = _parseHexColor(lesson.accentColor);

    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: blockHeight,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent, width: 1.4),
          ),
          child: Text(
            lesson.indexLabel,
            maxLines: blockHeight < 28 ? 1 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSlotLabel(int slotIndex) {
    final int totalMinutes = slotIndex * 30;
    final int hour = totalMinutes ~/ 60;
    final int minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}';
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

  Future<void> _onLessonTap(Lesson lesson) async {
    final bool? changed = await openLessonDetailPage(
      context,
      token: widget.token,
      lessonId: lesson.id,
      lesson: lesson,
      preferredSource: LessonSource.schedule,
    );
    if (changed == true) {
      _markChanged();
      await _loadDay();
    }
  }
}

class _ProgramDayColumn extends StatelessWidget {
  const _ProgramDayColumn({
    required this.lessons,
    required this.pixelsPerHour,
    required this.slotHeight,
    required this.slotsInDay,
    required this.slotPicking,
    required this.pressedSlotIndex,
    required this.draggingLessonId,
    required this.onSlotTap,
    required this.onSlotLongPress,
    required this.onSlotPressStart,
    required this.onSlotPressEnd,
    required this.onLessonTap,
    required this.onLessonDragStart,
    required this.onLessonDragMove,
    required this.onLessonDragEnd,
    required this.onLessonDragCancel,
    required this.canDragLesson,
    required this.parseColor,
  });

  final List<Lesson> lessons;
  final double pixelsPerHour;
  final double slotHeight;
  final int slotsInDay;
  final bool slotPicking;
  final int? pressedSlotIndex;
  final int? draggingLessonId;
  final ValueChanged<int> onSlotTap;
  final ValueChanged<int> onSlotLongPress;
  final ValueChanged<int> onSlotPressStart;
  final VoidCallback onSlotPressEnd;
  final ValueChanged<Lesson> onLessonTap;
  final void Function(Lesson lesson, LongPressStartDetails details)
      onLessonDragStart;
  final ValueChanged<Offset> onLessonDragMove;
  final VoidCallback onLessonDragEnd;
  final VoidCallback onLessonDragCancel;
  final bool Function(Lesson lesson) canDragLesson;
  final Color Function(String? hex) parseColor;

  @override
  Widget build(BuildContext context) {
    final double height = slotsInDay * slotHeight;
    final Color line = CupertinoColors.separator
        .resolveFrom(context)
        .withValues(alpha: slotPicking ? 0.75 : 0.55);
    final Color halfHourLine = line.withValues(alpha: 0.45);
    final Color pressFill = CupertinoColors.label
        .resolveFrom(context)
        .withValues(alpha: 0.08);

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
              children: List<Widget>.generate(slotsInDay, (int slotIndex) {
                final bool isHourStart = slotIndex.isEven;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: slotPicking
                      ? null
                      : () => onSlotLongPress(slotIndex),
                  child: Container(
                    height: slotHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isHourStart ? line : halfHourLine,
                          width: isHourStart ? 0.5 : 0.35,
                        ),
                      ),
                    ),
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
              final double top = start / 60 * pixelsPerHour;
              final double blockHeight =
                  ((end - start) / 60 * pixelsPerHour).clamp(16.0, height);

              final Color accent = parseColor(lesson.accentColor);
              final bool cancelled = lesson.status == 'cancelled';
              final bool isDragging = draggingLessonId == lesson.id;
              final bool canDrag = canDragLesson(lesson);

              return Positioned(
                top: top,
                left: 4,
                right: 4,
                height: blockHeight,
                child: IgnorePointer(
                  ignoring: slotPicking,
                  child: GestureDetector(
                    onTap: isDragging ? null : () => onLessonTap(lesson),
                    onLongPressStart: canDrag && !slotPicking
                        ? (LongPressStartDetails details) =>
                            onLessonDragStart(lesson, details)
                        : null,
                    onLongPressMoveUpdate: canDrag && !slotPicking
                        ? (LongPressMoveUpdateDetails details) =>
                            onLessonDragMove(details.globalPosition)
                        : null,
                    onLongPressEnd: canDrag && !slotPicking
                        ? (_) => onLessonDragEnd()
                        : null,
                    onLongPressCancel: canDrag && !slotPicking
                        ? () => onLessonDragCancel()
                        : null,
                    child: Opacity(
                      opacity: slotPicking ? 0.4 : isDragging ? 0.25 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cancelled
                              ? CupertinoColors.systemGrey5.resolveFrom(context)
                              : accent.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: cancelled
                                ? CupertinoColors.systemGrey3
                                    .resolveFrom(context)
                                : accent,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          lesson.indexLabel,
                          maxLines: blockHeight < 28 ? 1 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
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
                  ),
                ),
              );
            }),
            if (slotPicking)
              ...List<Widget>.generate(slotsInDay, (int slotIndex) {
                final bool pressed = pressedSlotIndex == slotIndex;
                return Positioned(
                  top: slotIndex * slotHeight,
                  left: 0,
                  right: 0,
                  height: slotHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => onSlotPressStart(slotIndex),
                    onTapCancel: onSlotPressEnd,
                    onTapUp: (_) => onSlotPressEnd(),
                    onTap: () => onSlotTap(slotIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 90),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: pressed ? pressFill : null,
                        borderRadius: BorderRadius.circular(8),
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
