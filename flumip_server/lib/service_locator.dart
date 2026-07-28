import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/options_service.dart';
import 'package:flumip_server/src/services/process_runner.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:get_it/get_it.dart';

GetIt sl = GetIt.instance;

/// Registers the application services with the service locator.
///
/// [processRunner] overrides the process abstraction; tests pass a fake so that
/// process-dependent logic can run without the real external tools. Defaults to
/// [SystemProcessRunner] (delegates to `dart:io`). Reassignment is enabled so a
/// test group can call [setup] again (or re-register a collaborator) to swap in
/// fakes.
void setup({ProcessRunner? processRunner}) {
  sl.allowReassignment = true;
  // Important to register services that might be used in AppModel constructor first
  sl.registerSingleton<ProcessRunner>(
    processRunner ?? const SystemProcessRunner(),
  );
  sl.registerSingleton<SettingsService>(SettingsService());
  sl.registerSingleton<ProjectService>(ProjectService());
  sl.registerSingleton<ProcessService>(ProcessService());
  sl.registerSingleton<GenomeService>(GenomeService());
  sl.registerSingleton<FileService>(FileService());
  sl.registerSingleton<OptionsService>(OptionsService());
  sl.registerSingleton<MipgenService>(MipgenService());
}