import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:tutor_app/groups/group_service.dart';
import 'package:tutor_app/pages/group_detail_page.dart';
import 'package:tutor_app/students/student_service.dart';

enum _StudentsViewMode { students, groups }

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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isGroupMode ? 'Groups' : 'Students'),
      ),
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    onChanged: (_) => _reloadCurrentMode(),
                    onSubmitted: (_) => _reloadCurrentMode(),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 12,
              child: _buildModeSwitch(),
            ),
            Positioned(
              right: 16,
              bottom: 12,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isGroupMode
                    ? _showCreateGroupSheet
                    : _showCreateStudentSheet,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
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
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? CupertinoColors.activeBlue
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(24),
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
      return Center(child: Text(_errorMessage!));
    }

    if (_isGroupMode) {
      if (_groups.isEmpty) {
        return const Center(
          child: Text(
            'No groups found.',
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        itemCount: _groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final TutorGroup group = _groups[index];
          return _groupTile(group);
        },
      );
    }

    if (_students.isEmpty) {
      return const Center(
        child: Text(
          'No students found.',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
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

  Widget _groupTile(TutorGroup group) {
    final Color accent = _parseHexColor(group.color);
    return Dismissible(
      key: ValueKey<String>('group-${group.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground
                .resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 1.4),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.person_3_fill,
                    size: 18,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: CupertinoColors.systemGrey2,
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
    return Dismissible(
      key: ValueKey<String>('student-${student.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
      ),
      confirmDismiss: (_) => confirmDismiss(),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: () => _openStudentDetailPage(student.id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemGroupedBackground
                .resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _parseHexColor(student.color).withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _parseHexColor(student.color),
                    width: 1.4,
                  ),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.person_fill,
                    size: 18,
                    color: _parseHexColor(student.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (student.phone != null &&
                        student.phone!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        student.phone!,
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 18,
                color: CupertinoColors.systemGrey2,
              ),
            ],
          ),
        ),
      ),
    );
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
    bool? shouldDelete;
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Student'),
          content: Text(
            'Delete ${student.name}? This will set status to inactive.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                shouldDelete = false;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                try {
                  await _studentService.deleteStudent(student.id);
                  shouldDelete = true;
                } on StudentServiceException catch (error) {
                  shouldDelete = false;
                  if (mounted) {
                    await _showErrorDialog(error.message);
                  }
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return shouldDelete == true;
  }

  Future<bool> _confirmDeleteGroup(TutorGroup group) async {
    bool? shouldDelete;
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Group'),
          content: Text(
            'Delete ${group.name}? This will set status to inactive.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                shouldDelete = false;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                try {
                  await _groupService.deleteGroup(group.id);
                  shouldDelete = true;
                } on GroupServiceException catch (error) {
                  shouldDelete = false;
                  if (mounted) {
                    await _showErrorDialog(error.message);
                  }
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Students'),
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

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  StudentSummary? _summary;
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
    final Color accentColor = _parseHexColor(_colorController.text);
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Student Detail'),
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
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
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
                    child: Column(
                      children: <Widget>[
                        _field(
                          _lessonCostController,
                          'Lesson Cost',
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 10),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _showDetailColorPicker,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.secondarySystemBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: CupertinoColors.systemGrey4,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _parseHexColor(_colorController.text),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: CupertinoColors.systemGrey4,
                                    ),
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
                                Text(
                                  _colorController.text.isEmpty
                                      ? _hexFromColor(
                                          _parseHexColor(_colorController.text),
                                        )
                                      : _colorController.text.toUpperCase(),
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  CupertinoIcons.slider_horizontal_3,
                                  color: CupertinoColors.systemGrey,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                  const SizedBox(height: 12),
                  if (_summary != null) ...<Widget>[
                    _sectionCard(
                      context,
                      title: 'Summary',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _summaryChip(
                            'Lessons',
                            '${_summary!.lessonsTotal}',
                            CupertinoColors.activeBlue,
                          ),
                          _summaryChip(
                            'Completed',
                            '${_summary!.lessonsCompleted}',
                            CupertinoColors.activeGreen,
                          ),
                          _summaryChip(
                            'Cancelled',
                            '${_summary!.lessonsCancelled}',
                            CupertinoColors.systemRed,
                          ),
                          _summaryChip(
                            'Last',
                            _summary!.lastLessonDate ?? '-',
                            CupertinoColors.systemGrey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 10),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isDeleting ? null : _deleteStudent,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withOpacity(0.12),
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
              ),
        ),
      ),
    );
  }

  Widget _profileHeader(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
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
                  _phoneController.text.trim().isEmpty
                      ? 'No phone number'
                      : _phoneController.text.trim(),
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
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

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: CupertinoColors.black),
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
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

  String _hexFromColor(Color color) {
    final int rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _showDetailColorPicker() async {
    Color tempColor = _parseHexColor(_colorController.text);

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
                              _colorController.text = _hexFromColor(tempColor);
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
              CupertinoIcons.calendar,
              size: 18,
              color: CupertinoColors.systemOrange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedBirthday == null
                    ? 'Add Birthday'
                    : 'Birthday: ${_formatDate(_selectedBirthday)}',
                style: const TextStyle(color: CupertinoColors.label),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 15,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBirthdayPicker() async {
    DateTime tempDate = _selectedBirthday ?? DateTime(2010, 1, 1);
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _selectedBirthday = tempDate;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime value) {
                    tempDate = value;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _handleBackPressed() async {
    if (!_isDirty) {
      return true;
    }

    bool shouldLeave = false;
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text('Save your changes before leaving?'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                shouldLeave = true;
                Navigator.of(context).pop();
              },
              child: const Text('Don\'t Save'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                final bool saved = await _saveChanges(showSuccess: false);
                if (saved) {
                  shouldLeave = true;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    return shouldLeave;
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
    bool confirmed = false;
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Student'),
          content: const Text(
            'This student will be set inactive. Continue?',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                confirmed = true;
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!confirmed) {
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
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Student'),
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
    DateTime tempDate = _selectedBirthday ?? DateTime(2010, 1, 1);
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _selectedBirthday = tempDate;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime value) {
                    tempDate = value;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Students'),
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
}
