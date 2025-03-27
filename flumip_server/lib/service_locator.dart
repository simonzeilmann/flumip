import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/options_service.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:get_it/get_it.dart';

GetIt sl = GetIt.instance;

void setup() {
  // Important to register services that might be used in AppModel constructor first
  sl.registerSingleton<SettingsService>(SettingsService());
  sl.registerSingleton<ProjectService>(ProjectService());
  sl.registerSingleton<ProcessService>(ProcessService());
  sl.registerSingleton<GenomeService>(GenomeService());
  sl.registerSingleton<FileService>(FileService());
  sl.registerSingleton<OptionsService>(OptionsService());
  sl.registerSingleton<MipgenService>(MipgenService());
}