import 'package:flutter/cupertino.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/payments/payment_service.dart';
import 'package:tutor_app/students/student_service.dart';

class CreatePaymentPage extends StatefulWidget {
  const CreatePaymentPage({
    required this.paymentService,
    required this.studentService,
    required this.lessonService,
    super.key,
  });

  final PaymentService paymentService;
  final StudentService studentService;
  final LessonService lessonService;

  @override
  State<CreatePaymentPage> createState() => _CreatePaymentPageState();
}

class _CreatePaymentPageState extends State<CreatePaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _kind = PaymentKind.lesson;
  String _method = PaymentMethod.cash;
  Student? _selectedStudent;
  Lesson? _selectedLesson;
  List<Student> _students = <Student>[];
  List<Lesson> _lessons = <Lesson>[];
  bool _applyToLesson = true;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    List<Student> students = <Student>[];
    List<Lesson> lessons = <Lesson>[];

    try {
      students = await widget.studentService.listStudents();
    } on StudentServiceException {
      // Form can still open.
    }

    try {
      final DateTime now = DateTime.now();
      final DateTime from = now.subtract(const Duration(days: 120));
      final DateTime to = now.add(const Duration(days: 30));
      lessons = await widget.lessonService.listLessons(
        startDate: _ymd(from),
        endDate: _ymd(to),
        source: LessonSource.journal,
        sortBy: 'date',
        sortDirection: 'desc',
      );
      lessons = lessons
          .where((Lesson lesson) => lesson.status != 'cancelled')
          .toList();
    } on LessonServiceException {
      // Form can still open.
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _students = students;
      _lessons = lessons;
      if (students.isNotEmpty && _selectedStudent == null) {
        _selectedStudent = students.first;
      }
      _isLoading = false;
    });
  }

  List<Lesson> get _selectableLessons {
    Iterable<Lesson> lessons = _lessons;
    if (_selectedStudent != null) {
      final int studentId = _selectedStudent!.id;
      final List<Lesson> forStudent = lessons
          .where((Lesson lesson) => lesson.studentId == studentId)
          .toList();
      if (forStudent.isNotEmpty) {
        lessons = forStudent;
      }
    }
    if (_kind == PaymentKind.lesson) {
      final List<Lesson> unpaid = lessons
          .where(
            (Lesson lesson) =>
                lesson.isFree != true &&
                lesson.resolvedPaymentStatus == PaymentStatus.unpaid,
          )
          .toList();
      if (unpaid.isNotEmpty) {
        return unpaid;
      }
    }
    return lessons.toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Record Payment'),
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
                  _sectionTitle('Amount'),
                  CupertinoTextField(
                    controller: _amountController,
                    placeholder: '500',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    padding: const EdgeInsets.all(12),
                    decoration: _fieldDecoration(context),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Kind'),
                  CupertinoSlidingSegmentedControl<String>(
                    groupValue: _kind,
                    children: const <String, Widget>{
                      PaymentKind.lesson: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text('Lesson'),
                      ),
                      PaymentKind.prepaid: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text('Prepaid'),
                      ),
                      PaymentKind.refund: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text('Refund'),
                      ),
                    },
                    onValueChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _kind = value;
                        if (_selectedLesson != null &&
                            !_selectableLessons.contains(_selectedLesson)) {
                          _selectedLesson = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Method'),
                  CupertinoSlidingSegmentedControl<String>(
                    groupValue: _method,
                    children: const <String, Widget>{
                      PaymentMethod.cash: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Text('Cash'),
                      ),
                      PaymentMethod.transfer: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Text('Transfer'),
                      ),
                      PaymentMethod.card: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Text('Card'),
                      ),
                      PaymentMethod.other: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Text('Other'),
                      ),
                    },
                    onValueChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _method = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Student'),
                  if (_students.isEmpty)
                    const Text(
                      'No students available.',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    )
                  else
                    _pickerButton(
                      label: _selectedStudent?.name ?? 'Select student',
                      onPressed: _pickStudent,
                    ),
                  const SizedBox(height: 16),
                  _sectionTitle('Lesson (optional)'),
                  _pickerButton(
                    label: _selectedLesson == null
                        ? 'Select lesson'
                        : _lessonLabel(_selectedLesson!),
                    onPressed: _pickLesson,
                  ),
                  if (_selectedLesson != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text('Apply to lesson status'),
                        ),
                        CupertinoSwitch(
                          value: _applyToLesson,
                          onChanged: (bool value) {
                            setState(() {
                              _applyToLesson = value;
                            });
                          },
                        ),
                      ],
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

  Widget _pickerButton({
    required String label,
    required VoidCallback onPressed,
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
                style: const TextStyle(color: CupertinoColors.label),
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
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

  String _lessonLabel(Lesson lesson) {
    final String who = lesson.displaySubtitle;
    final String price =
        lesson.price != null && lesson.price!.isNotEmpty ? ' · ${lesson.price}' : '';
    return '${lesson.date} ${lesson.startAt} · ${lesson.displayTitle} · $who$price';
  }

  Future<void> _pickStudent() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select Student'),
          actions: _students.map((Student student) {
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedStudent = student;
                  if (_selectedLesson != null &&
                      _selectedLesson!.studentId != null &&
                      _selectedLesson!.studentId != student.id) {
                    _selectedLesson = null;
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text(student.name),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _pickLesson() async {
    final List<Lesson> lessons = _selectableLessons;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Select Lesson'),
          message: lessons.isEmpty
              ? const Text('No lessons found for this filter.')
              : null,
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedLesson = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('No lesson'),
            ),
            ...lessons.map((Lesson lesson) {
              return CupertinoActionSheetAction(
                onPressed: () {
                  _applyLessonSelection(lesson);
                  Navigator.of(context).pop();
                },
                child: Text(
                  _lessonLabel(lesson),
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _applyLessonSelection(Lesson lesson) {
    setState(() {
      _selectedLesson = lesson;
      _applyToLesson = true;

      if (lesson.studentId != null) {
        final Student match = _students.firstWhere(
          (Student s) => s.id == lesson.studentId,
          orElse: () => Student(
            id: lesson.studentId!,
            name: lesson.student?.name ?? 'Student',
          ),
        );
        _selectedStudent = match;
      }

      final String? price = lesson.price;
      if (price != null &&
          price.isNotEmpty &&
          _amountController.text.trim().isEmpty) {
        _amountController.text = price;
      }
    });
  }

  Future<void> _submit() async {
    final String amountText = _amountController.text.trim();
    final num? amount = num.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      await _showMessage('Enter a valid amount.');
      return;
    }
    if (_selectedStudent == null && _selectedLesson == null) {
      await _showMessage('Select a student or lesson.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      await widget.paymentService.createPayment(
        PaymentCreateRequest(
          amount: amount,
          kind: _kind,
          studentId: _selectedStudent?.id ?? _selectedLesson?.studentId,
          groupId: _selectedLesson?.groupId,
          lessonId: _selectedLesson?.id,
          method: _method,
          notes: _notesController.text.trim(),
          applyToLesson: _selectedLesson != null && _applyToLesson,
          paidAt: DateTime.now().toIso8601String(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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

  Future<void> _showMessage(String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Payment'),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _ymd(DateTime date) {
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
