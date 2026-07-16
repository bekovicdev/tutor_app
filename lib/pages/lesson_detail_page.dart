import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/create_lesson_page.dart';
import 'package:tutor_app/pages/paywall_page.dart';
import 'package:tutor_app/payments/payment_service.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

Future<bool?> openLessonDetailPage(
  BuildContext context, {
  required String token,
  required int lessonId,
  Lesson? lesson,
  String? preferredSource,
}) {
  return Navigator.of(context).push<bool>(
    CupertinoPageRoute<bool>(
      builder: (BuildContext context) => LessonDetailPage(
        token: token,
        lessonId: lessonId,
        initialLesson: lesson,
        preferredSource: preferredSource,
      ),
    ),
  );
}

class LessonDetailPage extends StatefulWidget {
  const LessonDetailPage({
    required this.token,
    required this.lessonId,
    this.initialLesson,
    this.preferredSource,
    super.key,
  });

  final String token;
  final int lessonId;
  final Lesson? initialLesson;

  /// Hint for which editor flow to open (`schedule` / `journal`).
  final String? preferredSource;

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  late final LessonService _lessonService = LessonService(token: widget.token);
  late final PaymentService _paymentService =
      PaymentService(token: widget.token);

  Lesson? _lesson;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _lesson = widget.initialLesson;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _lesson == null;
      _error = null;
    });
    try {
      final Lesson lesson = await _lessonService.getLesson(widget.lessonId);
      if (!mounted) {
        return;
      }
      setState(() {
        _lesson = lesson;
        _loading = false;
      });
    } on LessonServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  String get _editorSource {
    final String? preferred = widget.preferredSource;
    if (preferred == LessonSource.schedule ||
        preferred == LessonSource.journal) {
      return preferred!;
    }
    return _lesson?.resolvedSource ?? LessonSource.journal;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Lesson? lesson = _lesson;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          lesson?.displayTitle ?? l10n.lessonDetail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(_changed),
          child: Text(l10n.back),
        ),
        trailing: lesson == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _busy ? null : _showActions,
                child: const Icon(CupertinoIcons.ellipsis_circle),
              ),
      ),
      child: SafeArea(child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading && _lesson == null) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error != null && _lesson == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: _load,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final Lesson lesson = _lesson!;
    final Color accent = _parseHexColor(lesson.accentColor);
    final Color secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);

    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: <Widget>[
            AppGlassCard(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                    ),
                    child: Icon(
                      lesson.isGroup
                          ? CupertinoIcons.person_3_fill
                          : CupertinoIcons.person_fill,
                      color: accent,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    lesson.displayTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.label.resolveFrom(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.displaySubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      _chip(
                        _statusLabel(l10n, lesson.status),
                        _statusColor(lesson.status),
                      ),
                      if (lesson.isFree == true)
                        _chip(l10n.freeLesson, AppBrand.primary)
                      else
                        _chip(
                          _paymentLabel(l10n, lesson.resolvedPaymentStatus),
                          _paymentColor(lesson.resolvedPaymentStatus),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: <Widget>[
                  _infoRow(
                    icon: CupertinoIcons.calendar,
                    label: l10n.date,
                    value: _formatDate(lesson.date),
                  ),
                  _divider(),
                  _infoRow(
                    icon: CupertinoIcons.time,
                    label: l10n.startTime,
                    value: _formatTime(lesson.startAt),
                  ),
                  _divider(),
                  _infoRow(
                    icon: CupertinoIcons.timer,
                    label: l10n.duration,
                    value: l10n.minutes(lesson.durationMinutes),
                  ),
                  if (lesson.isFree != true) ...<Widget>[
                    _divider(),
                    _infoRow(
                      icon: CupertinoIcons.money_dollar,
                      label: l10n.price,
                      value: _priceLabel(lesson),
                    ),
                  ],
                  _divider(),
                  _infoRow(
                    icon: lesson.isGroup
                        ? CupertinoIcons.person_3
                        : CupertinoIcons.person,
                    label: lesson.isGroup ? l10n.group : l10n.student,
                    value: lesson.displaySubtitle,
                  ),
                ],
              ),
            ),
            if (lesson.notes != null && lesson.notes!.trim().isNotEmpty) ...<
                Widget>[
              const SizedBox(height: 16),
              _sectionLabel(l10n.notes),
              AppGlassCard(
                child: Text(
                  lesson.notes!.trim(),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ],
            if (lesson.isGroup &&
                lesson.studentNotes.any(
                  (LessonStudentNote n) => n.notes.trim().isNotEmpty,
                )) ...<Widget>[
              const SizedBox(height: 16),
              _sectionLabel(l10n.studentNotes),
              AppGlassCard(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  children: lesson.studentNotes
                      .where(
                        (LessonStudentNote n) => n.notes.trim().isNotEmpty,
                      )
                      .map((LessonStudentNote note) {
                    final String name =
                        note.studentName?.trim().isNotEmpty == true
                            ? note.studentName!.trim()
                            : '#${note.studentId}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 88,
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              note.notes.trim(),
                              style: TextStyle(
                                fontSize: 15,
                                color: CupertinoColors.label
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: _bottomActions(l10n, lesson),
        ),
      ],
    );
  }

  Widget _bottomActions(AppLocalizations l10n, Lesson lesson) {
    final bool canMarkDone = lesson.status == 'scheduled' &&
        (_editorSource == LessonSource.schedule ||
            lesson.resolvedSource == LessonSource.schedule);
    final bool canComplete =
        lesson.status == 'scheduled' && !canMarkDone;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (canMarkDone)
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _busy ? null : () => _markLessonDone(lesson),
              child: Text(l10n.markLessonDone),
            ),
          )
        else if (canComplete)
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _busy ? null : () => _updateStatus(lesson, 'completed'),
              child: Text(l10n.markCompleted),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.secondarySystemGroupedBackground
                .resolveFrom(context),
            onPressed: _busy ? null : _openEditor,
            child: Text(
              l10n.editLessonAction,
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final Color secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppBrand.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 0.5,
      color: CupertinoColors.separator
          .resolveFrom(context)
          .withValues(alpha: 0.35),
    );
  }

  Future<void> _showActions() async {
    final Lesson? lesson = _lesson;
    if (lesson == null) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    await showAppActionSheet<void>(
      context: context,
      title: lesson.displayTitle,
      actions: <AppSheetAction>[
        AppSheetAction(
          label: l10n.editLessonAction,
          onPressed: (BuildContext ctx) {
            Navigator.of(ctx).pop();
            _openEditor();
          },
        ),
        if (lesson.status == 'scheduled' &&
            (_editorSource == LessonSource.schedule ||
                lesson.resolvedSource == LessonSource.schedule))
          AppSheetAction(
            label: l10n.markLessonDone,
            onPressed: (BuildContext ctx) {
              Navigator.of(ctx).pop();
              _markLessonDone(lesson);
            },
          ),
        if (lesson.status == 'scheduled')
          AppSheetAction(
            label: l10n.markCompleted,
            onPressed: (BuildContext ctx) {
              Navigator.of(ctx).pop();
              _updateStatus(lesson, 'completed');
            },
          ),
        if (lesson.status != 'cancelled')
          AppSheetAction(
            label: l10n.cancelLesson,
            isDestructive: true,
            onPressed: (BuildContext ctx) {
              Navigator.of(ctx).pop();
              _updateStatus(lesson, 'cancelled');
            },
          ),
        AppSheetAction(
          label: l10n.delete,
          isDestructive: true,
          onPressed: (BuildContext ctx) {
            Navigator.of(ctx).pop();
            _confirmDelete(lesson);
          },
        ),
      ],
    );
  }

  Future<void> _openEditor() async {
    final Lesson? lesson = _lesson;
    if (lesson == null) {
      return;
    }
    final bool? changed = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) => CreateLessonPage(
          token: widget.token,
          source: _editorSource,
          lesson: lesson,
        ),
      ),
    );
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _markLessonDone(Lesson lesson) async {
    final AppLocalizations l10n = context.l10n;
    String paymentChoice = 'unpaid';
    if (lesson.isFree != true) {
      final String? picked = await showAppActionSheet<String>(
        context: context,
        title: l10n.settlePaymentTitle,
        message: lesson.displayTitle,
        cancelLabel: l10n.cancel,
        actions: <AppSheetAction>[
          AppSheetAction(
            label: l10n.leaveUnpaid,
            onPressed: (BuildContext ctx) => Navigator.of(ctx).pop('unpaid'),
          ),
          AppSheetAction(
            label: l10n.markPaidNow,
            onPressed: (BuildContext ctx) => Navigator.of(ctx).pop('paid'),
          ),
          AppSheetAction(
            label: l10n.applyPrepaidCredit,
            onPressed: (BuildContext ctx) => Navigator.of(ctx).pop('prepaid'),
          ),
        ],
      );
      if (picked == null) {
        return;
      }
      paymentChoice = picked;
    }

    setState(() => _busy = true);
    try {
      await _lessonService.completeFromSchedule(lesson.id);
      if (paymentChoice != 'unpaid' && lesson.isFree != true) {
        await _paymentService.markLessonPayment(
          lessonId: lesson.id,
          request: LessonPaymentRequest(paymentStatus: paymentChoice),
        );
      }
      if (!mounted) {
        return;
      }
      _changed = true;
      await showAppAlert<void>(
        context: context,
        title: l10n.markLessonDone,
        message: l10n.movedToJournal,
        actions: <AppAlertAction>[
          AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
        ],
      );
      await _load();
    } on LessonServiceException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.isQuota) {
        await openPaywall(
          context,
          token: widget.token,
          reasonCode: error.code,
        );
      } else {
        await _showError(error.message);
      }
    } on PaymentServiceException catch (error) {
      if (!mounted) {
        return;
      }
      _changed = true;
      await _load();
      await _showError(error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _updateStatus(Lesson lesson, String status) async {
    setState(() => _busy = true);
    try {
      await _lessonService.updateLesson(
        id: lesson.id,
        body: <String, dynamic>{'status': status},
      );
      if (!mounted) {
        return;
      }
      _changed = true;
      await _load();
    } on LessonServiceException catch (error) {
      if (!mounted) {
        return;
      }
      await _showError(error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmDelete(Lesson lesson) async {
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showAppAlert<bool>(
      context: context,
      title: l10n.deleteLesson,
      message: l10n.deleteLessonConfirm(lesson.displayTitle),
      actions: <AppAlertAction>[
        AppAlertAction(
          label: l10n.cancel,
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: l10n.delete,
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(true),
        ),
      ],
    );
    if (confirmed != true) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _lessonService.deleteLesson(lesson.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on LessonServiceException catch (error) {
      if (!mounted) {
        return;
      }
      await _showError(error.message);
      setState(() => _busy = false);
    }
  }

  Future<void> _showError(String message) {
    return showAppAlert<void>(
      context: context,
      title: context.l10n.lessonDetail,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }

  String _priceLabel(Lesson lesson) {
    final String? raw = lesson.price?.trim();
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    return '$raw ${context.currencyLabel()}';
  }

  String _formatDate(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final Locale locale = Localizations.localeOf(context);
    return intl.DateFormat.yMMMEd(locale.toLanguageTag()).format(parsed);
  }

  String _formatTime(String raw) {
    final List<String> parts = raw.split(':');
    if (parts.length < 2) {
      return raw;
    }
    final int hour = int.tryParse(parts[0]) ?? 0;
    final int minute = int.tryParse(parts[1]) ?? 0;
    final DateTime dt = DateTime(2000, 1, 1, hour, minute);
    final Locale locale = Localizations.localeOf(context);
    return intl.DateFormat.jm(locale.toLanguageTag()).format(dt);
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'completed' => l10n.completed,
      'cancelled' => l10n.cancelled,
      _ => l10n.scheduled,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'completed' => CupertinoColors.activeGreen,
      'cancelled' => CupertinoColors.systemRed,
      _ => AppBrand.primary,
    };
  }

  String _paymentLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'paid' => l10n.paid,
      'prepaid' => l10n.prepaid,
      _ => l10n.unpaid,
    };
  }

  Color _paymentColor(String status) {
    return switch (status) {
      'paid' => CupertinoColors.activeGreen,
      'prepaid' => CupertinoColors.systemPurple,
      _ => CupertinoColors.systemOrange,
    };
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) {
      return AppBrand.primary;
    }
    String cleaned = hex.trim();
    if (cleaned.startsWith('#')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }
    final int? value = int.tryParse(cleaned, radix: 16);
    if (value == null) {
      return AppBrand.primary;
    }
    return Color(value);
  }
}
