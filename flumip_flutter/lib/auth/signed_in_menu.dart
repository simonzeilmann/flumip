import 'package:flutter/material.dart';

import '../ui/layout.dart';
import 'session_auth_key_provider.dart';

/// How much of the app bar the identity label may take before it is cut short.
///
/// An email address has no upper length, and this one shares a bar with a centred
/// title, a search field and a `TabBar`. 220px is about 28 characters at
/// `bodyMedium` — enough for most addresses whole, and a hard ceiling for the rest.
const double _maxLabelWidth = 220;

/// Who is signed in, and the way out.
///
/// ⚠️ **Moved out of `main.dart`, and that is what made the bug below findable.**
/// `main.dart` imports `dart:js_interop`, so nothing that lives in it can be
/// pumped in a VM test — `test/platform_boundary_test.dart` enforces exactly that.
/// This widget sat there with an unconstrained label for as long as it existed.
///
/// Sign-out arrives as a callback rather than being called on the app-wide
/// `authController`, following the convention every controller in this app uses:
/// the dependency is a function, so a test can watch it without a server.
class SignedInMenu extends StatelessWidget {
  const SignedInMenu({super.key, required this.user, required this.onSignOut});

  final SessionTokenResponse user;

  /// Called when the sign-out button is pressed.
  final VoidCallback onSignOut;

  /// The full identity, for the tooltip — which is the only place it appears once
  /// the window is too narrow for the label.
  String get _tooltip =>
      user.isAdmin ? '${user.email} (administrator)' : user.email;

  /// What the label says: a display name when the provider sent one, the address
  /// otherwise.
  String get _label => user.displayName.isEmpty ? user.email : user.displayName;

  @override
  Widget build(BuildContext context) {
    // ⚠️ Below the breakpoint the label is dropped entirely rather than shortened.
    // An ellipsised fragment of an address — `simon.zei…` — costs the width of a
    // word and says nothing the tooltip does not, and on a 375px bar there is no
    // width to spare: a centred title, the search icon and this have to share it.
    // Leaving it in is what overflowed the bar by 29px.
    final room = MediaQuery.sizeOf(context).width >= kSplitWidth;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (room)
          // ⚠️ `ConstrainedBox`, not `Flexible`. This `Row` sits inside the one
          // `AppBar` builds for `actions`, and a `Flexible` needs a bounded width
          // from its parent to resolve against — which an action slot does not
          // promise. A hard ceiling plus an ellipsis cannot overflow whatever the
          // parent passes down, which is the property worth having here.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxLabelWidth),
            child: Tooltip(
              message: _tooltip,
              child: Text(_label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          // Carries the identity when the label is gone, so who is signed in stays
          // answerable on a narrow window.
          tooltip: room ? 'Sign out' : 'Sign out — $_tooltip',
          onPressed: onSignOut,
        ),
      ],
    );
  }
}

/// What a guest on a public instance sees where [SignedInMenu] would be.
///
/// No sign-out: a guest's projects are tied to this browser's cookie, and
/// throwing it away would lose them with no way back except their share links.
/// Instead, the way for an administrator to sign in, when the server offers one.
class GuestMenu extends StatelessWidget {
  const GuestMenu({super.key, this.onSignIn});

  /// Starts an administrator's sign-in, or null when the server cannot do one.
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final room = MediaQuery.sizeOf(context).width >= kSplitWidth;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (room)
          const Tooltip(
            message:
                'Your projects are kept in this browser. Use a project\'s '
                'share link to open it anywhere else.',
            child: Text('Guest'),
          ),
        if (onSignIn != null)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Administrator sign-in',
            onPressed: onSignIn,
          ),
      ],
    );
  }
}
