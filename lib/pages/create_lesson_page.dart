import 'package:flutter/cupertino.dart';
import 'package:tutor_app/groups/group_service.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/students/student_service.dart';
import 'package:tutor_app/theme/app_dialogs.dart';

class CreateLessonPage extends StatefulWidget {
  const CreateLessonPage({
    required this.token,
    required this.source,
    this.initialDate,
    this.initialStartAt,
    super.key,
  });

  final String token;
  final String source;
  final DateTime? initialDate;
  final String? initialStartAt;

  @override
  State<CreateLessonPage> createState() => _CreateLessonPageState();
}

class _CreateLessonPageState extends State<CreateLessonPage> {
  late final LessonService _lessonService;
  late final StudentService _studentService;
  late final GroupService _groupService;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

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
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService(token: widget.token);
    _studentService = StudentService(token: widget.token);
    _groupService = GroupService(token: widget.token);

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
    _loadLookups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    List<Student> students = <Student>[];
    List<TutorGroup> groups = <TutorGroup>[];
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
      _students = students;
      _groups = groups;
      if (students.isNotEmpty) {
        _selectedStudent = students.first;
      }
      if (groups.isNotEmpty) {
        _selectedGroup = groups.first;
      }
      _isLoading = false;
    });
  }

  String get _pageTitle =>
      widget.source == LessonSource.schedule ? 'Add Schedule' : 'Add Lesson';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_pageTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const CupertinoActivityIndicator()
              : const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _sectionTitle('Target'),
                  CupertinoSlidingSegmentedControl<bool>(
                    groupValue: _isGroup,
                    children: const <bool, Widget>{
                      false: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text('Student'),
                      ),
                      true: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text('Group'),
                      ),
                    },
                    onValueChanged: (bool? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _isGroup = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_isGroup)
                    _pickerButton(
                      label: _selectedGroup?.name ?? 'Select group',
                      onPressed: _groups.isEmpty ? null : _pickGroup,
                    )
                  else
                    _pickerButton(
                      label: _selectedStudent?.name ?? 'Select student',
                      onPressed: _students.isEmpty ? null : _pickStudent,
                    ),
                  const SizedBox(height: 16),
                  _sectionTitle('Date'),
                  _pickerButton(
                    label: _formatDate(_date),
                    onPressed: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Start time'),
                  _pickerButton(
                    label: _formatTime(_startTime),
                    onPressed: _pickTime,
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Duration'),
                  _pickerButton(
                    label: '$_durationMinutes min',
                    onPressed: _pickDuration,
                  ),
                  if (widget.source == LessonSource.journal) ...<Widget>[
                    const SizedBox(height: 16),
                    _sectionTitle('Status'),
                    CupertinoSlidingSegmentedControl<String>(
                      groupValue: _status,
                      children: const <String, Widget>{
                        'scheduled': Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Text('Scheduled'),
                        ),
                        'completed': Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Text('Completed'),
                        ),
                        'cancelled': Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Text('Cancelled'),
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
                  _sectionTitle('Title (optional)'),
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: 'Math tutoring',
                    padding: const EdgeInsets.all(12),
                    decoration: _fieldDecoration(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('Free lesson')),
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
                    _sectionTitle('Price'),
                    CupertinoTextField(
                      controller: _priceController,
                      placeholder: '500',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      padding: const EdgeInsets.all(12),
                      decoration: _fieldDecoration(context),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _sectionTitle('Notes'),
                  CupertinoTextField(
                    controller: _notesController,
                    placeholder: 'Optional notes',
                    minLines: 2,
                    maxLines: 4,
                    padding: const EdgeInsets.all(12),
                    decoration: _fieldDecoration(context),
                  ),
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
                  color: onPressed == null
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.label,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration(BuildContext context) {
    return BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground
          .resolveFrom(context),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: CupertinoColors.systemGrey4),
    );
  }

  Future<void> _pickStudent() async {
    await showAppActionSheet<void>(
      context: context,
      title: 'Select Student',
      actions: _students.map((Student student) {
        return AppSheetAction(
          label: student.name,
          onPressed: (BuildContext ctx) {
            setState(() {
              _selectedStudent = student;
              if (student.lessonCost != null &&
                  student.lessonCost!.isNotEmpty &&
                  _priceController.text.trim().isEmpty) {
                _priceController.text = student.lessonCost!;
              }
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
      title: 'Select Group',
      actions: _groups.map((TutorGroup group) {
        return AppSheetAction(
          label: group.name,
          onPressed: (BuildContext ctx) {
            setState(() {
              _selectedGroup = group;
            });
            Navigator.of(ctx).pop();
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
        return Container(
          height: 280,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _durationMinutes = options[selectedIndex];
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedIndex,
                  ),
                  itemExtent: 36,
                  onSelectedItemChanged: (int index) {
                    selectedIndex = index;
                  },
                  children: options
                      .map((int minutes) => Center(child: Text('$minutes min')))
                      .toList(),
                ),
              ),
            ],
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
        return Container(
          height: 280,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _date = temp;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _date,
                  onDateTimeChanged: (DateTime value) {
                    temp = value;
                  },
                ),
              ),
            ],
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
        return Container(
          height: 280,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _startTime = Duration(
                            hours: temp.hour,
                            minutes: temp.minute,
                          );
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  minuteInterval: 5,
                  initialDateTime: temp,
                  onDateTimeChanged: (DateTime value) {
                    temp = value;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_isGroup && _selectedGroup == null) {
      await _showMessage('Select a group.');
      return;
    }
    if (!_isGroup && _selectedStudent == null) {
      await _showMessage('Select a student.');
      return;
    }

    String? price;
    if (!_isFree) {
      final String raw = _priceController.text.trim();
      if (raw.isNotEmpty) {
        final num? parsed = num.tryParse(raw.replaceAll(',', '.'));
        if (parsed == null || parsed < 0) {
          await _showMessage('Enter a valid price.');
          return;
        }
        price = raw.replaceAll(',', '.');
      }
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      await _lessonService.createLesson(
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
      actions: const <AppAlertAction>[
        AppAlertAction(label: 'OK', style: AppAlertStyle.primary),
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
}
