import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

/// Who a project belongs to, shown to administrators only.
///
/// The tile renders this whenever it was given a list of assignable owners, and
/// the tab passes null for everyone else rather than an empty list — so "not an
/// administrator" and "an install with no users yet" stay distinguishable.
class OwnerPicker extends StatelessWidget {
  const OwnerPicker({
    super.key,
    required this.owners,
    required this.ownerId,
    required this.onChanged,
  });

  final List<FlumipUserDto> owners;

  /// The project's current owner, or null when it is unowned.
  final int? ownerId;

  /// Called with the new owner's id, or null to release the project to unowned.
  final void Function(int? ownerId) onChanged;

  @override
  Widget build(BuildContext context) {
    // ⚠️ A DropdownButton whose value matches no item throws, and the project's
    // owner can legitimately be missing from the list: the identity may have been
    // deleted since the project was loaded. Fall back to showing it as unowned,
    // which is what ON DELETE SET NULL will have made it anyway.
    final selected = owners.any((u) => u.id == ownerId) ? ownerId : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text('Owner:'),
          const SizedBox(width: 10),
          DropdownButton<int?>(
            value: selected,
            onChanged: onChanged,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Unowned — shared with everyone'),
              ),
              for (final user in owners)
                DropdownMenuItem<int?>(
                  value: user.id,
                  child: Text(
                    user.displayName.isEmpty ? user.email : user.displayName,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
