import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:intl/intl.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';

/// Compact month calendar for picking a birthday.
Future<DateTime?> showBirthdayCalendar({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? maximumDate,
  DateTime? minimumDate,
}) {
  final DateTime now = DateTime.now();
  final DateTime max = maximumDate ?? now;
  final DateTime min = minimumDate ?? DateTime(1950, 1, 1);
  DateTime initial = initialDate ?? DateTime(2010, 1, 1);
  if (initial.isAfter(max)) {
    initial = max;
  }
  if (initial.isBefore(min)) {
    initial = min;
  }

  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.l10n.dismiss,
    barrierColor: const Color(0x66000000),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (
      BuildContext dialogContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _BirthdayCalendarDialog(
              initialDate: initial,
              minimumDate: min,
              maximumDate: max,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _BirthdayCalendarDialog extends StatefulWidget {
  const _BirthdayCalendarDialog({
    required this.initialDate,
    required this.minimumDate,
    required this.maximumDate,
  });

  final DateTime initialDate;
  final DateTime minimumDate;
  final DateTime maximumDate;

  @override
  State<_BirthdayCalendarDialog> createState() =>
      _BirthdayCalendarDialogState();
}

class _BirthdayCalendarDialogState extends State<_BirthdayCalendarDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSelectable(DateTime day) {
    final DateTime only = DateTime(day.year, day.month, day.day);
    final DateTime min = DateTime(
      widget.minimumDate.year,
      widget.minimumDate.month,
      widget.minimumDate.day,
    );
    final DateTime max = DateTime(
      widget.maximumDate.year,
      widget.maximumDate.month,
      widget.maximumDate.day,
    );
    return !only.isBefore(min) && !only.isAfter(max);
  }

  void _shiftMonth(int delta) {
    final DateTime next =
        DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final DateTime minMonth =
        DateTime(widget.minimumDate.year, widget.minimumDate.month);
    final DateTime maxMonth =
        DateTime(widget.maximumDate.year, widget.maximumDate.month);
    if (next.isBefore(minMonth) || next.isAfter(maxMonth)) {
      return;
    }
    setState(() {
      _visibleMonth = next;
    });
  }

  List<DateTime?> _daysInGrid() {
    final DateTime first = DateTime(_visibleMonth.year, _visibleMonth.month);
    // Monday = 1 ... Sunday = 7 → index 0 = Monday
    final int leading = first.weekday - DateTime.monday;
    final int daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    final List<DateTime?> cells = _daysInGrid();
    final String title =
        DateFormat.yMMMM(locale).format(_visibleMonth);
    final List<String> weekdayLabels = List<String>.generate(7, (int i) {
      // Monday-based week to match grid.
      final DateTime day =
          DateTime(2024, 1, 1).add(Duration(days: i)); // Mon Jan 1 2024
      return DateFormat.E(locale).format(day);
    });

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(22),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    CupertinoIcons.gift_fill,
                    size: 18,
                    color: Color(0xFFFF2D55),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.birthday,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: CupertinoColors.systemGrey3,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minimumSize: Size.zero,
                    onPressed: () => _shiftMonth(-12),
                    child: const Icon(CupertinoIcons.chevron_left_2, size: 16),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minimumSize: Size.zero,
                    onPressed: () => _shiftMonth(-1),
                    child: const Icon(CupertinoIcons.chevron_left, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minimumSize: Size.zero,
                    onPressed: () => _shiftMonth(1),
                    child: const Icon(CupertinoIcons.chevron_right, size: 18),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minimumSize: Size.zero,
                    onPressed: () => _shiftMonth(12),
                    child: const Icon(CupertinoIcons.chevron_right_2, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: weekdayLabels
                    .map(
                      (String label) => Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final DateTime? day = cells[index];
                  if (day == null) {
                    return const SizedBox.shrink();
                  }
                  final bool selected = _sameDay(day, _selected);
                  final bool enabled = _isSelectable(day);
                  return GestureDetector(
                    onTap: enabled
                        ? () {
                            setState(() {
                              _selected = day;
                            });
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? const Color(0xFFFF2D55)
                            : const Color(0x00000000),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: !enabled
                              ? CupertinoColors.tertiaryLabel
                                  .resolveFrom(context)
                              : selected
                                  ? CupertinoColors.white
                                  : CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => Navigator.of(context).pop(_selected),
                      child: Text(l10n.select),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
