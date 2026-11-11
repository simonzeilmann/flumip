import 'package:flumip_client/flumip_client.dart';
import 'package:material_ui/material_ui.dart';

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
    this.publicMode = false,
  });

  final List<FlumipUserDto> owners;

  /// The project's current owner, or null when it is unowned.
  final int? ownerId;

  /// Called with the new owner's id, or null to release the project to unowned.
  final void Function(int? ownerId) onChanged;

  /// Whether this is a public instance, where unowned means the opposite of
  /// what it means on an internal install: visible to administrators only, not
  /// to everyone. The label for "no owner" has to say which.
  final bool publicMode;

  @override
  Widget build(BuildContext context) {
    // ⚠️ A DropdownButton whose value matches no item throws, and the project's
    // owner can legitimately be missing from the list: the identity may have been
    // deleted since the project was loaded. Fall back to showing it as unowned,
    // which is what ON DELETE SET NULL will have made it anyway.
    final selected = owners.any((u) => u.id == ownerId) ? ownerId : null;

    // Of the guests, only the one who owns this project. A public instance has
    // one guest per visitor, far more than the people an administrator would
    // hand a project to, and nothing but an id to tell them apart. The current
    // owner stays so the picker still says whose project this is. Listed last:
    // the server orders by age of account, which interleaves the two.
    final listed = [
      ...owners.where((u) => !u.isGuest),
      ...owners.where((u) => u.isGuest && u.id == ownerId),
    ];

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
              DropdownMenuItem<int?>(
                value: null,
                child: Text(unownedLabel(publicMode: publicMode)),
              ),
              for (final user in listed)
                DropdownMenuItem<int?>(
                  value: user.id,
                  child: Text(ownerLabel(user)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What the picker calls a user: their name, else their address.
///
/// A guest on a public instance has neither, so it is named by its id — the
/// only thing that tells one guest from another. The fallback covers an
/// identity provider that sent no name and no address, which would otherwise
/// be an empty row as well.
String ownerLabel(FlumipUserDto user) {
  if (user.displayName.isNotEmpty) return user.displayName;
  if (user.email.isNotEmpty) return user.email;
  return user.isGuest ? 'Guest #${user.id}' : 'User #${user.id}';
}

/// What the picker calls a project with no owner.
///
/// ⚠️ Not the same thing on the two kinds of install. Internally an unowned
/// project is open to everyone who signs in. On a public instance only
/// administrators see it (`projectIsAccessible` on the server), because there
/// it is what a guest's project becomes once the guest is gone — so releasing
/// one hides it from the person who had it, and the label must not promise the
/// reverse.
String unownedLabel({required bool publicMode}) => publicMode
    ? 'Unowned — administrators only'
    : 'Unowned — shared with everyone';
