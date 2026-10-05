import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/projects_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The projects list, with the server replaced by closures.
///
/// ⚠️ The first test in this app to cover a tab's own logic. Everything here used
/// to live in `_ProjectsTabState`, which imported `main.dart` — so none of it
/// could be reached, and the optimistic delete below (the fix for the "zombie
/// row" complaint) had no coverage at all.
Project projectFixture({required int id, DateTime? created}) => Project(
  id: id,
  name: 'p$id',
  description: '',
  bedFileCreated: false,
  active: false,
  error: '',
  warning: '',
  size: 0,
  options: 1,
  created: created ?? DateTime(2026, 1, id),
);

FlumipUserDto userFixture(int id) =>
    FlumipUserDto(id: id, email: 'u$id@example.com', displayName: 'User $id');

/// A controller wired to fakes, with knobs for what each call does.
class Harness {
  Harness({
    this.projects = const [],
    this.admin = false,
    this.notifications = true,
    this.owners = const [],
  });

  List<Project> projects;
  bool admin;
  bool notifications;
  List<FlumipUserDto> owners;

  Object? loadThrows;
  Object? deleteThrows;
  Object? ownerThrows;
  Object? departmentThrows;
  List<String> assignableDepartments = const [];
  Object? notificationsThrows;
  Object? ownersThrows;

  final calls = <String>[];
  final auth = ChangeNotifier();

  late final ProjectsController controller = ProjectsController(
    loadProjects: () async {
      calls.add('load');
      if (loadThrows != null) throw loadThrows!;
      return projects;
    },
    deleteProject: (id) async {
      calls.add('delete $id');
      if (deleteThrows != null) throw deleteThrows!;
      projects = projects.where((p) => p.id != id).toList();
    },
    setOwner: (id, ownerId) async {
      calls.add('owner $id -> $ownerId');
      if (ownerThrows != null) throw ownerThrows!;
    },
    setDepartment: (id, department) async {
      calls.add('department $id -> $department');
      if (departmentThrows != null) throw departmentThrows!;
    },
    loadAssignableDepartments: () async {
      calls.add('departments?');
      return assignableDepartments;
    },
    loadNotificationsAvailable: () async {
      calls.add('notifications');
      if (notificationsThrows != null) throw notificationsThrows!;
      return notifications;
    },
    loadAssignableOwners: () async {
      calls.add('owners');
      if (ownersThrows != null) throw ownersThrows!;
      return owners;
    },
    isAdmin: () => admin,
    auth: auth,
  );
}

void main() {
  group('loading', () {
    test('starts out loading, then holds the list', () async {
      final h = Harness(projects: [projectFixture(id: 1)]);
      expect(h.controller.loading, isTrue);

      await h.controller.load();

      expect(h.controller.loading, isFalse);
      expect(h.controller.projects, hasLength(1));
      expect(h.controller.errorMessage, isNull);
    });

    test('newest first', () async {
      final h = Harness(
        projects: [
          projectFixture(id: 1, created: DateTime(2026, 1, 1)),
          projectFixture(id: 3, created: DateTime(2026, 3, 1)),
          projectFixture(id: 2, created: DateTime(2026, 2, 1)),
        ],
      );

      await h.controller.load();

      expect(h.controller.projects!.map((p) => p.id), [3, 2, 1]);
    });

    test('⚠️ sorts a copy, never the caller\'s list', () async {
      // An endpoint returning an unmodifiable list would throw, and a cached one
      // would be reordered underneath whoever else holds it. Same bug the genome
      // picker had.
      final original = <Project>[
        projectFixture(id: 1, created: DateTime(2026, 1, 1)),
        projectFixture(id: 2, created: DateTime(2026, 2, 1)),
      ];
      final h = Harness(projects: List.unmodifiable(original));

      await h.controller.load();

      expect(h.controller.projects!.map((p) => p.id), [2, 1]);
      expect(original.map((p) => p.id), [1, 2], reason: 'caller untouched');
    });

    test('a failure is reported and stops the spinner', () async {
      final h = Harness()..loadThrows = Exception('no route to host');

      await h.controller.load();

      expect(h.controller.loading, isFalse);
      expect(h.controller.errorMessage, isNotNull);
      expect(h.controller.projects, isNull);
    });

    test('a later success clears the error', () async {
      final h = Harness()..loadThrows = Exception('down');
      await h.controller.load();
      expect(h.controller.errorMessage, isNotNull);

      h
        ..loadThrows = null
        ..projects = [projectFixture(id: 1)];
      await h.controller.refresh();

      expect(h.controller.errorMessage, isNull);
      expect(h.controller.projects, hasLength(1));
    });
  });

  group('deleting', () {
    test('⚠️ the row goes before the server answers', () async {
      // The reported complaint. The server removes a multi-gigabyte directory
      // before it replies, and waiting for that left the deleted row on screen
      // looking untouched for seconds.
      final h = Harness(
        projects: [projectFixture(id: 1), projectFixture(id: 2)],
      );
      await h.controller.load();

      final pending = h.controller.delete(1);

      expect(h.controller.projects!.map((p) => p.id), [
        2,
      ], reason: 'gone already, without awaiting the delete');
      await pending;
      expect(h.controller.projects!.map((p) => p.id), [2]);
    });

    test('⚠️ a refused delete puts the row back', () async {
      final h = Harness(
        projects: [projectFixture(id: 1), projectFixture(id: 2)],
      )..deleteThrows = Exception('not yours');
      await h.controller.load();

      await h.controller.delete(1);

      expect(h.controller.projects!.map((p) => p.id), [2, 1]);
      expect(h.controller.errorMessage, contains('not yours'));
    });
  });

  group('reassigning an owner', () {
    test('sends the new owner and reloads', () async {
      final h = Harness(projects: [projectFixture(id: 1)]);
      await h.controller.load();
      h.calls.clear();

      await h.controller.setOwner(1, 7);

      expect(h.calls, ['owner 1 -> 7', 'load']);
    });

    test('null releases the project to unowned', () async {
      final h = Harness(projects: [projectFixture(id: 1)]);
      await h.controller.load();
      h.calls.clear();

      await h.controller.setOwner(1, null);

      expect(h.calls.first, 'owner 1 -> null');
    });

    test('a refusal is reported', () async {
      final h = Harness()..ownerThrows = Exception('not an administrator');
      await h.controller.load();

      await h.controller.setOwner(1, 7);

      expect(h.controller.errorMessage, contains('not an administrator'));
    });
  });

  group('who may reassign', () {
    test('⚠️ a non-administrator never asks for the owner list', () async {
      // The endpoint refuses non-admins, so asking would log a refusal on every
      // ordinary page load.
      final h = Harness(admin: false);

      await h.controller.load();

      expect(h.calls, isNot(contains('owners')));
      expect(h.controller.assignableOwners, isNull);
    });

    test('an administrator gets the list', () async {
      final h = Harness(admin: true, owners: [userFixture(7)]);

      await h.controller.load();

      expect(h.controller.assignableOwners, hasLength(1));
    });

    test('⚠️ null and empty are different answers', () async {
      // The tile hides the picker on null and shows "unowned only" on empty.
      final h = Harness(admin: true, owners: const []);

      await h.controller.load();

      expect(h.controller.assignableOwners, isEmpty);
      expect(h.controller.assignableOwners, isNotNull);
    });

    test('signing in later fetches the list that was skipped', () async {
      // TabBarView builds every tab before the bearer token exists, so the first
      // answer describes an anonymous caller.
      final h = Harness(admin: false, owners: [userFixture(7)]);
      await h.controller.load();
      expect(h.controller.assignableOwners, isNull);

      h.admin = true;
      h.auth.notifyListeners();
      await pumpEventQueue();

      expect(h.controller.assignableOwners, hasLength(1));
    });

    test('a failed owner lookup leaves the projects alone', () async {
      final h = Harness(admin: true, projects: [projectFixture(id: 1)])
        ..ownersThrows = Exception('refused');

      await h.controller.load();

      expect(h.controller.assignableOwners, isNull);
      expect(h.controller.projects, hasLength(1));
      expect(h.controller.errorMessage, isNull);
    });
  });

  group('the notification switch', () {
    test('follows what the server says', () async {
      final h = Harness(notifications: true);
      await h.controller.load();
      expect(h.controller.notificationsAvailable, isTrue);
    });

    test('⚠️ stays off when the question fails', () async {
      // The safe direction: it costs a control, never a notification, because
      // what is actually sent is decided on the server's send path.
      final h = Harness()..notificationsThrows = Exception('down');

      await h.controller.load();

      expect(h.controller.notificationsAvailable, isFalse);
      expect(h.controller.errorMessage, isNull, reason: 'not worth a banner');
    });
  });

  test('a new project is marked to open, and the list reloads', () async {
    final h = Harness();
    await h.controller.load();
    h.projects = [projectFixture(id: 9)];

    await h.controller.projectCreated(projectFixture(id: 9));

    expect(h.controller.openProjectId, 9);
    expect(h.controller.projects, hasLength(1));
  });

  group('revealing a project from a search result', () {
    /// Three projects, oldest id first so the newest-first sort has work to do.
    Future<Harness> loaded() async {
      final h = Harness(
        projects: [
          projectFixture(id: 1, created: DateTime(2026, 1, 1)),
          projectFixture(id: 2, created: DateTime(2026, 2, 1)),
          projectFixture(id: 3, created: DateTime(2026, 3, 1)),
        ],
      );
      await h.controller.load();
      expect(h.controller.projects!.map((p) => p.id), [3, 2, 1]);
      return h;
    }

    test('it opens the project and hoists it to the top', () async {
      final h = await loaded();

      h.controller.reveal(1);

      expect(h.controller.openProjectId, 1);
      // ⚠️ Hoisted rather than scrolled to: the tab is a `ListView.builder`, so a
      // row below the fold has no element for `ensureVisible` to aim at.
      expect(h.controller.projects!.map((p) => p.id), [1, 3, 2]);
    });

    test(
      'revealing the project that is already first changes no order',
      () async {
        final h = await loaded();

        h.controller.reveal(3);

        expect(h.controller.projects!.map((p) => p.id), [3, 2, 1]);
      },
    );

    test('⚠️ a later refresh keeps the revealed project first', () async {
      // The list re-reads itself every minute while a design is running. Without
      // the hoist in the sort, that tick would drop the revealed row back into
      // date order under somebody who is reading it.
      final h = await loaded();
      h.controller.reveal(1);

      await h.controller.refresh();

      expect(h.controller.projects!.map((p) => p.id), [1, 3, 2]);
    });

    test(
      'revealing a project that is not in the list leaves the order alone',
      () async {
        final h = await loaded();

        h.controller.reveal(99);

        expect(h.controller.openProjectId, 99);
        expect(h.controller.projects!.map((p) => p.id), [3, 2, 1]);
      },
    );
  });

  group('⚠️ the overview keeps up with a running design', () {
    // Reported: a design that finished while its tile was shut went on reading
    // "Designing" until somebody opened it. The tile polls every three seconds
    // but only while open, so the collapsed row's pill had nothing driving it.
    Project running() => projectFixture(id: 1)
      ..bedFileCreated = true
      ..active = true;

    test('a running project starts the list poll', () async {
      final h = Harness(projects: [running()]);
      addTearDown(h.controller.dispose);

      await h.controller.load();

      expect(h.controller.polling, isTrue);
      expect(
        ProjectsController.runningPollInterval,
        const Duration(minutes: 1),
      );
    });

    test('a list with nothing running does not poll', () async {
      final h = Harness(projects: [projectFixture(id: 1)]);
      addTearDown(h.controller.dispose);

      await h.controller.load();

      expect(h.controller.polling, isFalse);
    });

    test('the poll stops once the design finishes', () async {
      final h = Harness(projects: [running()]);
      addTearDown(h.controller.dispose);
      await h.controller.load();
      expect(h.controller.polling, isTrue);

      h.projects = [
        projectFixture(id: 1)
          ..bedFileCreated = true
          ..completedIn = const Duration(minutes: 5),
      ];
      await h.controller.refresh();

      expect(h.controller.polling, isFalse);
    });

    test('a failed load does not leave it polling forever', () async {
      final h = Harness(projects: [running()]);
      addTearDown(h.controller.dispose);
      await h.controller.load();

      h.loadThrows = Exception('down');
      await h.controller.refresh();

      // The list is unchanged, so the running project is still there and still
      // worth watching — but the timer must have been re-armed, not doubled.
      expect(h.controller.polling, isTrue);
    });
  });

  test('the error can be dismissed', () async {
    final h = Harness()..loadThrows = Exception('down');
    await h.controller.load();

    h.controller.dismissError();

    expect(h.controller.errorMessage, isNull);
  });

  test('⚠️ a call landing after dispose does not throw', () async {
    // Every method awaits at least one round trip, and the tab can go away while
    // one is in flight. Notifying a disposed ChangeNotifier throws, and Flutter
    // paints that over the whole tab.
    final h = Harness(projects: [projectFixture(id: 1)]);
    final pending = h.controller.refresh();
    h.controller.dispose();

    await expectLater(pending, completes);
  });
}
