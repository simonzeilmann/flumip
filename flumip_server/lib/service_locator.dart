import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/oidc_client.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/http_client.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/mail_sender.dart';
import 'package:flumip_server/src/services/mail_service.dart';
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
/// [processRunner] overrides the process abstraction, [mailSender] the SMTP
/// abstraction and [httpClient] the calls to the identity provider; tests pass
/// fakes so that process-, mail- and OIDC-dependent logic can run without the
/// real external tools, an SMTP server or a running provider. They default to
/// [SystemProcessRunner] (delegates to `dart:io`), [SmtpMailSender] and
/// [PackageHttpJsonClient].
///
/// [authRuntime] lets a test install a runtime with a synthetic environment, so
/// the environment-variable precedence rules can be exercised without mutating
/// the real process environment.
///
/// Reassignment is enabled so a test group can call [setup] again (or
/// re-register a collaborator) to swap in fakes.
void setup({
  ProcessRunner? processRunner,
  MailSender? mailSender,
  HttpJsonClient? httpClient,
  AuthRuntime? authRuntime,
}) {
  sl.allowReassignment = true;
  // Important to register services that might be used in AppModel constructor first
  sl.registerSingleton<ProcessRunner>(
    processRunner ?? const SystemProcessRunner(),
  );
  sl.registerSingleton<MailSender>(mailSender ?? const SmtpMailSender());
  sl.registerSingleton<HttpJsonClient>(
    httpClient ?? const PackageHttpJsonClient(),
  );
  sl.registerSingleton<SettingsService>(SettingsService());
  sl.registerSingleton<ProjectService>(ProjectService());
  sl.registerSingleton<ProcessService>(ProcessService());
  sl.registerSingleton<GenomeService>(GenomeService());
  sl.registerSingleton<FileService>(FileService());
  sl.registerSingleton<OptionsService>(OptionsService());
  sl.registerSingleton<MipgenService>(MipgenService());
  sl.registerSingleton<MailService>(MailService());
  sl.registerSingleton<OidcClient>(OidcClient());
  sl.registerSingleton<AuthService>(AuthService());
  // Registered rather than a static singleton so that tests can install one
  // with a synthetic environment, following the same seam-not-mock convention
  // as the rest of these.
  sl.registerSingleton<AuthRuntime>(authRuntime ?? AuthRuntime());
}