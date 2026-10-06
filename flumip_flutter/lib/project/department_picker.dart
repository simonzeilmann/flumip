import 'package:flutter/material.dart';

/// Which group a project belongs to.
///
/// ⚠️ **Shown to the owner, not only to administrators** — unlike `OwnerPicker`
/// next to it. Which of their own groups a project belongs to is something the
/// person who made it already knows, and the server refuses a group the caller
/// is not in, so there is nothing here an admin needs to arbitrate.
///
/// The tile renders this only when it was given a non-empty list. An install
/// with no department claim configured collects no groups, so the list is empty
/// and the control is absent altogether rather than offered with nothing in it.
class DepartmentPicker extends StatelessWidget {
  const DepartmentPicker({
    super.key,
    required this.departments,
    required this.department,
    required this.onChanged,
  });

  /// The groups this caller may choose from — their own, plus (for an admin)
  /// every department already in use.
  final List<String> departments;

  /// The project's current department, or null when it is in none.
  final String? department;

  /// Called with the new department, or null to take the project out of one.
  final void Function(String? department) onChanged;

  @override
  Widget build(BuildContext context) {
    // ⚠️ A DropdownButton whose value matches no item throws, and a project can
    // legitimately sit in a department this caller is not in: an admin moved it
    // there, or the group was renamed in the provider. Offer it as an extra
    // item rather than dropping it, so the picker shows the truth instead of
    // silently claiming the project has no department.
    final options = <String>[
      ...departments,
      if (department != null &&
          department!.isNotEmpty &&
          !departments.contains(department))
        department!,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text('Department:'),
          const SizedBox(width: 10),
          Flexible(
            child: DropdownButton<String?>(
              value: department?.isEmpty ?? true ? null : department,
              isExpanded: true,
              onChanged: onChanged,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None — only you and administrators'),
                ),
                for (final name in options)
                  DropdownMenuItem<String?>(
                    value: name,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
