import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Material, MaterialType;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tutor_app/groups/group_service.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/create_payment_page.dart';
import 'package:tutor_app/pages/group_detail_page.dart';
import 'package:tutor_app/payments/payment_service.dart';
import 'package:tutor_app/students/student_service.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';
import 'package:tutor_app/widgets/birthday_calendar_picker.dart';
import 'package:url_launcher/url_launcher.dart';

enum _StudentsViewMode { students, groups }

enum _StudentDetailTab { info, lessons, payments }

class StudentsPage extends StatefulWidget {
  const StudentsPage({
    required this.token,
    super.key,
  });

  final String token;

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  late final StudentService _studentService;
  late final GroupService _groupService;
  final TextEditingController _searchController = TextEditingController();

  _StudentsViewMode _viewMode = _StudentsViewMode.students;
  List<Student> _students = <Student>[];
  List<TutorGroup> _groups = <TutorGroup>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _studentService = StudentService(token: widget.token);
    _groupService = GroupService(token: widget.token);
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isGroupMode => _viewMode == _StudentsViewMode.groups;

  @override
  Widget build(BuildContext context) {
    final int itemCount = _isGroupMode ? _groups.length : _students.length;
    final String subtitle = _isLoading
        ? 'Loading…'
        : _isGroupMode
            ? '$itemCount group${itemCount == 1 ? '' : 's'}'
            : '$itemCount student${itemCount == 1 ? '' : 's'}';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_isGroupMode ? 'Groups' : 'Students'),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
        border: appNavigationBarBorder,
      ),
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground
                          .resolveFrom(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5.resolveFrom(context),
                      ),
                    ),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: _isGroupMode
                          ? 'Search groups'
                          : 'Search by name or phone',
                      backgroundColor: const Color(0x00000000),
                      borderRadius: BorderRadius.circular(14),
                      onChanged: (_) => _reloadCurrentMode(),
                      onSubmitted: (_) => _reloadCurrentMode(),
                    ),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 14,
              child: _buildModeSwitch(),
            ),
            Positioned(
              right: 16,
              bottom: 14,
              child: _buildAddButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _isGroupMode ? _showCreateGroupSheet : _showCreateStudentSheet,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF5AC8FA),
              CupertinoColors.activeBlue,
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: CupertinoColors.activeBlue.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.add,
          color: CupertinoColors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _modeChip(
            label: 'Students',
            icon: CupertinoIcons.person_2,
            selected: !_isGroupMode,
            onTap: () => _setViewMode(_StudentsViewMode.students),
          ),
          _modeChip(
            label: 'Groups',
            icon: CupertinoIcons.person_3,
            selected: _isGroupMode,
            onTap: () => _setViewMode(_StudentsViewMode.groups),
          ),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? CupertinoColors.activeBlue
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: CupertinoColors.activeBlue.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: selected
                  ? CupertinoColors.white
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? CupertinoColors.white
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMessage != null) {
      return _emptyState(
        icon: CupertinoIcons.exclamationmark_triangle,
        title: 'Something went wrong',
        message: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _reloadCurrentMode,
      );
    }

    if (_isGroupMode) {
      if (_groups.isEmpty) {
        return _emptyState(
          icon: CupertinoIcons.person_3,
          title: 'No groups yet',
          message: 'Create a group to organize students together.',
          actionLabel: 'Add group',
          onAction: _showCreateGroupSheet,
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: _groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final TutorGroup group = _groups[index];
          return _groupTile(group);
        },
      );
    }

    if (_students.isEmpty) {
      return _emptyState(
        icon: CupertinoIcons.person_crop_circle_badge_plus,
        title: 'No students yet',
        message: 'Add your first student to start tracking lessons.',
        actionLabel: 'Add student',
        onAction: _showCreateStudentSheet,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final Student student = _students[index];
        return _studentTile(
          student: student,
          confirmDismiss: () => _confirmDelete(student),
          onDismissed: () {
            setState(() {
              _students =
                  _students.where((Student s) => s.id != student.id).toList();
            });
          },
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 18),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupTile(TutorGroup group) {
    final Color accent = _parseHexColor(group.color);
    return Dismissible(
      key: ValueKey<String>('group-${group.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.resolveFrom(context),
          borderRadius: BorderRadius.circular(AppGlassTokens.radius),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      confirmDismiss: (_) => _confirmDeleteGroup(group),
      onDismissed: (_) {
        setState(() {
          _groups = _groups.where((TutorGroup g) => g.id != group.id).toList();
        });
      },
      child: GestureDetector(
        onTap: () => _openGroupDetailPage(group),
        child: AppGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              _avatarBubble(
                accent: accent,
                label: _initials(group.name),
                icon: CupertinoIcons.person_3_fill,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Group',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentTile({
    required Student student,
    required Future<bool> Function() confirmDismiss,
    required VoidCallback onDismissed,
  }) {
    final Color accent = _parseHexColor(student.color);
    final String? phone = student.phone;
    final String? cost = student.lessonCost;

    return Dismissible(
      key: ValueKey<String>('student-${student.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.resolveFrom(context),
          borderRadius: BorderRadius.circular(AppGlassTokens.radius),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      confirmDismiss: (_) => confirmDismiss(),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: () => _openStudentDetailPage(student.id),
        child: AppGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              _avatarBubble(
                accent: accent,
                label: _initials(student.name),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if ((phone != null && phone.isNotEmpty) ||
                        (cost != null && cost.isNotEmpty)) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        <String>[
                          if (phone != null && phone.isNotEmpty) phone,
                          if (cost != null && cost.isNotEmpty) '$cost / lesson',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarBubble({
    required Color accent,
    required String label,
    IconData? icon,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.28),
            accent.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.85), width: 1.5),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: 20, color: accent)
          : Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.2,
              ),
            ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _setViewMode(_StudentsViewMode mode) async {
    if (_viewMode == mode) {
      return;
    }
    setState(() {
      _viewMode = mode;
      _errorMessage = null;
      _searchController.clear();
    });
    await _reloadCurrentMode();
  }

  Future<void> _reloadCurrentMode() async {
    if (_isGroupMode) {
      await _loadGroups();
    } else {
      await _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<Student> result = await _studentService.listStudents(
        search: _searchController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _students = result;
      });
    } on StudentServiceException catch (error) {
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

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<TutorGroup> groups = await _groupService.listGroups(
        search: _searchController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _groups = groups;
      });
    } on GroupServiceException catch (error) {
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

  Future<void> _showCreateStudentSheet() async {
    final bool? created = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) =>
            _CreateStudentPage(studentService: _studentService),
      ),
    );
    if (created == true) {
      await _loadStudents();
    }
  }

  Future<void> _showCreateGroupSheet() async {
    final bool? created = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) =>
            CreateGroupPage(groupService: _groupService),
      ),
    );
    if (created == true) {
      await _loadGroups();
    }
  }

  Future<void> _openGroupDetailPage(TutorGroup group) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) => GroupDetailPage(
          group: group,
          groupService: _groupService,
          studentService: _studentService,
        ),
      ),
    );
    if (changed == true) {
      await _loadGroups();
    }
  }

  Future<void> _openStudentDetailPage(int studentId) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) => _StudentDetailPage(
          studentId: studentId,
          studentService: _studentService,
        ),
      ),
    );
    if (changed == true) {
      await _reloadCurrentMode();
    }
  }

  Future<bool> _confirmDelete(Student student) async {
    final bool? shouldDelete = await showAppAlert<bool>(
      context: context,
      title: 'Delete Student',
      message:
          'Delete ${student.name}? This will set status to inactive.',
      actions: <AppAlertAction>[
        AppAlertAction(
          label: 'Cancel',
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: 'Delete',
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext ctx) async {
            try {
              await _studentService.deleteStudent(student.id);
              if (ctx.mounted) {
                Navigator.of(ctx).pop(true);
              }
            } on StudentServiceException catch (error) {
              if (mounted) {
                await _showErrorDialog(error.message);
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop(false);
              }
            }
          },
        ),
      ],
    );
    return shouldDelete == true;
  }

  Future<bool> _confirmDeleteGroup(TutorGroup group) async {
    final bool? shouldDelete = await showAppAlert<bool>(
      context: context,
      title: 'Delete Group',
      message: 'Delete ${group.name}? This will set status to inactive.',
      actions: <AppAlertAction>[
        AppAlertAction(
          label: 'Cancel',
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: 'Delete',
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext ctx) async {
            try {
              await _groupService.deleteGroup(group.id);
              if (ctx.mounted) {
                Navigator.of(ctx).pop(true);
              }
            } on GroupServiceException catch (error) {
              if (mounted) {
                await _showErrorDialog(error.message);
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop(false);
              }
            }
          },
        ),
      ],
    );
    return shouldDelete == true;
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
    return Color.fromARGB(255, (rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF);
  }

  Future<void> _showErrorDialog(String message) {
    return showAppAlert<void>(
      context: context,
      title: 'Students',
      message: message,
      actions: const <AppAlertAction>[
        AppAlertAction(label: 'OK', style: AppAlertStyle.primary),
      ],
    );
  }
}

class _StudentDetailPage extends StatefulWidget {
  const _StudentDetailPage({
    required this.studentId,
    required this.studentService,
  });

  final int studentId;
  final StudentService studentService;

  @override
  State<_StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<_StudentDetailPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _lessonCostController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  LessonService get _lessonService =>
      LessonService(token: widget.studentService.token);
  PaymentService get _paymentService =>
      PaymentService(token: widget.studentService.token);

  _StudentDetailTab _tab = _StudentDetailTab.info;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  StudentSummary? _summary;
  StudentBalance? _balance;
  List<Lesson> _completedLessons = <Lesson>[];
  String? _paymentsError;
  String? _lessonsError;
  DateTime? _selectedBirthday;
  String _initialName = '';
  String _initialPhone = '';
  String _initialLessonCost = '';
  String _initialNotes = '';
  String _initialColor = '';
  String _initialBirthday = '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _lessonCostController.dispose();
    _notesController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Student Detail'),
          border: appNavigationBarBorder,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              final bool canLeave = await _handleBackPressed();
              if (!canLeave || !mounted) {
                return;
              }
              Navigator.of(context).pop();
            },
            child: const Text('Back'),
          ),
          trailing: _buildNavTrailing(),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: CupertinoSlidingSegmentedControl<_StudentDetailTab>(
                        groupValue: _tab,
                        children: const <_StudentDetailTab, Widget>{
                          _StudentDetailTab.info: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text('Info'),
                          ),
                          _StudentDetailTab.lessons: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text('Lessons'),
                          ),
                          _StudentDetailTab.payments: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text('Payments'),
                          ),
                        },
                        onValueChanged: (_StudentDetailTab? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _tab = value;
                          });
                        },
                      ),
                    ),
                    Expanded(child: _buildTabBody()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget? _buildNavTrailing() {
    if (_isLoading) {
      return null;
    }
    if (_tab == _StudentDetailTab.payments) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _openAddPayment,
        child: const Text('Add'),
      );
    }
    if (_tab != _StudentDetailTab.info) {
      return null;
    }
    if (_isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CupertinoButton(
            padding: const EdgeInsets.only(right: 8),
            onPressed: _isSaving ? null : _cancelEditing,
            child: const Text('Cancel'),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isSaving
                ? null
                : () async {
                    final bool saved = await _saveChanges();
                    if (saved && mounted) {
                      setState(() {
                        _isEditing = false;
                      });
                    }
                  },
            child: _isSaving
                ? const CupertinoActivityIndicator()
                : const Text('Save'),
          ),
        ],
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        setState(() {
          _isEditing = true;
        });
      },
      child: const Text('Edit'),
    );
  }

  void _cancelEditing() {
    setState(() {
      _nameController.text = _initialName;
      _phoneController.text = _initialPhone;
      _lessonCostController.text = _initialLessonCost;
      _notesController.text = _initialNotes;
      _colorController.text = _initialColor;
      _selectedBirthday = _parseDate(_initialBirthday);
      _isEditing = false;
    });
  }

  Widget _buildTabBody() {
    switch (_tab) {
      case _StudentDetailTab.info:
        return _buildInfoTab();
      case _StudentDetailTab.lessons:
        return _buildLessonsTab();
      case _StudentDetailTab.payments:
        return _buildPaymentsTab();
    }
  }

  Widget _buildInfoTab() {
    final Color accentColor = _parseHexColor(_colorController.text);
    if (!_isEditing) {
      return _buildInfoView(accentColor);
    }
    return _buildInfoEdit(accentColor);
  }

  Widget _buildInfoView(Color accentColor) {
    final String name = _nameController.text.trim().isEmpty
        ? 'Öğrenci'
        : _nameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String cost = _lessonCostController.text.trim();
    final String notes = _notesController.text.trim();
    final String birthday = _formatBirthdayDisplay(_selectedBirthday);
    final bool hasPhone = phone.isNotEmpty;
    final String initials = _studentInitials(name);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: <Widget>[
        AppGlassCard(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            children: <Widget>[
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      accentColor.withValues(alpha: 0.95),
                      accentColor.withValues(alpha: 0.55),
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              if (hasPhone) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (birthday.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D55).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF2D55).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.cake_rounded,
                        size: 16,
                        color: Color(0xFFFF2D55),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        birthday,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF2D55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _heroAction(
                      label: 'Ara',
                      color: CupertinoColors.activeGreen,
                      enabled: hasPhone,
                      onPressed: _callStudent,
                      child: const Icon(
                        CupertinoIcons.phone_fill,
                        size: 18,
                        color: CupertinoColors.activeGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _heroAction(
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      enabled: hasPhone,
                      onPressed: _openWhatsApp,
                      child: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        size: 16,
                        color: Color(0xFF25D366),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _metricGlanceCard(
          label: 'Ders ücreti',
          value: cost.isEmpty ? '—' : cost,
          subtitle: cost.isEmpty ? 'Belirtilmedi' : 'ders başı',
          icon: CupertinoIcons.money_dollar_circle_fill,
          color: CupertinoColors.activeBlue,
        ),
        if (birthday.isEmpty) ...<Widget>[
          const SizedBox(height: 10),
          AppGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D55).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cake_rounded,
                    color: Color(0xFFFF2D55),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Doğum günü eklenmedi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (notes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          AppGlassCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.doc_text_fill,
                      size: 16,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Notlar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _studentInitials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _heroAction({
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              child,
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricGlanceCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return AppGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoEdit(Color accentColor) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        _profileHeader(accentColor),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Basic Info',
          child: Column(
            children: <Widget>[
              _field(_nameController, 'Name *'),
              const SizedBox(height: 10),
              _field(
                _phoneController,
                'Phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              _birthdayButton(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Lesson Settings',
          child: _field(
            _lessonCostController,
            'Lesson Cost',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Notes',
          child: _field(
            _notesController,
            'Notes',
            minLines: 4,
            maxLines: 5,
          ),
        ),
        const SizedBox(height: 20),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isDeleting ? null : _deleteStudent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_isDeleting) ...<Widget>[
                  const CupertinoActivityIndicator(),
                  const SizedBox(width: 8),
                ] else ...<Widget>[
                  const Icon(
                    CupertinoIcons.delete,
                    size: 18,
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(width: 8),
                ],
                const Text(
                  'Delete Student',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsTab() {
    final StudentSummary? summary = _summary;
    final int completedCount = summary?.lessonsCompleted ??
        _completedLessons.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        _sectionCard(
          context,
          title: 'Completed lessons',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$completedCount',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.activeGreen,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lessons with status completed',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              if (summary != null) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _metricTile(
                        label: 'Total',
                        value: '${summary.lessonsTotal}',
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile(
                        label: 'Cancelled',
                        value: '${summary.lessonsCancelled}',
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ),
                if (summary.lastLessonDate != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    'Son ders: ${_formatDisplayDate(summary.lastLessonDate)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Completed list',
          child: _lessonsError != null
              ? Text(
                  _lessonsError!,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                )
              : _completedLessons.isEmpty
                  ? const Text(
                      'No completed lessons yet.',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    )
                  : Column(
                      children: _completedLessons.map((Lesson lesson) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      lesson.displayTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_formatDisplayDate(lesson.date)} · ${_formatDisplayTime(lesson.startAt)}'
                                      '${lesson.price != null && lesson.price!.isNotEmpty ? ' · ${lesson.price}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                size: 18,
                                color: CupertinoColors.activeGreen,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab() {
    final StudentBalance? balance = _balance;
    if (_paymentsError != null && balance == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _paymentsError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CupertinoColors.systemRed),
          ),
        ),
      );
    }
    if (balance == null) {
      return const Center(child: Text('No payment data.'));
    }
    final String currency =
        balance.currency.isEmpty ? 'TRY' : balance.currency;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        if (_paymentsError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _paymentsError!,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemOrange,
              ),
            ),
          ),
        Row(
          children: <Widget>[
            Expanded(
              child: _metricTile(
                label: 'Total paid',
                value: _money(balance.paidAmount, currency),
                color: CupertinoColors.activeGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricTile(
                label: 'Prepaid',
                value: _money(balance.prepaidAmount, currency),
                color: CupertinoColors.systemPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _metricTile(
          label: 'Debts (unpaid)',
          value: _money(balance.unpaidAmount, currency),
          color: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Cashflow',
          child: Column(
            children: <Widget>[
              _balanceRow('Collected', balance.cashCollected, currency),
              _balanceRow('Refunded', balance.cashRefunded, currency),
              _balanceRow('Net', balance.cashNet, currency),
              _balanceRow('Settled', balance.settledAmount, currency),
              _balanceRow('Lesson total', balance.totalAmount, currency),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return AppGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: AppGlassTokens.radiusSmall,
      tint: color.withValues(alpha: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceRow(String label, num amount, String currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label),
          Text(
            _money(amount, currency),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _money(num amount, String currency) {
    final String value = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '$value $currency';
  }

  Future<void> _openAddPayment() async {
    final Student student = Student(
      id: widget.studentId,
      name: _nameController.text.trim().isEmpty
          ? 'Student'
          : _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      lessonCost: _lessonCostController.text.trim().isEmpty
          ? null
          : _lessonCostController.text.trim(),
      color: _colorController.text.trim().isEmpty
          ? null
          : _colorController.text.trim(),
    );

    final bool? created = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (BuildContext context) => CreatePaymentPage(
          paymentService: _paymentService,
          studentService: widget.studentService,
          lessonService: _lessonService,
          initialStudent: student,
          lockStudent: true,
        ),
      ),
    );
    if (created == true && mounted) {
      await _reloadBalance();
    }
  }

  Future<void> _reloadBalance() async {
    try {
      final StudentBalance balance =
          await widget.studentService.getStudentBalance(widget.studentId);
      if (!mounted) {
        return;
      }
      setState(() {
        _balance = balance;
        _paymentsError = null;
      });
    } on StudentServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _paymentsError = error.message;
      });
    }
  }

  Widget _profileHeader(Color accentColor) {
    final String phone = _phoneController.text.trim();
    final bool hasPhone = phone.isNotEmpty;

    return AppGlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'Student'
                      : _nameController.text.trim(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPhone ? phone : 'No phone number',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          _contactActionButton(
            color: CupertinoColors.activeGreen,
            enabled: hasPhone,
            onPressed: _callStudent,
            child: const Icon(
              CupertinoIcons.phone_fill,
              size: 20,
              color: CupertinoColors.activeGreen,
            ),
          ),
          const SizedBox(width: 8),
          _contactActionButton(
            color: const Color(0xFF25D366),
            enabled: hasPhone,
            onPressed: _openWhatsApp,
            child: const FaIcon(
              FontAwesomeIcons.whatsapp,
              size: 18,
              color: Color(0xFF25D366),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactActionButton({
    required Color color,
    required bool enabled,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: enabled ? onPressed : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Future<void> _callStudent() async {
    final String? tel = _phoneForTel(_phoneController.text);
    if (tel == null) {
      await _showMessage('Add a phone number first.');
      return;
    }
    final Uri uri = Uri(scheme: 'tel', path: tel);
    final bool launched = await launchUrl(uri);
    if (!launched && mounted) {
      await _showMessage('Could not start the call.');
    }
  }

  Future<void> _openWhatsApp() async {
    final String? digits = _phoneForWhatsApp(_phoneController.text);
    if (digits == null) {
      await _showMessage('Add a phone number first.');
      return;
    }
    final Uri uri = Uri.parse('https://wa.me/$digits');
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      await _showMessage('Could not open WhatsApp.');
    }
  }

  /// Digits (and optional leading +) for `tel:` links.
  String? _phoneForTel(String raw) {
    final String cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty || RegExp(r'^\+?$').hasMatch(cleaned)) {
      return null;
    }
    return cleaned;
  }

  /// International digits for WhatsApp (`wa.me`), TR local `0…` → `90…`.
  String? _phoneForWhatsApp(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return null;
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      digits = '90${digits.substring(1)}';
    }
    return digits;
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return AppGlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: AppGlassTokens.radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String placeholder, {
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
    );
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
    return Color.fromARGB(255, (rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF);
  }

  Widget _birthdayButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _showBirthdayPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.cake_rounded,
              size: 20,
              color: Color(0xFFFF2D55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedBirthday == null
                    ? 'Doğum günü ekle'
                    : _formatBirthdayDisplay(_selectedBirthday),
                style: TextStyle(
                  color: _selectedBirthday == null
                      ? CupertinoColors.placeholderText.resolveFrom(context)
                      : CupertinoColors.label.resolveFrom(context),
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

  Future<void> _showBirthdayPicker() async {
    final DateTime? picked = await showBirthdayCalendar(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2010, 1, 1),
      maximumDate: DateTime.now(),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedBirthday = picked;
    });
  }

  Future<bool> _handleBackPressed() async {
    if (!_isDirty) {
      return true;
    }

    final bool? shouldLeave = await showAppAlert<bool>(
      context: context,
      title: 'Unsaved changes',
      message: 'Save your changes before leaving?',
      actions: <AppAlertAction>[
        AppAlertAction(
          label: 'Cancel',
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: "Don't Save",
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(true),
        ),
        AppAlertAction(
          label: 'Save',
          style: AppAlertStyle.primary,
          onPressed: (BuildContext ctx) async {
            final bool saved = await _saveChanges(showSuccess: false);
            if (saved && ctx.mounted) {
              Navigator.of(ctx).pop(true);
            }
          },
        ),
      ],
    );
    return shouldLeave == true;
  }

  bool get _isDirty {
    return _nameController.text != _initialName ||
        _phoneController.text != _initialPhone ||
        _lessonCostController.text != _initialLessonCost ||
        _notesController.text != _initialNotes ||
        _colorController.text != _initialColor ||
        _formatDate(_selectedBirthday) != _initialBirthday;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatBirthdayDisplay(DateTime? date) {
    if (date == null) {
      return '';
    }
    const List<String> months = <String>[
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDisplayDate(String? raw) {
    final DateTime? parsed = _parseDate(raw);
    if (parsed == null) {
      return (raw ?? '').trim();
    }
    return _formatBirthdayDisplay(parsed);
  }

  String _formatDisplayTime(String? raw) {
    if (raw == null) {
      return '';
    }
    final String value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    // "12:00:00" or "12:00"
    final RegExp timeOnly = RegExp(r'^(\d{1,2}):(\d{2})');
    final Match? match = timeOnly.firstMatch(value);
    if (match != null) {
      return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)}';
    }
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    }
    return value;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.trim());
  }

  Future<void> _loadDetail() async {
    try {
      final StudentDetail detail =
          await widget.studentService.getStudentDetail(widget.studentId);

      StudentBalance? balance;
      String? paymentsError;
      try {
        balance =
            await widget.studentService.getStudentBalance(widget.studentId);
      } on StudentServiceException catch (error) {
        paymentsError = error.message;
      }

      List<Lesson> completed = <Lesson>[];
      String? lessonsError;
      try {
        completed = await _lessonService.listLessons(
          studentId: widget.studentId,
          status: 'completed',
          source: LessonSource.journal,
          sortBy: 'date',
          sortDirection: 'desc',
        );
      } on LessonServiceException catch (error) {
        lessonsError = error.message;
      }

      if (!mounted) {
        return;
      }
      _nameController.text = detail.student.name;
      _phoneController.text = detail.student.phone ?? '';
      _lessonCostController.text = detail.student.lessonCost ?? '';
      _notesController.text = detail.student.notes ?? '';
      _colorController.text = detail.student.color ?? '';
      _selectedBirthday = _parseDate(detail.student.birthday);
      _initialName = _nameController.text;
      _initialPhone = _phoneController.text;
      _initialLessonCost = _lessonCostController.text;
      _initialNotes = _notesController.text;
      _initialColor = _colorController.text;
      _initialBirthday = _formatDate(_selectedBirthday);
      setState(() {
        _summary = detail.summary;
        _balance = balance;
        _completedLessons = completed;
        _paymentsError = paymentsError;
        _lessonsError = lessonsError;
      });
    } on StudentServiceException catch (error) {
      await _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _saveChanges({bool showSuccess = true}) async {
    if (_isSaving) {
      return false;
    }
    if (_nameController.text.trim().isEmpty) {
      await _showMessage('Name is required.');
      return false;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await widget.studentService.updateStudent(
        id: widget.studentId,
        request: StudentCreateRequest(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          birthday: _formatDate(_selectedBirthday),
          lessonCost: _lessonCostController.text.trim(),
          notes: _notesController.text.trim(),
          color: _colorController.text.trim(),
        ),
      );
      if (!mounted) {
        return false;
      }
      if (showSuccess) {
        await _showMessage('Student updated successfully.');
      }
      _initialName = _nameController.text;
      _initialPhone = _phoneController.text;
      _initialLessonCost = _lessonCostController.text;
      _initialNotes = _notesController.text;
      _initialColor = _colorController.text;
      _initialBirthday = _formatDate(_selectedBirthday);
      return true;
    } on StudentServiceException catch (error) {
      await _showMessage(error.message);
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteStudent() async {
    final bool? confirmed = await showAppAlert<bool>(
      context: context,
      title: 'Delete Student',
      message: 'This student will be set inactive. Continue?',
      actions: <AppAlertAction>[
        AppAlertAction(
          label: 'Cancel',
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: 'Delete',
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(true),
        ),
      ],
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _isDeleting = true;
    });
    try {
      await widget.studentService.deleteStudent(widget.studentId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on StudentServiceException catch (error) {
      await _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _showMessage(String message) {
    return showAppAlert<void>(
      context: context,
      title: 'Student',
      message: message,
      actions: const <AppAlertAction>[
        AppAlertAction(label: 'OK', style: AppAlertStyle.primary),
      ],
    );
  }
}

class _CreateStudentPage extends StatefulWidget {
  const _CreateStudentPage({required this.studentService});

  final StudentService studentService;

  @override
  State<_CreateStudentPage> createState() => _CreateStudentPageState();
}

class _CreateStudentPageState extends State<_CreateStudentPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _lessonCostController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedBirthday;
  int _red = 10;
  int _green = 132;
  int _blue = 255;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _lessonCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add Student'),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _selectedAvatarColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: _selectedAvatarColor, width: 2),
                ),
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: 42,
                  color: _selectedAvatarColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showAdvancedColorPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _selectedAvatarColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: CupertinoColors.systemGrey4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pick a color',
                        style: const TextStyle(
                          color: CupertinoColors.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: CupertinoColors.systemGrey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _formField(
              _nameController,
              'Name & Surname',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            _formField(
              _phoneController,
              'Phone',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showBirthdayPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.calendar,
                      color: CupertinoColors.systemOrange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedBirthday == null
                            ? 'Add Birthday'
                            : 'Birthday: ${_formatDate(_selectedBirthday!)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CupertinoColors.systemOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      color: CupertinoColors.systemGrey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.systemGrey4),
              ),
              child: Row(
                children: <Widget>[
                  const Text(
                    'Lesson Cost:',
                    style: TextStyle(
                      color: CupertinoColors.systemPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _lessonCostController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      placeholder: '200',
                      textAlign: TextAlign.left,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _formField(
              _notesController,
              'Notes',
              maxLines: 5,
              minLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String placeholder, {
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.left,
    int maxLines = 1,
    int minLines = 1,
  }) {
    return CupertinoTextField(
      controller: controller,
      keyboardType: keyboardType,
      placeholder: placeholder,
      textAlign: textAlign,
      minLines: minLines,
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      await _showErrorDialog('Name is required.');
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      await widget.studentService.createStudent(
        StudentCreateRequest(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          birthday: _selectedBirthday == null
              ? null
              : _formatDate(_selectedBirthday!),
          lessonCost: _lessonCostController.text.trim(),
          notes: _notesController.text.trim(),
          color: _hexFromColor(_selectedAvatarColor),
          status: 1,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on StudentServiceException catch (error) {
      await _showErrorDialog(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showBirthdayPicker() async {
    final DateTime? picked = await showBirthdayCalendar(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2010, 1, 1),
      maximumDate: DateTime.now(),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedBirthday = picked;
    });
  }

  String _formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Color get _selectedAvatarColor => Color.fromARGB(255, _red, _green, _blue);

  String _hexFromColor(Color color) {
    final int rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _showAdvancedColorPicker() async {
    Color tempColor = _selectedAvatarColor;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        final double sheetHeight = MediaQuery.of(context).size.height * 0.82;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: sheetHeight,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const Expanded(
                          child: Text(
                            'Avatar Color',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _red = tempColor.red;
                              _green = tempColor.green;
                              _blue = tempColor.blue;
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: tempColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CupertinoColors.systemGrey4,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hexFromColor(tempColor),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.secondarySystemBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: tempColor,
                              onColorChanged: (Color value) {
                                setModalState(() {
                                  tempColor = value;
                                });
                              },
                              enableAlpha: false,
                              // Remove material dropdown that needs localizations.
                              labelTypes: const <ColorLabelType>[],
                              pickerAreaHeightPercent: 0.58,
                              pickerAreaBorderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              displayThumbColor: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showErrorDialog(String message) {
    return showAppAlert<void>(
      context: context,
      title: 'Students',
      message: message,
      actions: const <AppAlertAction>[
        AppAlertAction(label: 'OK', style: AppAlertStyle.primary),
      ],
    );
  }
}
