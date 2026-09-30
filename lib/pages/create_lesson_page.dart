import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' as intl;
import 'package:tutor_app/groups/group_service.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/paywall_page.dart';
import 'package:tutor_app/payments/payment_service.dart';
import 'package:tutor_app/settings/app_settings.dart';
import 'package:tutor_app/students/student_service.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

class CreateLessonPage extends StatefulWidget {
  const CreateLessonPage({
    required this.token,
    required this.source,
    this.initialDate,
    this.initialStartAt,
    this.lockDateTime = false,
    this.lesson,
    this.preselectedStudentId,
    super.key,
  });

  final String token;
  final String source;
  final DateTime? initialDate;
  final String? initialStartAt;

  /// When true, date and start time are fixed (e.g. picked from schedule grid).
  final bool lockDateTime;

  /// When set, the page edits this lesson instead of creating a new one.
  final Lesson? lesson;

  /// When set (and [lesson] is null), the individual student is
  /// pre-selected, e.g. when creating a lesson from a student's detail page.
  final int? preselectedStudentId;

  bool get isEditing => lesson != null;

  @override
  State<CreateLessonPage> createState() => _CreateLessonPageState();
}

class _CreateLessonPageState extends State<CreateLessonPage> {
  late final LessonService _lessonService;
  late final StudentService _studentService;
  late final GroupService _groupService;
  late final PaymentService _paymentService;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final Map<int, TextEditingController> _studentNoteControllers =
      <int, TextEditingController>{};
  final Set<int> _existingStudentNoteIds = <int>{};

  DateTime _date = DateTime.now();
  Duration _startTime = const Duration(hours: 10);
  int _durationMinutes = 60;
  String _status = 'scheduled';
  bool _isGroup = false;
  bool _isFree = false;
  bool _repeatWeekly = false;
  int _repeatWeeks = 8;
  Student? _selectedStudent;
  TutorGroup? _selectedGroup;
  List<Student> _students = <Student>[];
  List<TutorGroup> _groups = <TutorGroup>[];
  List<Student> _groupMembers = <Student>[];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _defaultIndividualCost;
  String? _defaultGroupCost;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService(token: widget.token);
    _studentService = StudentService(token: widget.token);
    _groupService = GroupService(token: widget.token);
    _paymentService = PaymentService(token: widget.token);

    final DateTime? initial = widget.initialDate;
    if (initial != null) {
      _date = DateTime(initial.year, initial.month, initial.day);
    }
    final String? start = widget.initialStartAt;
    if (start != null && start.contains(':')) {
      final List<String> parts = start.split(':');
      final int hour = int.tryParse(parts[0]) ?? 10;
      final int minute = int.tryParse(parts[1]) ?? 0;
      _startTime = Duration(hours: hour, minutes: minute);
    }
    final Lesson? existing = widget.lesson;
    if (existing != null) {
      _applyLesson(existing);
    }
    _loadLookups();
  }

  void _applyLesson(Lesson lesson) {
    final String dateKey = lesson.date.length >= 10
        ? lesson.date.substring(0, 10)
        : lesson.date;
    final DateTime? parsedDate = DateTime.tryParse(dateKey);
    if (parsedDate != null) {
      _date = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    }
    final List<String> parts = lesson.startAt.split(':');
    if (parts.length >= 2) {
      _startTime = Duration(
        hours: int.tryParse(parts[0]) ?? 10,
        minutes: int.tryParse(parts[1]) ?? 0,
      );
    }
    _durationMinutes = lesson.durationMinutes > 0 ? lesson.durationMinutes : 60;
    _status = lesson.status;
    _isGroup = lesson.isGroup;
    _isFree = lesson.isFree == true;
    _titleController.text = lesson.title ?? '';
    _priceController.text = lesson.price ?? '';
    _notesController.text = lesson.notes ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    for (final TextEditingController controller
        in _studentNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _disposeStudentNoteControllers() {
    for (final TextEditingController controller
        in _studentNoteControllers.values) {
      controller.dispose();
    }
    _studentNoteControllers.clear();
    _existingStudentNoteIds.clear();
  }

  Future<void> _loadGroupMembersAndNotes(TutorGroup? group) async {
    _disposeStudentNoteControllers();
    if (group == null) {
      setState(() {
        _groupMembers = <Student>[];
      });
      return;
    }
    List<Student> members = <Student>[];
    try {
      final List<GroupStudent> rows = await _groupService.listGroupStudents(
        group.id,
      );
      members = rows.map((GroupStudent row) => row.student).toList();
    } on GroupServiceException {
      members = <Student>[];
    }

    final Map<int, String> existingNotes = <int, String>{};
    final Lesson? lesson = widget.lesson;
    if (lesson != null && lesson.isGroup) {
      try {
        final List<LessonStudentNote> notes = await _lessonService
            .listStudentNotes(lesson.id);
        for (final LessonStudentNote note in notes) {
          existingNotes[note.studentId] = note.notes;
          _existingStudentNoteIds.add(note.studentId);
        }
      } on LessonServiceException {
        for (final LessonStudentNote note in lesson.studentNotes) {
          existingNotes[note.studentId] = note.notes;
          _existingStudentNoteIds.add(note.studentId);
        }
      }
    }

    for (final Student member in members) {
      _studentNoteControllers[member.id] = TextEditingController(
        text: existingNotes[member.id] ?? '',
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _groupMembers = members;
    });
  }

  Future<void> _loadLookups() async {
    List<Student> students = <Student>[];
    List<TutorGroup> groups = <TutorGroup>[];
    final String? defaultIndividual = await AppSettings.individualLessonCost();
    final String? defaultGroup = await AppSettings.groupLessonCost();
    try {
      students = await _studentService.listStudents();
    } on StudentServiceException {
      // Form can still open.
    }
    try {
      groups = await _groupService.listGroups();
    } on GroupServiceException {
      // Form can still open.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _defaultIndividualCost = defaultIndividual;
      _defaultGroupCost = defaultGroup;
      _students = students;
      _groups = groups;
      final Lesson? existing = widget.lesson;
      if (existing != null) {
        if (existing.isGroup) {
          TutorGroup? match;
          for (final TutorGroup group in groups) {
            if (group.id == existing.groupId) {
              match = group;
              break;
            }
          }
          _selectedGroup = match ?? (groups.isNotEmpty ? groups.first : null);
          _selectedStudent = students.isNotEmpty ? students.first : null;
        } else {
          Student? match;
          for (final Student student in students) {
            if (student.id == existing.studentId) {
              match = student;
              break;
            }
          }
          _selectedStudent =
              match ?? (students.isNotEmpty ? students.first : null);
          _selectedGroup = groups.isNotEmpty ? groups.first : null;
        }
      } else {
        final int? preselectedId = widget.preselectedStudentId;
        if (preselectedId != null) {
          Student? match;
          for (final Student student in students) {
            if (student.id == preselectedId) {
              match = student;
              break;
            }
          }
          _selectedStudent =
              match ?? (students.isNotEmpty ? students.first : null);
          _isGroup = false;
        } else if (students.isNotEmpty) {
          _selectedStudent = students.first;
        }
        if (groups.isNotEmpty) {
          _selectedGroup = groups.first;
        }
        _fillDefaultPrice();
      }
      _isLoading = false;
    });
    if (_isGroup && _selectedGroup != null) {
      await _loadGroupMembersAndNotes(_selectedGroup);
    }
  }

  void _fillDefaultPrice({bool force = false}) {
    if (_isFree) {
      return;
    }
    if (!force && _priceController.text.trim().isNotEmpty) {
      return;
    }
    if (_isGroup) {
      final String? groupCost = _selectedGroup?.lessonCost?.trim();
      if (groupCost != null && groupCost.isNotEmpty) {
        _priceController.text = groupCost;
        return;
      }
      final String? groupDefault = _defaultGroupCost;
      if (groupDefault != null && groupDefault.isNotEmpty) {
        _priceController.text = groupDefault;
      }
      return;
    }
    final Student? student = _selectedStudent;
    final String? studentCost = student?.lessonCost?.trim();
    if (studentCost != null && studentCost.isNotEmpty) {
      _priceController.text = studentCost;
      return;
    }
    final String? individualDefault = _defaultIndividualCost;
    if (individualDefault != null && individualDefault.isNotEmpty) {
      _priceController.text = individualDefault;
    }
  }

  String get _pageTitle {
    final AppLocalizations l10n = context.l10n;
    if (widget.isEditing) {
      return widget.source == LessonSource.schedule
          ? l10n.editSchedule
          : l10n.editLesson;
    }
    return widget.source == LessonSource.schedule
        ? l10n.addSchedule
        : l10n.addLesson;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_pageTitle),
        border: appNavigationBarBorderOf(context),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const CupertinoActivityIndicator()
              : Text(
                  l10n.save,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: <Widget>[
                  _sectionLabel(l10n.target),
                  AppGlassCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      children: <Widget>[
                        _typeToggle(l10n),
                        const SizedBox(height: 12),
                        _personPicker(l10n),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.date),
                  AppGlassCard(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                    child: Column(
                      children: <Widget>[
                        if (widget.lockDateTime &&
                            !widget.isEditing) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                            child: _slotBanner(l10n),
                          ),
                          _rowDivider(),
                        ] else ...<Widget>[
                          _settingsRow(
                            icon: CupertinoIcons.calendar,
                            iconColor: AppBrand.primary.resolveFrom(context),
                            label: l10n.date,
                            value: _formatDateDisplay(_date),
                            onPressed: _pickDate,
                          ),
                          _rowDivider(),
                          _settingsRow(
                            icon: CupertinoIcons.clock,
                            iconColor: CupertinoColors.activeBlue.resolveFrom(
                              context,
                            ),
                            label: l10n.startTime,
                            value: _formatTimeDisplay(_startTime),
                            onPressed: _pickTime,
                          ),
                          _rowDivider(),
                        ],
                        _settingsRow(
                          icon: CupertinoIcons.timer,
                          iconColor: CupertinoColors.systemOrange.resolveFrom(
                            context,
                          ),
                          label: l10n.duration,
                          value: l10n.minutes(_durationMinutes),
                          onPressed: _pickDuration,
                        ),
                        if (widget.source == LessonSource.journal) ...<Widget>[
                          _rowDivider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _inlineLabel(l10n.status),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child:
                                      CupertinoSlidingSegmentedControl<String>(
                                        groupValue: _status,
                                        children: <String, Widget>{
                                          'scheduled': _segmentLabel(
                                            l10n.scheduled,
                                          ),
                                          'completed': _segmentLabel(
                                            l10n.completed,
                                          ),
                                          'cancelled': _segmentLabel(
                                            l10n.cancelled,
                                          ),
                                        },
                                        onValueChanged: (String? value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setState(() {
                                            _status = value;
                                          });
                                        },
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!widget.isEditing &&
                            widget.source == LessonSource.journal) ...<Widget>[
                          _rowDivider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                            child: Column(
                              children: <Widget>[
                                _switchRow(
                                  label: l10n.repeatWeekly,
                                  value: _repeatWeekly,
                                  onChanged: (bool value) {
                                    setState(() {
                                      _repeatWeekly = value;
                                    });
                                  },
                                ),
                                if (_repeatWeekly) ...<Widget>[
                                  const SizedBox(height: 8),
                                  _settingsRow(
                                    icon: CupertinoIcons.repeat,
                                    iconColor: CupertinoColors.systemPurple
                                        .resolveFrom(context),
                                    label: l10n.repeatWeeksLabel,
                                    value: l10n.weeksCount(_repeatWeeks),
                                    onPressed: _pickRepeatWeeks,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.lessonFee),
                  AppGlassCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _inlineLabel(l10n.titleOptional),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _titleController,
                          placeholder: l10n.titleOptional,
                        ),
                        const SizedBox(height: 14),
                        _switchRow(
                          label: l10n.freeLesson,
                          value: _isFree,
                          onChanged: (bool value) {
                            setState(() {
                              _isFree = value;
                            });
                          },
                        ),
                        if (!_isFree) ...<Widget>[
                          const SizedBox(height: 14),
                          _inlineLabel(l10n.price),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _priceController,
                            placeholder: l10n.eg500,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            suffix: Text(
                              context.currencyLabel(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel(l10n.notes),
                  AppGlassCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_isGroup) ...<Widget>[
                          _inlineLabel(l10n.studentNotes),
                          const SizedBox(height: 8),
                          if (_groupMembers.isEmpty)
                            Text(
                              l10n.noGroupMembers,
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                                fontSize: 13,
                              ),
                            )
                          else
                            ..._groupMembers.map(_studentNoteField),
                          const SizedBox(height: 14),
                          _inlineLabel(l10n.notes),
                          const SizedBox(height: 8),
                        ],
                        _textField(
                          controller: _notesController,
                          placeholder: l10n.optionalNotes,
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                  if (widget.isEditing &&
                      widget.source == LessonSource.schedule) ...<Widget>[
                    const SizedBox(height: 22),
                    _filledAction(
                      label: l10n.markLessonDone,
                      icon: CupertinoIcons.checkmark_circle_fill,
                      onPressed: _isSubmitting ? null : _markLessonDone,
                    ),
                  ],
                  if (widget.isEditing) ...<Widget>[
                    const SizedBox(height: 12),
                    _destructiveAction(
                      label: l10n.deleteLesson,
                      onPressed: _isSubmitting ? null : _confirmDelete,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _inlineLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );
  }

  Widget _segmentLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  Widget _typeToggle(AppLocalizations l10n) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _typeChip(
            selected: !_isGroup,
            icon: CupertinoIcons.person_fill,
            label: l10n.student,
            onTap: () {
              if (!_isGroup) {
                return;
              }
              setState(() {
                _isGroup = false;
                _fillDefaultPrice(force: true);
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _typeChip(
            selected: _isGroup,
            icon: CupertinoIcons.person_2_fill,
            label: l10n.group,
            onTap: () {
              if (_isGroup) {
                return;
              }
              setState(() {
                _isGroup = true;
                _fillDefaultPrice(force: true);
              });
              if (_selectedGroup != null) {
                _loadGroupMembersAndNotes(_selectedGroup);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _typeChip({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final Color selectedColor = AppBrand.primary.resolveFrom(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.16)
              : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
                  context,
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? selectedColor.withValues(alpha: 0.45)
                : CupertinoColors.separator
                      .resolveFrom(context)
                      .withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: selected
                  ? selectedColor
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected
                    ? selectedColor
                    : CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personPicker(AppLocalizations l10n) {
    final String name = _isGroup
        ? (_selectedGroup?.name ?? l10n.selectGroup)
        : (_selectedStudent?.name ?? l10n.selectStudent);
    final Color accent = _parseHexColor(
      _isGroup ? _selectedGroup?.color : _selectedStudent?.color,
    );
    final bool enabled = _isGroup ? _groups.isNotEmpty : _students.isNotEmpty;
    final String? pictureUrl = _isGroup
        ? null
        : _selectedStudent?.profilePictureUrl;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: enabled ? (_isGroup ? _pickGroup : _pickStudent) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            _avatar(name: name, color: accent, pictureUrl: pictureUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isGroup ? l10n.group : l10n.student,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar({
    required String name,
    required Color color,
    String? pictureUrl,
  }) {
    final bool hasPhoto = pictureUrl != null && pictureUrl.isNotEmpty;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(pictureUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              _initials(name),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
    );
  }

  Widget _slotBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppBrand.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppBrand.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.calendar_today,
              size: 18,
              color: AppBrand.primary.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.selectedSlot(
                _formatDateDisplay(_date),
                _formatTimeDisplay(_startTime),
              ),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback? onPressed,
  }) {
    final Color muted = CupertinoColors.secondaryLabel.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
            if (onPressed != null) ...<Widget>[
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rowDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator
            .resolveFrom(context)
            .withValues(alpha: 0.45),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
    Widget? suffix,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: CupertinoColors.label.resolveFrom(context),
      ),
      placeholderStyle: TextStyle(
        color: CupertinoColors.placeholderText.resolveFrom(context),
      ),
      suffix: suffix == null
          ? null
          : Padding(padding: const EdgeInsets.only(right: 12), child: suffix),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _studentNoteField(Student member) {
    final TextEditingController controller = _studentNoteControllers
        .putIfAbsent(member.id, TextEditingController.new);
    final Color accent = _parseHexColor(member.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CupertinoTextField(
        controller: controller,
        placeholder: context.l10n.studentNotePlaceholder(member.name),
        minLines: 1,
        maxLines: 3,
        padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.label.resolveFrom(context),
        ),
        placeholderStyle: TextStyle(
          color: CupertinoColors.placeholderText.resolveFrom(context),
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 6, right: 8),
          child: _avatar(name: member.name, color: accent),
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _filledAction({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppBrand.primary.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 18, color: CupertinoColors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destructiveAction({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: CupertinoColors.systemRed.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              CupertinoIcons.trash,
              size: 18,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return AppBrand.primary.resolveFrom(context);
    }
    final String value = hex.replaceAll('#', '').trim();
    if (value.length != 6) {
      return AppBrand.primary.resolveFrom(context);
    }
    final int? rgb = int.tryParse(value, radix: 16);
    if (rgb == null) {
      return AppBrand.primary.resolveFrom(context);
    }
    return Color.fromARGB(
      255,
      (rgb >> 16) & 0xFF,
      (rgb >> 8) & 0xFF,
      rgb & 0xFF,
    );
  }

  Future<void> _pickStudent() async {
    await showAppActionSheet<void>(
      context: context,
      title: context.l10n.selectStudentTitle,
      actions: _students.map((Student student) {
        return AppSheetAction(
          label: student.name,
          onPressed: (BuildContext ctx) {
            setState(() {
              _selectedStudent = student;
              _fillDefaultPrice(force: true);
            });
            Navigator.of(ctx).pop();
          },
        );
      }).toList(),
    );
  }

  Future<void> _pickGroup() async {
    await showAppActionSheet<void>(
      context: context,
      title: context.l10n.selectGroupTitle,
      actions: _groups.map((TutorGroup group) {
        return AppSheetAction(
          label: group.name,
          onPressed: (BuildContext ctx) {
            setState(() {
              _selectedGroup = group;
              _fillDefaultPrice(force: true);
            });
            Navigator.of(ctx).pop();
            _loadGroupMembersAndNotes(group);
          },
        );
      }).toList(),
    );
  }

  Future<void> _pickDuration() async {
    const int minMinutes = 5;
    const int maxMinutes = 240;
    const int step = 5;
    final List<int> options = List<int>.generate(
      ((maxMinutes - minMinutes) ~/ step) + 1,
      (int i) => minMinutes + i * step,
    );
    int selectedIndex = options.indexOf(_durationMinutes);
    if (selectedIndex < 0) {
      selectedIndex = options.indexOf(60);
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return _pickerSheet(
          context: context,
          onCancel: () => Navigator.of(context).pop(),
          onDone: () {
            setState(() {
              _durationMinutes = options[selectedIndex];
            });
            Navigator.of(context).pop();
          },
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: selectedIndex,
            ),
            itemExtent: 36,
            onSelectedItemChanged: (int index) {
              selectedIndex = index;
            },
            children: options
                .map(
                  (int minutes) =>
                      Center(child: Text(context.l10n.minutes(minutes))),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _pickRepeatWeeks() async {
    const int minWeeks = 2;
    const int maxWeeks = 52;
    final List<int> options = List<int>.generate(
      maxWeeks - minWeeks + 1,
      (int i) => minWeeks + i,
    );
    int selectedIndex = options.indexOf(_repeatWeeks);
    if (selectedIndex < 0) {
      selectedIndex = options.indexOf(8);
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return _pickerSheet(
          context: context,
          onCancel: () => Navigator.of(context).pop(),
          onDone: () {
            setState(() {
              _repeatWeeks = options[selectedIndex];
            });
            Navigator.of(context).pop();
          },
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: selectedIndex,
            ),
            itemExtent: 36,
            onSelectedItemChanged: (int index) {
              selectedIndex = index;
            },
            children: options
                .map(
                  (int weeks) =>
                      Center(child: Text(context.l10n.weeksCount(weeks))),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    DateTime temp = _date;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return _pickerSheet(
          context: context,
          onCancel: () => Navigator.of(context).pop(),
          onDone: () {
            setState(() {
              _date = temp;
            });
            Navigator.of(context).pop();
          },
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _date,
            onDateTimeChanged: (DateTime value) {
              temp = value;
            },
          ),
        );
      },
    );
  }

  Future<void> _pickTime() async {
    DateTime temp = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.inHours,
      _startTime.inMinutes % 60,
    );
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return _pickerSheet(
          context: context,
          onCancel: () => Navigator.of(context).pop(),
          onDone: () {
            setState(() {
              _startTime = Duration(hours: temp.hour, minutes: temp.minute);
            });
            Navigator.of(context).pop();
          },
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: true,
            minuteInterval: 5,
            initialDateTime: temp,
            onDateTimeChanged: (DateTime value) {
              temp = value;
            },
          ),
        );
      },
    );
  }

  Widget _pickerSheet({
    required BuildContext context,
    required VoidCallback onCancel,
    required VoidCallback onDone,
    required Widget child,
  }) {
    final AppLocalizations l10n = context.l10n;
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: Size.zero,
                      onPressed: onCancel,
                      child: Text(l10n.cancel),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: Size.zero,
                      onPressed: onDone,
                      child: Text(
                        l10n.done,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isGroup && _selectedGroup == null) {
      await _showMessage(context.l10n.selectAGroup);
      return;
    }
    if (!_isGroup && _selectedStudent == null) {
      await _showMessage(context.l10n.selectAStudent);
      return;
    }

    String? price;
    if (!_isFree) {
      final String raw = _priceController.text.trim();
      if (raw.isNotEmpty) {
        final num? parsed = num.tryParse(raw.replaceAll(',', '.'));
        if (parsed == null || parsed < 0) {
          await _showMessage(context.l10n.enterValidPrice);
          return;
        }
        price = raw.replaceAll(',', '.');
      }
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      final Lesson? existing = widget.lesson;
      late final Lesson saved;
      if (existing != null) {
        saved = await _lessonService.updateLesson(
          id: existing.id,
          body: <String, dynamic>{
            'date': _formatDate(_date),
            'start_at': _formatTime(_startTime),
            'duration_minutes': _durationMinutes,
            'student_id': _isGroup ? null : _selectedStudent?.id,
            'group_id': _isGroup ? _selectedGroup?.id : null,
            'title': _titleController.text.trim(),
            'is_free': _isFree,
            if (!_isFree && price != null) 'price': price,
            'notes': _notesController.text.trim(),
            if (widget.source == LessonSource.journal) 'status': _status,
          },
        );
      } else {
        saved = await _lessonService.createLesson(
          LessonCreateRequest(
            date: _formatDate(_date),
            startAt: _formatTime(_startTime),
            durationMinutes: _durationMinutes,
            studentId: _isGroup ? null : _selectedStudent?.id,
            groupId: _isGroup ? _selectedGroup?.id : null,
            title: _titleController.text.trim(),
            isFree: _isFree,
            price: price,
            notes: _notesController.text.trim(),
            source: widget.source,
            status: widget.source == LessonSource.journal
                ? _status
                : 'scheduled',
            paymentStatus: _isFree ? null : 'unpaid',
          ),
        );
      }
      if (_isGroup) {
        await _persistStudentNotes(saved.id);
      }

      int repeatsCreated = 0;
      String? repeatError;
      if (existing == null && _repeatWeekly && _repeatWeeks > 1) {
        for (int i = 1; i < _repeatWeeks; i++) {
          try {
            final DateTime repeatDate = _date.add(Duration(days: 7 * i));
            final Lesson repeatLesson = await _lessonService.createLesson(
              LessonCreateRequest(
                date: _formatDate(repeatDate),
                startAt: _formatTime(_startTime),
                durationMinutes: _durationMinutes,
                studentId: _isGroup ? null : _selectedStudent?.id,
                groupId: _isGroup ? _selectedGroup?.id : null,
                title: _titleController.text.trim(),
                isFree: _isFree,
                price: price,
                notes: _notesController.text.trim(),
                source: widget.source,
                status: 'scheduled',
                paymentStatus: _isFree ? null : 'unpaid',
              ),
            );
            if (_isGroup) {
              await _createStudentNotesForRepeat(repeatLesson.id);
            }
            repeatsCreated++;
          } on LessonServiceException catch (error) {
            repeatError = error.message;
            break;
          }
        }
      }

      if (!mounted) {
        return;
      }
      if (repeatError != null) {
        await _showMessage(
          context.l10n.repeatLessonsPartial(
            repeatsCreated + 1,
            _repeatWeeks,
            repeatError,
          ),
        );
        if (!mounted) {
          return;
        }
      }
      Navigator.of(context).pop(true);
    } on LessonServiceException catch (error) {
      if (error.isQuota) {
        await openPaywall(context, token: widget.token, reasonCode: error.code);
      } else {
        await _showMessage(error.message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _persistStudentNotes(int lessonId) async {
    for (final MapEntry<int, TextEditingController> entry
        in _studentNoteControllers.entries) {
      final String text = entry.value.text.trim();
      final bool exists = _existingStudentNoteIds.contains(entry.key);
      if (text.isEmpty) {
        if (exists) {
          await _lessonService.deleteStudentNote(
            lessonId: lessonId,
            studentId: entry.key,
          );
          _existingStudentNoteIds.remove(entry.key);
        }
        continue;
      }
      await _lessonService.upsertStudentNote(
        lessonId: lessonId,
        studentId: entry.key,
        notes: text,
        alreadyExists: exists,
      );
      _existingStudentNoteIds.add(entry.key);
    }
  }

  /// Copies the group student notes onto a lesson created by the weekly
  /// repeat flow. Unlike [_persistStudentNotes], this always creates fresh
  /// notes since each repeated lesson is a brand-new record.
  Future<void> _createStudentNotesForRepeat(int lessonId) async {
    for (final MapEntry<int, TextEditingController> entry
        in _studentNoteControllers.entries) {
      final String text = entry.value.text.trim();
      if (text.isEmpty) {
        continue;
      }
      try {
        await _lessonService.createStudentNote(
          lessonId: lessonId,
          studentId: entry.key,
          notes: text,
        );
      } on LessonServiceException {
        // Ignore note failures for repeat instances; the lesson itself
        // was already created successfully.
      }
    }
  }

  Future<void> _markLessonDone() async {
    final Lesson? existing = widget.lesson;
    if (existing == null) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    String paymentChoice = 'unpaid';
    if (!_isFree) {
      final String? picked = await showAppActionSheet<String>(
        context: context,
        title: l10n.settlePaymentTitle,
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

    setState(() {
      _isSubmitting = true;
    });
    try {
      if (_isGroup) {
        await _persistStudentNotes(existing.id);
      }
      await _lessonService.completeFromSchedule(existing.id);
      if (paymentChoice != 'unpaid' && !_isFree) {
        await _paymentService.markLessonPayment(
          lessonId: existing.id,
          request: LessonPaymentRequest(paymentStatus: paymentChoice),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on LessonServiceException catch (error) {
      await _showMessage(error.message);
    } on PaymentServiceException catch (error) {
      await _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final Lesson? existing = widget.lesson;
    if (existing == null) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showAppAlert<bool>(
      context: context,
      title: l10n.deleteLesson,
      message: l10n.deleteLessonConfirmShort,
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
    setState(() {
      _isSubmitting = true;
    });
    try {
      await _lessonService.deleteLesson(existing.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on LessonServiceException catch (error) {
      await _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showMessage(String message) {
    return showAppAlert<void>(
      context: context,
      title: _pageTitle,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _formatDateDisplay(DateTime date) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    return intl.DateFormat.yMMMEd(locale).format(date);
  }

  String _formatTime(Duration time) {
    final String h = time.inHours.toString().padLeft(2, '0');
    final String m = (time.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _formatTimeDisplay(Duration time) {
    final String h = time.inHours.toString().padLeft(2, '0');
    final String m = (time.inMinutes % 60).toString().padLeft(2, '0');
    return '$h.$m';
  }
}
