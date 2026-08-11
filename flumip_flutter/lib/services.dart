import 'package:flumip_client/flumip_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'access_controller.dart';
import 'api_config.dart';
import 'auth/auth_controller.dart';
import 'genome/genome_controller.dart';
import 'project/new_project_controller.dart';
import 'project/project_tile_controller.dart';
import 'project/projects_controller.dart';
import 'settings/settings_controller.dart';
import 'snp/picked_file.dart';
import 'snp/snp_section_controller.dart';
import 'snp/snp_transport.dart';
import 'snp/snp_upload_controller.dart';

/// The app-wide singletons, in a file that compiles on the Dart VM.
///
/// ⚠️ **This file exists to be importable from a test, and the rule that keeps
/// it that way is: no `dart:js_interop`, no `package:web`, and nothing that
/// imports them.** Those libraries exist only when compiling to JavaScript or
/// Wasm; `flutter test` compiles for the VM, where importing one is a
/// *compile-time* error:
///
///     lib/main.dart:2:8: Error: Dart library 'dart:js_interop' is not
///     available on this platform.
///
/// That error is why these lived in `main.dart` and why nothing that touched
/// them could be tested. Seven files imported `main.dart` for `client` and
/// `siteUrl` — every tab among them — and each inherited the same wall. Moving
/// the singletons here and leaving the browser wiring in `main.dart` is what
/// takes the wall down; it does not, on its own, make [client] substitutable
/// (see the note there).
///
/// The three values below are computed rather than injected because
/// `api_config.dart` is already VM-safe: it branches on `kIsWeb` from
/// `foundation`, and off the web it returns the development fallbacks the unit
/// tests already assert on.
final String apiUrl = resolveApiUrl();

/// Origin the app was served from, which is also the web server's — so it is
/// where the `/auth/*` routes and the session cookie live. See `api_config.dart`.
final String siteUrl = resolveSiteUrl();

/// Whether this build can upload at all.
///
/// False during a `flutter run`, where the app and the web server are different
/// origins — the same reason sign-in does not work there.
final bool uploadsAvailable = resolveUploadsAvailable();

/// The Serverpod client every endpoint call goes through.
///
/// ⚠️ Still a mutable global, deliberately: making it substitutable is a
/// separate change with real design choices in it. A `var` rather than a `final`
/// at least means a test *can* assign a fake before pumping a widget — which is
/// how this would be used before something better exists.
var client = Client(apiUrl)..connectivityMonitor = FlutterConnectivityMonitor();

/// Sign-in state for the whole app.
late AuthController authController;

/// What this caller may do, asked of the server rather than inferred.
late AccessController accessController;

/// Browser uploads of custom SNP files.
///
/// ⚠️ App-wide rather than owned by a widget, because an upload takes minutes
/// and has to survive the dialog closing, the tab changing, and `TabBarView`
/// rebuilding. None of those should cancel a transfer somebody started.
late SnpUploadController snpUploads;

/// The projects list and everything that changes it.
///
/// ⚠️ App-wide rather than owned by `ProjectsTab`, because `TabBarView` can
/// rebuild the tab and reloading the whole list on every tab switch is both slow
/// and visibly flickery. The tab takes an optional controller so a test can hand
/// it one built from fakes.
late ProjectsController projectsController;

/// A controller for the genome tab, wired to the real client.
///
/// ⚠️ A factory rather than a singleton, unlike [projectsController]. The genome
/// controller holds a poll timer for the genome being looked at, and one shared
/// instance would keep polling while somebody is on another tab. `GenomeTab`
/// makes one, owns it and disposes it.
GenomeController createGenomeController() => GenomeController(
  loadCategories: () => client.genome.getCategories(),
  loadGenomes: (category) => client.genome.getGenomeByCategory(category),
  loadGenome: (id) => client.genome.getGenome(id),
  indexGenome: (id) => client.genome.indexFasta(id),
  deleteIndex: (id) => client.genome.deleteFastaIndex(id),
  updateGenome: (id, genome) => client.genome.updateGenome(id, genome),
  scanForGenomes: () => client.genome.collectGenomes(),
  recheckSnpSets: () => client.snp.collectCustomSnps(),
);

/// A controller for one genome's SNP list, wired to the real client.
///
/// ⚠️ A factory, like [createGenomeController] and for the same reason: it holds
/// a poll for the sets on screen. [snpUploads] is passed through rather than
/// recreated — a transfer has to outlive the section that started it.
SnpSectionController createSnpSectionController(int genomeId) =>
    SnpSectionController(
      genomeId: genomeId,
      loadSnps: (id) => client.snp.listSnpsForGenome(id),
      loadMySnps: () => client.snp.listMySnps(),
      setShared: (id, shared) => client.snp.setShared(id, shared),
      rename: (id, name, description) =>
          client.snp.renameSnp(id, name, description),
      retryImport: (id) => client.snp.retryImport(id),
      cancelUpload: (id) => client.snp.cancelUpload(id),
      deleteSnp: (id) => client.snp.deleteCustomSnp(id),
      deleteAsAdmin: (id, password, {required force}) =>
          client.snp.deleteSnpAsAdmin(id, password, force: force),
      loadUsage: (id) => client.snp.snpUsage(id),
      importFromUrls: (request) => client.snp.importFromUrls(request),
      createUpload: (request) => client.snp.createUpload(request),
      uploads: snpUploads,
      isAdmin: () => accessController.isAdmin,
      auth: authController,
      access: accessController,
    );

/// Server configuration and who may see it.
///
/// ⚠️ App-wide, like [projectsController]: it holds the settings password typed
/// into the gate, and a per-tab instance would ask for it again on every tab
/// switch. Never disposed — disposing it would take the form's controllers with
/// it, that password included.
late SettingsController settingsController;

/// A controller for one project row, wired to the real client.
///
/// ⚠️ A factory: there is one of these per row and each holds its own poll.
ProjectTileController createProjectTileController(
  Project project, {
  required bool expanded,
}) => ProjectTileController(
  project: project,
  expanded: expanded,
  loadProject: (id) => client.project.getProject(id),
  loadOptions: (id) => client.options.getProjectOptions(id),
  loadGenome: (id) => client.genome.getGenome(id),
  loadSnp: (id) => client.genome.getSnp(id),
  loadProgress: (id) => client.file.showMipsProgress(id),
  addGene: (id, gene) => client.project.addGeneToProject(id, gene),
  removeGene: (id, gene) => client.project.removeGeneFromProject(id, gene),
  createBedFile: (id) => client.mipgen.createBedFile(id),
  generateMips: (id, deleteExcessFiles) =>
      client.mipgen.generateMips(id, deleteExcessFiles),
  loadGenomeCategories: () => client.genome.getCategories(),
  loadGenomesInCategory: (category) =>
      client.genome.getGenomeByCategory(category),
  // ⚠️ Through `client.snp`, not `client.genome`: only that one filters by
  // visibility, and having the picker and the genome tab disagree about what
  // exists would be worse than either being wrong on its own.
  loadSnpsForGenome: (genomeId) => client.snp.listSnpsForGenome(genomeId),
  setGenome: (projectId, genomeId) =>
      client.project.setGeneById(projectId, genomeId),
  setSnp: (projectId, snpId) => client.project.setSnpById(projectId, snpId),
  setEmailNotification: (projectId, enabled) =>
      client.project.setEmailNotification(projectId, enabled),
);

/// A controller for the create-project form, wired to the real client.
///
/// ⚠️ A factory: the form is built fresh each time it is opened.
NewProjectController createNewProjectController() => NewProjectController(
  loadDefaultOptions: () => client.options.createProjectOptions(),
  insertOptions: (options) => client.options.insertProjectOptions(options),
  createProject: (name, options, description) =>
      client.project.createProject(name, options, description),
);

/// Opens a URL in a new tab.
///
/// Injected rather than called directly, because `web.window.open` is the whole
/// reason `project_result_actions.dart` could not be compiled for a test. The
/// only implementation is the one `main()` installs.
late void Function(String url) openExternalUrl;

/// Opens the browser's file dialog and returns what was chosen, or null.
///
/// Same reason: `file_picker.dart` imports `dart:js_interop`, and
/// `add_custom_snp_dialog.dart` imported it for nothing but the default value of
/// one parameter — which was enough to make the whole SNP tab uncompilable off
/// the web. [PickedFile] itself was already written to name nothing web-only.
late Future<PickedFile?> Function({required String accept}) pickFile;

/// Wires up the four things above that need the browser.
///
/// Called once from `main()`, before `runApp`. ⚠️ The fields are `late` and not
/// `late final` on purpose: a test that installs fakes needs to be able to do it
/// again for the next test, and `late final` throws on a second assignment.
void installServices({
  required void Function(String url) navigate,
  required void Function(String url) openUrl,
  required Future<PickedFile?> Function({required String accept}) filePicker,
  required SnpTransport snpTransport,
}) {
  openExternalUrl = openUrl;
  pickFile = filePicker;

  // Sign-in and sign-out are full-page navigations rather than popups: the
  // session cookie has to be set in the browsing context the app itself runs in,
  // and the redirect chain finishes by loading the app again.
  authController = AuthController.forApp(
    client: client,
    siteUrl: siteUrl,
    navigate: navigate,
  );

  // A single owner for the question, because there were already two answers to
  // it in this app and this is the one that decides whether a destructive button
  // appears. It re-asks whenever sign-in state changes, because `TabBarView`
  // builds every tab before the bearer token exists.
  accessController = AccessController(
    fetchAccess: () => client.settings.userSettings(),
    auth: authController,
  );

  snpUploads = SnpUploadController(
    transport: snpTransport,
    finishUpload: (snpId) => client.snp.finishUpload(snpId),
  );

  settingsController = SettingsController(
    loadAccess: () => client.settings.userSettings(),
    loadSettings: (password) => client.settings.getSettings(password),
    saveSettings: (password, settings) =>
        client.settings.updateSettings(password, settings),
    setSmtpPassword: (password, smtpPassword) =>
        client.settings.setSmtpPassword(password, smtpPassword),
    setOidcClientSecret: (password, secret) =>
        client.settings.setOidcClientSecret(password, secret),
    smtpPasswordConfigured: (password) =>
        client.settings.smtpPasswordConfigured(password),
    loadAuthStatus: (password) => client.settings.getAuthAdminStatus(password),
    sendTestMail: (password, to) => client.settings.sendTestMail(password, to),
    signOut: () => authController.signOut(siteUrl),
    auth: authController,
  );

  projectsController = ProjectsController(
    loadProjects: () => client.project.getProjects(),
    deleteProject: (id) => client.project.deleteProject(id),
    setOwner: (id, ownerId) => client.project.setProjectOwner(id, ownerId),
    loadNotificationsAvailable: () => client.project.notificationsAvailable(),
    loadAssignableOwners: () => client.project.assignableOwners(),
    // ⚠️ Read through a closure, not captured: `authController.user` changes
    // when somebody signs in, and the answer decides whether the owner picker is
    // fetched at all.
    isAdmin: () => authController.user?.isAdmin ?? false,
    auth: authController,
  );
}
