import 'package:flutter/cupertino.dart';
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
      final List<GroupStudent> rows =
          await _groupService.listGroupStudents(group.id);
      members = rows.map((GroupStudent row) => row.student).toList();
    } on GroupServiceException {
      members = <Student>[];
    }

    final Map<int, String> existingNotes = <int, String>{};
    final Lesson? lesson = widget.lesson;
    if (lesson != null && lesson.isGroup) {
      try {
        final List<LessonStudentNote> notes =
            await _lessonService.listStudentNotes(lesson.id);
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
        if (students.isNotEmpty) {
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
              : Text(l10n.save),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _sectionTitle(l10n.target),
                  CupertinoSlidingSegmentedControl<bool>(
                    groupValue: _isGroup,
                    children: <bool, Widget>{
                      false: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(l10n.student),
                      ),
                      true: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(l10n.group),
                      ),
                    },
                    onValueChanged: (bool? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _isGroup = value;
                        _fillDefaultPrice(force: true);
                      });
                      if (value && _selectedGroup != null) {
                        _loadGroupMembersAndNotes(_selectedGroup);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_isGroup)
                    _pickerButton(
                      label: _selectedGroup?.name ?? l10n.selectGroup,
                      onPressed: _groups.isEmpty ? null : _pickGroup,
                    )
                  else
                    _pickerButton(
                      label: _selectedStudent?.name ?? l10n.selectStudent,
                      onPressed: _students.isEmpty ? null : _pickStudent,
                    ),
                  const SizedBox(height: 16),
                  if (widget.lockDateTime && !widget.isEditing) ...<Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppBrand.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppBrand.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            CupertinoIcons.calendar,
                            size: 18,
                            color: AppBrand.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.selectedSlot(
                                _formatDate(_date),
                                _formatTimeDisplay(_startTime),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...<Widget>[
                    _sectionTitle(l10n.date),
                    _pickerButton(
                      label: _formatDate(_date),
                      onPressed: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(l10n.startTime),
                  _pickerButton(
                    label: _formatTimeDisplay(_startTime),
                    onPressed: _pickTime,
                  ),
                  ],
                  const SizedBox(height: 16),
                  _sectionTitle(l10n.duration),
                  _pickerButton(
                    label: l10n.minutes(_durationMinutes),
                    onPressed: _pickDuration,
                  ),
                  if (widget.source == LessonSource.journal) ...<Widget>[
                    const SizedBox(height: 16),
                    _sectionTitle(l10n.status),
                    CupertinoSlidingSegmentedControl<String>(
                      groupValue: _status,
                      children: <String, Widget>{
                        'scheduled': Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Text(l10n.scheduled),
                        ),
                        'completed': Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Text(l10n.completed),
                        ),
                        'cancelled': Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Text(l10n.cancelled),
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
                  ],
                  const SizedBox(height: 16),
                  _sectionTitle(l10n.titleOptional),
                  CupertinoTextField(
                    controller: _titleController,
                    padding: const EdgeInsets.all(12),
                    style: _fieldTextStyle,
                    placeholderStyle: _fieldPlaceholderStyle,
                    decoration: _fieldDecoration(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(child: Text(l10n.freeLesson)),
                      CupertinoSwitch(
                        value: _isFree,
                        onChanged: (bool value) {
                          setState(() {
                            _isFree = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (!_isFree) ...<Widget>[
                    const SizedBox(height: 12),
                    _sectionTitle(l10n.price),
                    CupertinoTextField(
                      controller: _priceController,
                      placeholder: '500',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      padding: const EdgeInsets.all(12),
                      style: _fieldTextStyle,
                      placeholderStyle: _fieldPlaceholderStyle,
                      decoration: _fieldDecoration(context),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_isGroup) ...<Widget>[
                    _sectionTitle(l10n.studentNotes),
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
                      ..._groupMembers.map((Student member) {
                        final TextEditingController controller =
                            _studentNoteControllers.putIfAbsent(
                          member.id,
                          TextEditingController.new,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CupertinoTextField(
                            controller: controller,
                            placeholder:
                                l10n.studentNotePlaceholder(member.name),
                            minLines: 1,
                            maxLines: 3,
                            padding: const EdgeInsets.all(12),
                            style: _fieldTextStyle,
                            placeholderStyle: _fieldPlaceholderStyle,
                            decoration: _fieldDecoration(context),
                            prefix: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                member.name.split(' ').first,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    _sectionTitle(l10n.notes),
                    CupertinoTextField(
                      controller: _notesController,
                      placeholder: l10n.optionalNotes,
                      minLines: 2,
                      maxLines: 4,
                      padding: const EdgeInsets.all(12),
                      style: _fieldTextStyle,
                      placeholderStyle: _fieldPlaceholderStyle,
                      decoration: _fieldDecoration(context),
                    ),
                  ] else ...<Widget>[
                    _sectionTitle(l10n.notes),
                    CupertinoTextField(
                      controller: _notesController,
                      placeholder: l10n.optionalNotes,
                      minLines: 2,
                      maxLines: 4,
                      padding: const EdgeInsets.all(12),
                      style: _fieldTextStyle,
                      placeholderStyle: _fieldPlaceholderStyle,
                      decoration: _fieldDecoration(context),
                    ),
                  ],
                  if (widget.isEditing &&
                      widget.source == LessonSource.schedule) ...<Widget>[
                    const SizedBox(height: 20),
                    CupertinoButton.filled(
                      onPressed: _isSubmitting ? null : _markLessonDone,
                      child: Text(l10n.markLessonDone),
                    ),
                  ],
                  if (widget.isEditing) ...<Widget>[
                    const SizedBox(height: 12),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: _isSubmitting ? null : _confirmDelete,
                      child: Text(
                        l10n.deleteLesson,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _pickerButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    final Color muted =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    final Color labelColor = CupertinoColors.label.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _fieldDecoration(context),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: onPressed == null ? muted : labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: muted,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration(BuildContext context) {
    return BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: CupertinoColors.separator
            .resolveFrom(context)
            .withValues(alpha: 0.35),
      ),
    );
  }

  TextStyle get _fieldTextStyle => TextStyle(
        color: CupertinoColors.label.resolveFrom(context),
        fontWeight: FontWeight.w500,
      );

  TextStyle get _fieldPlaceholderStyle => TextStyle(
        color: CupertinoColors.placeholderText.resolveFrom(context),
      );

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
              _startTime = Duration(
                hours: temp.hour,
                minutes: temp.minute,
              );
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
      color: CupertinoColors.systemBackground.resolveFrom(context),
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
            status: widget.source == LessonSource.journal ? _status : 'scheduled',
            paymentStatus: _isFree ? null : 'unpaid',
          ),
        );
      }
      if (_isGroup) {
        await _persistStudentNotes(saved.id);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on LessonServiceException catch (error) {
      if (error.isQuota) {
        await openPaywall(
          context,
          token: widget.token,
          reasonCode: error.code,
        );
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
