import 'package:flutter/cupertino.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/lesson_calendar_picker_page.dart';
import 'package:tutor_app/payments/payment_service.dart';
import 'package:tutor_app/students/student_service.dart';
import 'package:tutor_app/theme/app_dialogs.dart';

class CreatePaymentPage extends StatefulWidget {
  const CreatePaymentPage({
    required this.paymentService,
    required this.studentService,
    required this.lessonService,
    this.initialStudent,
    this.lockStudent = false,
    this.initialKind,
    super.key,
  });

  final PaymentService paymentService;
  final StudentService studentService;
  final LessonService lessonService;

  /// When set, this student is pre-selected after load.
  final Student? initialStudent;

  /// When true (and [initialStudent] is set), student cannot be changed.
  final bool lockStudent;

  /// Prefill payment kind (e.g. prepaid for package load).
  final String? initialKind;

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
  bool _applyToLesson = true;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final String? initialKind = widget.initialKind;
    if (initialKind != null && initialKind.isNotEmpty) {
      _kind = initialKind;
    }
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

    try {
      students = await widget.studentService.listStudents();
    } on StudentServiceException {
      // Form can still open.
    }

    if (!mounted) {
      return;
    }

    Student? selected = widget.initialStudent;
    if (selected != null) {
      final int id = selected.id;
      final bool inList = students.any((Student s) => s.id == id);
      if (!inList) {
        students = <Student>[selected, ...students];
      } else {
        selected = students.firstWhere((Student s) => s.id == id);
      }
    } else if (students.isNotEmpty) {
      selected = students.first;
    }

    setState(() {
      _students = students;
      _selectedStudent = selected;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.recordPaymentTitle),
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
                  if (_kind == PaymentKind.prepaid) ...<Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemPurple.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.loadPackageHint,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle(
                    _kind == PaymentKind.prepaid
                        ? l10n.loadPackage
                        : l10n.amount,
                  ),
                  CupertinoTextField(
                    controller: _amountController,
                    placeholder: '500',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: _fieldDecoration(context),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle(l10n.kind),
                  CupertinoSlidingSegmentedControl<String>(
                    groupValue: _kind,
                    children: <String, Widget>{
                      PaymentKind.lesson: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(l10n.kindLesson),
                      ),
                      PaymentKind.prepaid: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(l10n.loadPackage),
                      ),
                      PaymentKind.refund: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(l10n.kindRefund),
                      ),
                    },
                    onValueChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _kind = value;
                        if (value == PaymentKind.prepaid) {
                          _selectedLesson = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle(l10n.method),
                  CupertinoSlidingSegmentedControl<String>(
                    groupValue: _method,
                    children: <String, Widget>{
                      PaymentMethod.cash: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Text(l10n.methodCash),
                      ),
                      PaymentMethod.transfer: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Text(l10n.methodTransfer),
                      ),
                      PaymentMethod.card: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Text(l10n.methodCard),
                      ),
                      PaymentMethod.other: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Text(l10n.methodOther),
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
                  _sectionTitle(l10n.student),
                  if (_students.isEmpty)
                    Text(
                      l10n.noStudentsAvailable,
                      style: const TextStyle(color: CupertinoColors.systemGrey),
                    )
                  else if (widget.lockStudent && widget.initialStudent != null)
                    _lockedField(
                      label:
                          _selectedStudent?.name ?? widget.initialStudent!.name,
                    )
                  else
                    _pickerButton(
                      label: _selectedStudent?.name ?? l10n.selectStudent,
                      onPressed: _pickStudent,
                    ),
                  if (_kind != PaymentKind.prepaid) ...<Widget>[
                    const SizedBox(height: 16),
                    _sectionTitle(l10n.lessonOptional),
                    _pickerButton(
                      label: _selectedLesson == null
                          ? l10n.pickLessonFromCalendar
                          : _lessonLabel(_selectedLesson!),
                      onPressed: _openLessonCalendar,
                      trailing: CupertinoIcons.calendar,
                    ),
                    if (_selectedLesson != null) ...<Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          onPressed: () {
                            setState(() {
                              _selectedLesson = null;
                            });
                          },
                          child: Text(
                            l10n.clearLesson,
                            style: const TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemRed,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(child: Text(l10n.applyToLessonStatus)),
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
                  ],
                  const SizedBox(height: 16),
                  _sectionTitle(l10n.notes),
                  CupertinoTextField(
                    controller: _notesController,
                    placeholder: l10n.optionalNotes,
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
    IconData trailing = CupertinoIcons.chevron_down,
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
            Icon(
              trailing,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockedField({required String label}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _fieldDecoration(context),
      child: Text(label, style: const TextStyle(color: CupertinoColors.label)),
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

  BoxDecoration _fieldDecoration(BuildContext context) {
    return BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: CupertinoColors.systemGrey4),
    );
  }

  String _lessonLabel(Lesson lesson) {
    final String who = lesson.displaySubtitle;
    final String price = lesson.price != null && lesson.price!.isNotEmpty
        ? ' · ${lesson.price}'
        : '';
    return '${lesson.date} ${lesson.startAt} · ${lesson.displayTitle} · $who$price';
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
              if (_selectedLesson != null &&
                  _selectedLesson!.studentId != null &&
                  _selectedLesson!.studentId != student.id) {
                _selectedLesson = null;
              }
            });
            Navigator.of(ctx).pop();
          },
        );
      }).toList(),
    );
  }

  Future<void> _openLessonCalendar() async {
    final Lesson? picked = await Navigator.of(context).push<Lesson>(
      CupertinoPageRoute<Lesson>(
        builder: (BuildContext context) => LessonCalendarPickerPage(
          lessonService: widget.lessonService,
          studentId: _selectedStudent?.id,
          unpaidOnly: _kind == PaymentKind.lesson,
        ),
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    _applyLessonSelection(picked);
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
            name: lesson.student?.name ?? context.l10n.student,
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
      await _showMessage(context.l10n.enterValidAmount);
      return;
    }
    if (_selectedStudent == null && _selectedLesson == null) {
      await _showMessage(context.l10n.selectStudentOrLesson);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      final bool isPackageLoad = _kind == PaymentKind.prepaid;
      await widget.paymentService.createPayment(
        PaymentCreateRequest(
          amount: amount,
          kind: _kind,
          studentId: _selectedStudent?.id ?? _selectedLesson?.studentId,
          groupId: isPackageLoad ? null : _selectedLesson?.groupId,
          lessonId: isPackageLoad ? null : _selectedLesson?.id,
          method: _method,
          notes: _notesController.text.trim(),
          applyToLesson:
              !isPackageLoad && _selectedLesson != null && _applyToLesson,
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
    return showAppAlert<void>(
      context: context,
      title: context.l10n.payment,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }
}
