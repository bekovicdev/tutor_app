import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Material, MaterialType;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tutor_app/groups/group_service.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/pages/create_payment_page.dart';
import 'package:tutor_app/pages/group_detail_page.dart';
import 'package:tutor_app/pages/paywall_page.dart';
import 'package:tutor_app/payments/payment_service.dart';
import 'package:tutor_app/settings/app_settings.dart';
import 'package:tutor_app/students/student_service.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';
import 'package:tutor_app/widgets/birthday_calendar_picker.dart';
import 'package:tutor_app/widgets/settings_nav_button.dart';
import 'package:url_launcher/url_launcher.dart';

enum _StudentsViewMode { students, groups }

enum _StudentDetailTab { info, lessons, payments }

class StudentsPage extends StatefulWidget {
  const StudentsPage({
    required this.token,
    this.onOpenSettings,
    super.key,
  });

  final String token;
  final void Function(BuildContext context)? onOpenSettings;

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
    final AppLocalizations l10n = context.l10n;
    final int itemCount = _isGroupMode ? _groups.length : _students.length;
    final String subtitle = _isLoading
        ? l10n.loading
        : _isGroupMode
        ? l10n.groupCount(itemCount)
        : l10n.studentCount(itemCount);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_isGroupMode ? l10n.groups : l10n.students),
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
        border: appNavigationBarBorderOf(context),
        leading: widget.onOpenSettings == null
            ? null
            : SettingsNavButton(
                onPressed: () => widget.onOpenSettings!(context),
              ),
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
                          ? l10n.searchGroups
                          : l10n.searchByNameOrPhone,
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
            Positioned(left: 16, bottom: 14, child: _buildModeSwitch()),
            Positioned(right: 16, bottom: 14, child: _buildAddButton()),
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
          gradient: AppBrand.heroGradient,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppBrand.primary.withValues(alpha: 0.35),
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
    final AppLocalizations l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
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
            label: l10n.students,
            icon: CupertinoIcons.person_2,
            selected: !_isGroupMode,
            onTap: () => _setViewMode(_StudentsViewMode.students),
          ),
          _modeChip(
            label: l10n.groups,
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
              ? AppBrand.primary
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppBrand.primary.withValues(alpha: 0.28),
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
    final AppLocalizations l10n = context.l10n;
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMessage != null) {
      return _emptyState(
        icon: CupertinoIcons.exclamationmark_triangle,
        title: l10n.somethingWentWrong,
        message: _errorMessage!,
        actionLabel: l10n.retry,
        onAction: _reloadCurrentMode,
      );
    }

    if (_isGroupMode) {
      if (_groups.isEmpty) {
        return _emptyState(
          icon: CupertinoIcons.person_3,
          title: l10n.noGroupsYet,
          message: l10n.noGroupsHint,
          actionLabel: l10n.addGroup,
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
        title: l10n.noStudentsYet,
        message: l10n.noStudentsHint,
        actionLabel: l10n.addStudent,
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
              _students = _students
                  .where((Student s) => s.id != student.id)
                  .toList();
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
                color: AppBrand.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppBrand.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
    final AppLocalizations l10n = context.l10n;
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
                      l10n.group,
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
    final AppLocalizations l10n = context.l10n;
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
                imageUrl: student.profilePictureUrl,
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
                          if (cost != null && cost.isNotEmpty)
                            l10n.costPerLesson(cost),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
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
    String? imageUrl,
    IconData? icon,
  }) {
    final bool hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.12),
                ],
              ),
        border: Border.all(color: accent.withValues(alpha: 0.85), width: 1.5),
        image: hasImage
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? null
          : icon != null
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
    final bool? changed = await openStudentDetailPage(
      context,
      studentId: studentId,
      studentService: _studentService,
    );
    if (changed == true) {
      await _reloadCurrentMode();
    }
  }

  Future<bool> _confirmDelete(Student student) async {
    final AppLocalizations l10n = context.l10n;
    final bool? shouldDelete = await showAppAlert<bool>(
      context: context,
      title: l10n.deleteStudent,
      message: l10n.deleteStudentConfirm(student.name),
      actions: <AppAlertAction>[
        AppAlertAction(
          label: l10n.cancel,
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: l10n.delete,
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
    final AppLocalizations l10n = context.l10n;
    final bool? shouldDelete = await showAppAlert<bool>(
      context: context,
      title: l10n.deleteGroup,
      message: l10n.deleteGroupConfirm(group.name),
      actions: <AppAlertAction>[
        AppAlertAction(
          label: l10n.cancel,
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: l10n.delete,
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

  Future<void> _showErrorDialog(String message) {
    final AppLocalizations l10n = context.l10n;
    return showAppAlert<void>(
      context: context,
      title: l10n.students,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }
}

/// Opens the student detail screen. Returns `true` if data changed.
Future<bool?> openStudentDetailPage(
  BuildContext context, {
  required int studentId,
  required StudentService studentService,
}) {
  return Navigator.of(context).push<bool>(
    CupertinoPageRoute<bool>(
      builder: (BuildContext context) => _StudentDetailPage(
        studentId: studentId,
        studentService: studentService,
      ),
    ),
  );
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
  bool _isUploadingPhoto = false;
  String? _profilePictureUrl;
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
    final AppLocalizations l10n = context.l10n;
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.studentDetail),
          border: appNavigationBarBorderOf(context),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              final bool canLeave = await _handleBackPressed();
              if (!canLeave || !mounted) {
                return;
              }
              Navigator.of(context).pop();
            },
            child: Text(l10n.back),
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
                      child:
                          CupertinoSlidingSegmentedControl<_StudentDetailTab>(
                            groupValue: _tab,
                            children: <_StudentDetailTab, Widget>{
                              _StudentDetailTab.info: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(l10n.info),
                              ),
                              _StudentDetailTab.lessons: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(l10n.lessons),
                              ),
                              _StudentDetailTab.payments: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(l10n.payments),
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
    final AppLocalizations l10n = context.l10n;
    if (_isLoading) {
      return null;
    }
    if (_tab == _StudentDetailTab.payments) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _openAddPayment,
        child: Text(l10n.add),
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
            child: Text(l10n.cancel),
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
                : Text(l10n.save),
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
      child: Text(l10n.edit),
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
    final AppLocalizations l10n = context.l10n;
    final String name = _nameController.text.trim().isEmpty
        ? l10n.student
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
                  gradient:
                      (_profilePictureUrl == null ||
                          _profilePictureUrl!.isEmpty)
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            accentColor.withValues(alpha: 0.95),
                            accentColor.withValues(alpha: 0.55),
                          ],
                        )
                      : null,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  image:
                      (_profilePictureUrl != null &&
                          _profilePictureUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(_profilePictureUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child:
                    (_profilePictureUrl == null || _profilePictureUrl!.isEmpty)
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      )
                    : null,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
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
                      label: l10n.call,
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
                      label: l10n.whatsApp,
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
          label: l10n.lessonFee,
          value: cost.isEmpty ? '—' : cost,
          subtitle: l10n.perLesson,
          icon: CupertinoIcons.money_dollar_circle_fill,
          color: AppBrand.primary,
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
                    l10n.noBirthdayAdded,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
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
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.notes,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
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
    final AppLocalizations l10n = context.l10n;
    final bool hasImage =
        _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty;
    final String initials = _studentInitials(
      _nameController.text.trim().isEmpty
          ? l10n.student.substring(0, 1)
          : _nameController.text.trim(),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        Center(
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: _manageProfilePicture,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasImage
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  accentColor.withValues(alpha: 0.95),
                                  accentColor.withValues(alpha: 0.55),
                                ],
                              ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: hasImage
                            ? DecorationImage(
                                image: NetworkImage(_profilePictureUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(
                          color: CupertinoColors.white,
                          width: 3,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _isUploadingPhoto
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : hasImage
                          ? null
                          : Text(
                              initials,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppBrand.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CupertinoColors.systemBackground.resolveFrom(
                              context,
                            ),
                            width: 3,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppBrand.primary.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.camera_fill,
                          size: 15,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tapPhotoToChange,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AppGlassCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _editFieldLabel(l10n.name),
              _editField(
                controller: _nameController,
                placeholder: l10n.studentName,
              ),
              const SizedBox(height: 16),
              _editFieldLabel(l10n.phone),
              _editField(
                controller: _phoneController,
                placeholder: '05xx xxx xx xx',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _editFieldLabel(l10n.birthday),
              _birthdayButton(),
              const SizedBox(height: 16),
              _editFieldLabel(l10n.lessonFee),
              _editField(
                controller: _lessonCostController,
                placeholder: l10n.eg500,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              _editFieldLabel(l10n.notes),
              _editField(
                controller: _notesController,
                placeholder: l10n.addShortNote,
                minLines: 4,
                maxLines: 6,
              ),
            ],
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
              color: CupertinoColors.systemRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CupertinoColors.systemRed.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_isDeleting) ...<Widget>[
                  const CupertinoActivityIndicator(),
                  const SizedBox(width: 8),
                ] else ...<Widget>[
                  const Icon(
                    CupertinoIcons.trash,
                    size: 18,
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  l10n.deleteStudentAction,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _editFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String placeholder,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      placeholderStyle: TextStyle(
        color: CupertinoColors.placeholderText.resolveFrom(context),
        fontWeight: FontWeight.w400,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator
              .resolveFrom(context)
              .withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildLessonsTab() {
    final AppLocalizations l10n = context.l10n;
    final StudentSummary? summary = _summary;
    final int completedCount =
        summary?.lessonsCompleted ?? _completedLessons.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        _sectionCard(
          context,
          title: l10n.completedLessons,
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
              Text(
                l10n.lessonsWithStatusCompleted,
                style: const TextStyle(
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
                        label: l10n.total,
                        value: '${summary.lessonsTotal}',
                        color: AppBrand.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile(
                        label: l10n.cancelled,
                        value: '${summary.lessonsCancelled}',
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ),
                if (summary.lastLessonDate != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    l10n.lastLesson(_formatDisplayDate(summary.lastLessonDate)),
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
          title: l10n.completedList,
          child: _lessonsError != null
              ? Text(
                  _lessonsError!,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                )
              : _completedLessons.isEmpty
              ? Text(
                  l10n.noCompletedLessonsYet,
                  style: const TextStyle(color: CupertinoColors.systemGrey),
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
    final AppLocalizations l10n = context.l10n;
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
      return Center(child: Text(l10n.noPaymentData));
    }
    final String currency = balance.currency.isEmpty ? 'TRY' : balance.currency;

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
        _buildPackageCreditStrip(balance, currency),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _metricTile(
                label: l10n.totalPaid,
                value: _money(balance.paidAmount, currency),
                color: CupertinoColors.activeGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricTile(
                label: l10n.prepaid,
                value: _money(balance.prepaidAmount, currency),
                color: CupertinoColors.systemPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _metricTile(
          label: l10n.debtsUnpaid,
          value: _money(balance.unpaidAmount, currency),
          color: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: l10n.cashflow,
          child: Column(
            children: <Widget>[
              _balanceRow(l10n.collected, balance.cashCollected, currency),
              _balanceRow(l10n.refunded, balance.cashRefunded, currency),
              _balanceRow(l10n.net, balance.cashNet, currency),
              _balanceRow(l10n.settled, balance.settledAmount, currency),
              _balanceRow(l10n.lessonTotal, balance.totalAmount, currency),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCreditStrip(StudentBalance balance, String currency) {
    final AppLocalizations l10n = context.l10n;
    final num credit = balance.packageCredit;
    final num lessonCost =
        num.tryParse(_lessonCostController.text.replaceAll(',', '.')) ?? 0;
    final int? approxLessons = lessonCost > 0
        ? (credit / lessonCost).floor()
        : null;

    return AppGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: AppGlassTokens.radiusSmall,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.packageCredit,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _money(credit, currency),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.systemPurple,
            ),
          ),
          if (approxLessons != null && credit > 0) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              l10n.approxLessonsLeft(approxLessons),
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: CupertinoColors.systemPurple.withValues(alpha: 0.15),
                  onPressed: credit > 0 && balance.unpaidAmount > 0
                      ? _applyCreditToUnpaidLesson
                      : null,
                  child: Text(
                    l10n.applyCredit,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: credit > 0 && balance.unpaidAmount > 0
                          ? CupertinoColors.systemPurple
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: AppBrand.primary.withValues(alpha: 0.12),
                  onPressed: _openLoadPackage,
                  child: Text(
                    l10n.loadPackage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppBrand.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openLoadPackage() async {
    final AppLocalizations l10n = context.l10n;
    final Student student = Student(
      id: widget.studentId,
      name: _nameController.text.trim().isEmpty
          ? l10n.student
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
          initialKind: PaymentKind.prepaid,
        ),
      ),
    );
    if (created == true && mounted) {
      await _reloadBalance();
    }
  }

  Future<void> _applyCreditToUnpaidLesson() async {
    final AppLocalizations l10n = context.l10n;
    List<Lesson> unpaid = <Lesson>[];
    try {
      unpaid = await _lessonService.listLessons(
        studentId: widget.studentId,
        source: LessonSource.journal,
        paymentStatus: PaymentStatus.unpaid,
        sortBy: 'date',
        sortDirection: 'asc',
      );
      unpaid = unpaid
          .where(
            (Lesson lesson) =>
                lesson.isFree != true &&
                lesson.status != 'cancelled' &&
                lesson.resolvedPaymentStatus == PaymentStatus.unpaid,
          )
          .toList();
    } on LessonServiceException catch (error) {
      await showAppAlert<void>(
        context: context,
        title: l10n.payments,
        message: error.message,
        actions: <AppAlertAction>[
          AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
        ],
      );
      return;
    }

    if (unpaid.isEmpty) {
      await showAppAlert<void>(
        context: context,
        title: l10n.applyCredit,
        message: l10n.noUnpaidLessons,
        actions: <AppAlertAction>[
          AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
        ],
      );
      return;
    }

    final Lesson? selected = await showAppActionSheet<Lesson>(
      context: context,
      title: l10n.selectUnpaidLesson,
      cancelLabel: l10n.cancel,
      actions: unpaid
          .map(
            (Lesson lesson) => AppSheetAction(
              label:
                  '${lesson.date} · ${lesson.startAt} · ${lesson.displayTitle}'
                  '${lesson.price != null ? ' · ${lesson.price}' : ''}',
              onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(lesson),
            ),
          )
          .toList(),
    );
    if (selected == null) {
      return;
    }

    try {
      await _paymentService.markLessonPayment(
        lessonId: selected.id,
        request: LessonPaymentRequest(
          paymentStatus: PaymentStatus.prepaid,
          amount: num.tryParse(selected.price?.replaceAll(',', '.') ?? ''),
          // Cash was already recorded when the package was loaded.
          recordPayment: false,
        ),
      );
      if (!mounted) {
        return;
      }
      await showAppAlert<void>(
        context: context,
        title: l10n.applyCredit,
        message: l10n.creditApplied,
        actions: <AppAlertAction>[
          AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
        ],
      );
      await _reloadBalance();
    } on PaymentServiceException catch (error) {
      if (!mounted) {
        return;
      }
      await showAppAlert<void>(
        context: context,
        title: l10n.payments,
        message: error.message,
        actions: <AppAlertAction>[
          AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
        ],
      );
    }
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
    final AppLocalizations l10n = context.l10n;
    final Student student = Student(
      id: widget.studentId,
      name: _nameController.text.trim().isEmpty
          ? l10n.student
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
      final StudentBalance balance = await widget.studentService
          .getStudentBalance(widget.studentId);
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

  Future<void> _manageProfilePicture() async {
    final AppLocalizations l10n = context.l10n;
    if (!_isEditing || _isUploadingPhoto) {
      return;
    }

    final bool hasPhoto =
        _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty;

    final String? action = await showAppActionSheet<String>(
      context: context,
      title: l10n.profilePhoto,
      actions: <AppSheetAction>[
        AppSheetAction(
          label: l10n.chooseFromGallery,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop('gallery'),
        ),
        AppSheetAction(
          label: l10n.camera,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop('camera'),
        ),
        if (hasPhoto)
          AppSheetAction(
            label: l10n.removePhoto,
            isDestructive: true,
            onPressed: (BuildContext ctx) => Navigator.of(ctx).pop('remove'),
          ),
      ],
    );
    if (action == null || !mounted) {
      return;
    }

    if (action == 'remove') {
      await _removeProfilePicture();
      return;
    }

    final ImageSource source = action == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
    });
    try {
      final Student updated = await widget.studentService.uploadProfilePicture(
        id: widget.studentId,
        file: File(picked.path),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profilePictureUrl = updated.profilePictureUrl;
      });
    } on StudentServiceException catch (error) {
      await _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    setState(() {
      _isUploadingPhoto = true;
    });
    try {
      await widget.studentService.deleteProfilePicture(widget.studentId);
      if (!mounted) {
        return;
      }
      setState(() {
        _profilePictureUrl = null;
      });
    } on StudentServiceException catch (error) {
      await _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _callStudent() async {
    final AppLocalizations l10n = context.l10n;
    final String? tel = _phoneForTel(_phoneController.text);
    if (tel == null) {
      await _showMessage(l10n.addPhoneFirst);
      return;
    }
    final Uri uri = Uri(scheme: 'tel', path: tel);
    final bool launched = await launchUrl(uri);
    if (!launched && mounted) {
      await _showMessage(l10n.couldNotStartCall);
    }
  }

  Future<void> _openWhatsApp() async {
    final AppLocalizations l10n = context.l10n;
    final String? digits = _phoneForWhatsApp(_phoneController.text);
    if (digits == null) {
      await _showMessage(l10n.addPhoneFirst);
      return;
    }
    final Uri uri = Uri.parse('https://wa.me/$digits');
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      await _showMessage(l10n.couldNotOpenWhatsApp);
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
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
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

  Widget _birthdayButton() {
    final AppLocalizations l10n = context.l10n;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _showBirthdayPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator
                .resolveFrom(context)
                .withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFF2D55).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cake_rounded,
                size: 18,
                color: Color(0xFFFF2D55),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedBirthday == null
                    ? l10n.selectDate
                    : _formatBirthdayDisplay(_selectedBirthday),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _selectedBirthday == null
                      ? CupertinoColors.placeholderText.resolveFrom(context)
                      : CupertinoColors.label.resolveFrom(context),
                ),
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

    final AppLocalizations l10n = context.l10n;
    final bool? shouldLeave = await showAppAlert<bool>(
      context: context,
      title: l10n.unsavedChanges,
      message: l10n.saveBeforeLeaving,
      actions: <AppAlertAction>[
        AppAlertAction(
          label: l10n.cancel,
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: l10n.dontSave,
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(true),
        ),
        AppAlertAction(
          label: l10n.save,
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
    final Locale locale = Localizations.localeOf(context);
    return DateFormat.yMMMMd(locale.toLanguageTag()).format(date);
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
      final StudentDetail detail = await widget.studentService.getStudentDetail(
        widget.studentId,
      );

      StudentBalance? balance;
      String? paymentsError;
      try {
        balance = await widget.studentService.getStudentBalance(
          widget.studentId,
        );
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
      final String studentCost = detail.student.lessonCost?.trim() ?? '';
      if (studentCost.isNotEmpty) {
        _lessonCostController.text = studentCost;
      } else {
        final String? defaultCost = await AppSettings.individualLessonCost();
        _lessonCostController.text = defaultCost ?? '';
      }
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
        _profilePictureUrl = detail.student.profilePictureUrl;
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
      await _showMessage(context.l10n.nameRequired);
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
        await _showMessage(context.l10n.studentUpdated);
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
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showAppAlert<bool>(
      context: context,
      title: l10n.deleteStudent,
      message: l10n.deleteStudentContinue,
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
    final AppLocalizations l10n = context.l10n;
    return showAppAlert<void>(
      context: context,
      title: l10n.student,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
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
  void initState() {
    super.initState();
    _loadDefaultLessonCost();
  }

  Future<void> _loadDefaultLessonCost() async {
    final String? cost = await AppSettings.individualLessonCost();
    if (!mounted || cost == null || cost.isEmpty) {
      return;
    }
    if (_lessonCostController.text.trim().isNotEmpty) {
      return;
    }
    setState(() {
      _lessonCostController.text = cost;
    });
  }

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
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.addStudentTitle),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                        l10n.pickAColor,
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
              l10n.nameAndSurname,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            _formField(
              _phoneController,
              l10n.phone,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showBirthdayPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
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
                            ? l10n.addBirthday
                            : l10n.birthdayColon(
                                _formatBirthdayDisplay(_selectedBirthday!),
                              ),
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
                  Text(
                    l10n.lessonCostColon,
                    style: const TextStyle(
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
            _formField(_notesController, l10n.notes, maxLines: 5, minLines: 4),
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
      await _showErrorDialog(context.l10n.nameRequired);
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
      if (error.isQuota) {
        await openPaywall(
          context,
          token: widget.studentService.token,
          reasonCode: error.code,
        );
      } else {
        await _showErrorDialog(error.message);
      }
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

  String _formatBirthdayDisplay(DateTime date) {
    final Locale locale = Localizations.localeOf(context);
    return DateFormat.yMMMMd(locale.toLanguageTag()).format(date);
  }

  Color get _selectedAvatarColor => Color.fromARGB(255, _red, _green, _blue);

  String _hexFromColor(Color color) {
    final int rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _showAdvancedColorPicker() async {
    final AppLocalizations l10n = context.l10n;
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
                          child: Text(l10n.cancel),
                        ),
                        Expanded(
                          child: Text(
                            l10n.color,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                          child: Text(l10n.done),
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
                              pickerAreaBorderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
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
    final AppLocalizations l10n = context.l10n;
    return showAppAlert<void>(
      context: context,
      title: l10n.students,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }
}
