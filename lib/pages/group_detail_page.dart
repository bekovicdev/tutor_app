import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:tutor_app/groups/group_service.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/pages/paywall_page.dart';
import 'package:tutor_app/pages/students_page.dart';
import 'package:tutor_app/settings/app_settings.dart';
import 'package:tutor_app/students/student_service.dart';
import 'package:tutor_app/theme/app_dialogs.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({
    required this.group,
    required this.groupService,
    required this.studentService,
    super.key,
  });

  final TutorGroup group;
  final GroupService groupService;
  final StudentService studentService;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late TutorGroup _group;
  List<GroupStudent> _members = <GroupStudent>[];
  bool _isLoading = true;
  String? _errorMessage;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_group.name),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(_changed),
          child: Text(context.l10n.back),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showGroupActions,
          child: const Icon(CupertinoIcons.ellipsis_circle),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            _buildBody(),
            Positioned(
              right: 16,
              bottom: 12,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showAddStudentSheet,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppBrand.primary,
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_members.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noStudentsInGroup,
          style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final GroupStudent item = _members[index];
        final Student student = item.student;
        final Color accent = _parseHexColor(student.color);
        return Dismissible(
          key: ValueKey<int>(student.id),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: const Icon(
              CupertinoIcons.delete,
              color: CupertinoColors.white,
            ),
          ),
          confirmDismiss: (_) => _confirmRemove(student),
          onDismissed: (_) {
            setState(() {
              _members = _members
                  .where((GroupStudent m) => m.student.id != student.id)
                  .toList();
            });
            _changed = true;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openStudentDetail(student.id),
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
                        CupertinoIcons.person_fill,
                        size: 18,
                        color: accent,
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
                        if (item.pivotStatus == 0) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.inactiveInGroup,
                            style: const TextStyle(
                              color: CupertinoColors.systemOrange,
                              fontSize: 13,
                            ),
                          ),
                        ] else if (student.phone != null &&
                            student.phone!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            student.phone!,
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ],
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
          ),
        );
      },
    );
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<GroupStudent> members = await widget.groupService
          .listGroupStudents(_group.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _members = members;
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

  Future<void> _showAddStudentSheet() async {
    List<Student> allStudents;
    try {
      allStudents = await widget.studentService.listStudents();
    } on StudentServiceException catch (error) {
      await _showMessage(error.message);
      return;
    }
    if (!mounted) {
      return;
    }

    final Set<int> existingIds = _members
        .map((GroupStudent m) => m.student.id)
        .toSet();
    final List<Student> candidates = allStudents
        .where((Student s) => !existingIds.contains(s.id))
        .toList();

    if (candidates.isEmpty) {
      await _showMessage(context.l10n.allStudentsAlreadyInGroup);
      return;
    }

    await showAppActionSheet<void>(
      context: context,
      title: context.l10n.addToGroup(_group.name),
      message: context.l10n.chooseStudentToAdd,
      actions: candidates
          .map(
            (Student student) => AppSheetAction(
              label: student.name,
              onPressed: (BuildContext ctx) async {
                Navigator.of(ctx).pop();
                await _addStudent(student);
              },
            ),
          )
          .toList(),
    );
  }

  Future<void> _addStudent(Student student) async {
    try {
      await widget.groupService.addStudentToGroup(
        groupId: _group.id,
        studentId: student.id,
      );
      _changed = true;
      await _loadMembers();
    } on GroupServiceException catch (error) {
      await _showMessage(error.message);
    }
  }

  Future<void> _openStudentDetail(int studentId) async {
    final bool? changed = await openStudentDetailPage(
      context,
      studentId: studentId,
      studentService: widget.studentService,
    );
    if (changed == true) {
      _changed = true;
      await _loadMembers();
    }
  }

  Future<bool> _confirmRemove(Student student) async {
    final bool? shouldRemove = await showAppAlert<bool>(
      context: context,
      title: context.l10n.removeFromGroup,
      message: context.l10n.removeStudentFromGroup(student.name, _group.name),
      actions: <AppAlertAction>[
        AppAlertAction(
          label: context.l10n.cancel,
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: context.l10n.remove,
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext ctx) async {
            try {
              await widget.groupService.removeStudentFromGroup(
                groupId: _group.id,
                studentId: student.id,
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop(true);
              }
            } on GroupServiceException catch (error) {
              if (mounted) {
                await _showMessage(error.message);
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop(false);
              }
            }
          },
        ),
      ],
    );
    return shouldRemove == true;
  }

  Future<void> _showGroupActions() async {
    await showAppActionSheet<void>(
      context: context,
      title: _group.name,
      actions: <AppSheetAction>[
        AppSheetAction(
          label: context.l10n.editGroup,
          onPressed: (BuildContext ctx) {
            Navigator.of(ctx).pop();
            _showEditGroupSheet();
          },
        ),
        AppSheetAction(
          label: context.l10n.deleteGroup,
          isDestructive: true,
          onPressed: (BuildContext ctx) {
            Navigator.of(ctx).pop();
            _confirmDeleteGroup();
          },
        ),
      ],
    );
  }

  Future<void> _showEditGroupSheet() async {
    final TutorGroup? updated = await Navigator.of(context).push<TutorGroup>(
      CupertinoPageRoute<TutorGroup>(
        builder: (_) => CreateGroupPage(
          groupService: widget.groupService,
          group: _group,
        ),
      ),
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _group = updated;
    });
    _changed = true;
  }

  Future<void> _confirmDeleteGroup() async {
    final bool? confirmed = await showAppAlert<bool>(
      context: context,
      title: context.l10n.deleteGroup,
      message: context.l10n.deleteGroupConfirm(_group.name),
      actions: <AppAlertAction>[
        AppAlertAction(
          label: context.l10n.cancel,
          style: AppAlertStyle.cancel,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(false),
        ),
        AppAlertAction(
          label: context.l10n.delete,
          style: AppAlertStyle.destructive,
          onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(true),
        ),
      ],
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.groupService.deleteGroup(_group.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on GroupServiceException catch (error) {
      await _showMessage(error.message);
    }
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

  Future<void> _showMessage(String message) {
    return showAppAlert<void>(
      context: context,
      title: context.l10n.group,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }
}

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({
    required this.groupService,
    this.group,
    super.key,
  });

  final GroupService groupService;
  final TutorGroup? group;

  bool get isEditing => group != null;

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _lessonCostController;
  late int _red;
  late int _green;
  late int _blue;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final TutorGroup? group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _lessonCostController = TextEditingController(
      text: group?.lessonCost?.trim() ?? '',
    );
    final Color initial = _parseHexColor(group?.color);
    _red = (initial.r * 255.0).round() & 0xff;
    _green = (initial.g * 255.0).round() & 0xff;
    _blue = (initial.b * 255.0).round() & 0xff;
    if (!widget.isEditing) {
      _loadDefaultLessonCost();
    }
  }

  Future<void> _loadDefaultLessonCost() async {
    final String? cost = await AppSettings.groupLessonCost();
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
    _lessonCostController.dispose();
    super.dispose();
  }

  Color get _selectedColor => Color.fromARGB(255, _red, _green, _blue);

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return const Color.fromARGB(255, 52, 199, 89);
    }
    final String value = hex.replaceAll('#', '').trim();
    if (value.length != 6) {
      return const Color.fromARGB(255, 52, 199, 89);
    }
    final int? rgb = int.tryParse(value, radix: 16);
    if (rgb == null) {
      return const Color.fromARGB(255, 52, 199, 89);
    }
    return Color.fromARGB(
      255,
      (rgb >> 16) & 0xFF,
      (rgb >> 8) & 0xFF,
      rgb & 0xFF,
    );
  }

  String _hexFromColor(Color color) {
    final int rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.isEditing ? l10n.editGroup : l10n.addGroupTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
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
                  color: _selectedColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: _selectedColor, width: 2),
                ),
                child: Icon(
                  CupertinoIcons.person_3_fill,
                  size: 42,
                  color: _selectedColor,
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
                  color: CupertinoColors.secondarySystemGroupedBackground
                      .resolveFrom(context),
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
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CupertinoColors.separator
                              .resolveFrom(context)
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.pickAColor,
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _nameController,
              placeholder: l10n.groupName,
              textAlign: TextAlign.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w500,
              ),
              placeholderStyle: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground
                    .resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.separator
                      .resolveFrom(context)
                      .withValues(alpha: 0.35),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground
                    .resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.separator
                      .resolveFrom(context)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    l10n.lessonCostColon,
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
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
                      textAlign: TextAlign.left,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      style: TextStyle(
                        color: CupertinoColors.label.resolveFrom(context),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemFill
                            .resolveFrom(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAdvancedColorPicker() async {
    final AppLocalizations l10n = context.l10n;
    Color tempColor = _selectedColor;

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
                              _red = (tempColor.r * 255.0).round() & 0xff;
                              _green = (tempColor.g * 255.0).round() & 0xff;
                              _blue = (tempColor.b * 255.0).round() & 0xff;
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
                          color: CupertinoColors.separator
                              .resolveFrom(context)
                              .withValues(alpha: 0.45),
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hexFromColor(tempColor),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors
                              .secondarySystemGroupedBackground
                              .resolveFrom(context),
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

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      await _showMessage(context.l10n.nameRequired);
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    final String name = _nameController.text.trim();
    final String color = _hexFromColor(_selectedColor);
    final String lessonCost = _lessonCostController.text.trim();
    try {
      if (widget.isEditing) {
        final TutorGroup existing = widget.group!;
        await widget.groupService.updateGroup(
          id: existing.id,
          request: GroupCreateRequest(
            name: name,
            color: color,
            status: existing.status,
            lessonCost: lessonCost,
          ),
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(
          TutorGroup(
            id: existing.id,
            name: name,
            color: color,
            status: existing.status,
            lessonCost: lessonCost.isEmpty ? null : lessonCost,
          ),
        );
      } else {
        await widget.groupService.createGroup(
          GroupCreateRequest(
            name: name,
            color: color,
            status: 1,
            lessonCost: lessonCost,
          ),
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(true);
      }
    } on GroupServiceException catch (error) {
      if (error.isQuota) {
        await openPaywall(
          context,
          token: widget.groupService.token,
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

  Future<void> _showMessage(String message) {
    return showAppAlert<void>(
      context: context,
      title: context.l10n.group,
      message: message,
      actions: <AppAlertAction>[
        AppAlertAction(label: context.l10n.ok, style: AppAlertStyle.primary),
      ],
    );
  }
}
