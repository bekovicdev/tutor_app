import 'package:flutter/cupertino.dart';
import 'package:tutor_app/groups/group_service.dart';
import 'package:tutor_app/students/student_service.dart';

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
          child: const Text('Back'),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_members.isEmpty) {
      return const Center(
        child: Text(
          'No students in this group.',
          style: TextStyle(color: CupertinoColors.systemGrey),
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
                        const Text(
                          'Inactive in group',
                          style: TextStyle(
                            color: CupertinoColors.systemOrange,
                            fontSize: 13,
                          ),
                        ),
                      ] else if (student.phone != null &&
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
              ],
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
      final List<GroupStudent> members =
          await widget.groupService.listGroupStudents(_group.id);
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

    final Set<int> existingIds =
        _members.map((GroupStudent m) => m.student.id).toSet();
    final List<Student> candidates = allStudents
        .where((Student s) => !existingIds.contains(s.id))
        .toList();

    if (candidates.isEmpty) {
      await _showMessage('All students are already in this group.');
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text('Add to ${_group.name}'),
          message: const Text('Choose a student to add to this group.'),
          actions: candidates.map((Student student) {
            return CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                await _addStudent(student);
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

  Future<bool> _confirmRemove(Student student) async {
    bool? shouldRemove;
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Remove from Group'),
          content: Text('Remove ${student.name} from ${_group.name}?'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                shouldRemove = false;
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                try {
                  await widget.groupService.removeStudentFromGroup(
                    groupId: _group.id,
                    studentId: student.id,
                  );
                  shouldRemove = true;
                } on GroupServiceException catch (error) {
                  shouldRemove = false;
                  if (mounted) {
                    await _showMessage(error.message);
                  }
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    return shouldRemove == true;
  }

  Future<void> _showGroupActions() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(_group.name),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditGroupSheet();
              },
              child: const Text('Edit Group'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                _confirmDeleteGroup();
              },
              child: const Text('Delete Group'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _showEditGroupSheet() async {
    final TextEditingController nameController =
        TextEditingController(text: _group.name);
    final TextEditingController colorController =
        TextEditingController(text: _group.color ?? '');

    final bool? saved = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Edit Group'),
          content: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: nameController,
                placeholder: 'Group name',
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: colorController,
                placeholder: 'Color (#33FF57)',
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) {
      nameController.dispose();
      colorController.dispose();
      return;
    }

    final String name = nameController.text.trim();
    final String color = colorController.text.trim();
    nameController.dispose();
    colorController.dispose();

    if (name.isEmpty) {
      await _showMessage('Name is required.');
      return;
    }

    try {
      await widget.groupService.updateGroup(
        id: _group.id,
        request: GroupCreateRequest(
          name: name,
          color: color,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _group = TutorGroup(
          id: _group.id,
          name: name,
          color: color.isEmpty ? _group.color : color,
          status: _group.status,
        );
      });
      _changed = true;
    } on GroupServiceException catch (error) {
      await _showMessage(error.message);
    }
  }

  Future<void> _confirmDeleteGroup() async {
    bool confirmed = false;
    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Group'),
          content: Text(
            'Delete ${_group.name}? This will set status to inactive.',
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
    return Color.fromARGB(
      255,
      (rgb >> 16) & 0xFF,
      (rgb >> 8) & 0xFF,
      rgb & 0xFF,
    );
  }

  Future<void> _showMessage(String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Group'),
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

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({
    required this.groupService,
    super.key,
  });

  final GroupService groupService;

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  int _red = 52;
  int _green = 199;
  int _blue = 89;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color get _selectedColor => Color.fromARGB(255, _red, _green, _blue);

  String _hexFromColor(Color color) {
    final int rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add Group'),
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
                  color: _selectedColor.withOpacity(0.2),
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
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _nameController,
              placeholder: 'Group name',
              textAlign: TextAlign.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.systemGrey4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            _colorSlider('R', _red, (int v) => setState(() => _red = v)),
            _colorSlider('G', _green, (int v) => setState(() => _green = v)),
            _colorSlider('B', _blue, (int v) => setState(() => _blue = v)),
            const SizedBox(height: 8),
            Text(
              _hexFromColor(_selectedColor),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorSlider(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 24,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: CupertinoSlider(
            min: 0,
            max: 255,
            value: value.toDouble(),
            onChanged: (double v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text('$value', textAlign: TextAlign.end),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      await _showMessage('Name is required.');
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      await widget.groupService.createGroup(
        GroupCreateRequest(
          name: _nameController.text.trim(),
          color: _hexFromColor(_selectedColor),
          status: 1,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on GroupServiceException catch (error) {
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
          title: const Text('Group'),
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
