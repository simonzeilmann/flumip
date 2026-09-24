import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/settings/sso_settings.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The first automated coverage of two behaviours that had none, and that both
/// fail *silently*: a field the environment has taken over must render
/// read-only, and the write-only client secret must say whether one is stored.
///
/// Testable because `SsoSettings` takes its controllers and its status as
/// parameters and reports the test-connection press through a callback, so it
/// never reaches the top-level `client` in `main.dart`.
AuthAdminStatusDto statusFixture({
  List<String> envOverrides = const [],
  bool secretConfigured = false,
  bool discoveryOk = true,
  String? discoveryError,
  String redirectUri = 'https://flumip.example.org/auth/callback',
  bool enabled = true,
  bool enforcing = true,
}) => AuthAdminStatusDto(
  enabled: enabled,
  enforcing: enforcing,
  secretConfigured: secretConfigured,
  envOverrides: envOverrides,
  redirectUri: redirectUri,
  discoveryOk: discoveryOk,
  discoveryError: discoveryError,
  authorizationEndpoint: 'https://login.example.org/auth',
  tokenEndpoint: 'https://login.example.org/token',
);

class SsoControllers {
  final issuer = TextEditingController();
  final clientId = TextEditingController();
  final clientSecret = TextEditingController();
  final publicUrl = TextEditingController();
  final allowedDomains = TextEditingController();
  final adminEmails = TextEditingController();
  final scopes = TextEditingController();
  final buttonLabel = TextEditingController();
}

Future<SsoControllers> pumpSso(
  WidgetTester tester, {
  AuthAdminStatusDto? status,
  VoidCallback? onTestConnection,
}) async {
  final c = SsoControllers();
  tester.view.physicalSize = const Size(1000, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SsoSettings(
            issuerController: c.issuer,
            clientIdController: c.clientId,
            clientSecretController: c.clientSecret,
            publicUrlController: c.publicUrl,
            allowedDomainsController: c.allowedDomains,
            adminEmailsController: c.adminEmails,
            departmentClaimController: TextEditingController(),
            scopesController: c.scopes,
            buttonLabelController: c.buttonLabel,
            status: status,
            onTestConnection: onTestConnection ?? () {},
          ),
        ),
      ),
    ),
  );
  return c;
}

TextField fieldWithLabel(WidgetTester tester, String label) {
  return tester
      .widgetList<TextField>(find.byType(TextField))
      .firstWhere(
        (f) => f.decoration?.labelText == label,
        orElse: () => throw StateError('no field labelled "$label"'),
      );
}

void main() {
  group('a field the environment has taken over', () {
    testWidgets('is read-only and says which variable did it', (tester) async {
      await pumpSso(
        tester,
        status: statusFixture(envOverrides: const ['FLUMIP_OIDC_ISSUER']),
      );

      final issuer = fieldWithLabel(tester, 'OIDC issuer');
      expect(issuer.readOnly, isTrue);
      expect(
        issuer.decoration?.helperText,
        'Set by FLUMIP_OIDC_ISSUER in the environment',
      );
      expect(issuer.decoration?.suffixIcon, isNotNull);
    });

    testWidgets('leaves the others editable', (tester) async {
      await pumpSso(
        tester,
        status: statusFixture(envOverrides: const ['FLUMIP_OIDC_ISSUER']),
      );
      expect(fieldWithLabel(tester, 'Client ID').readOnly, isFalse);
    });

    testWidgets('nothing is read-only when nothing is overridden', (
      tester,
    ) async {
      await pumpSso(tester, status: statusFixture());
      expect(fieldWithLabel(tester, 'OIDC issuer').readOnly, isFalse);
      expect(fieldWithLabel(tester, 'Client secret').readOnly, isFalse);
    });

    testWidgets('an overridden client secret is locked too', (tester) async {
      await pumpSso(
        tester,
        status: statusFixture(
          envOverrides: const ['FLUMIP_OIDC_CLIENT_SECRET'],
        ),
      );
      final secret = fieldWithLabel(tester, 'Client secret');
      expect(secret.readOnly, isTrue);
      expect(
        secret.decoration?.helperText,
        contains('FLUMIP_OIDC_CLIENT_SECRET'),
      );
    });

    testWidgets('before the status arrives, nothing claims to be overridden', (
      tester,
    ) async {
      // ⚠️ status is null until the probe answers. If this widget were built as
      // const it would never rebuild once it did, and the markers would never
      // appear at all.
      await pumpSso(tester, status: null);
      expect(fieldWithLabel(tester, 'OIDC issuer').readOnly, isFalse);
    });
  });

  group('the write-only client secret', () {
    testWidgets('says when one is stored, without revealing it', (
      tester,
    ) async {
      await pumpSso(tester, status: statusFixture(secretConfigured: true));

      final secret = fieldWithLabel(tester, 'Client secret');
      expect(secret.obscureText, isTrue);
      expect(secret.decoration?.helperText, contains('A secret is stored'));
      expect(secret.decoration?.suffixIcon, isNotNull);
    });

    testWidgets('says when none is stored', (tester) async {
      await pumpSso(tester, status: statusFixture(secretConfigured: false));

      final secret = fieldWithLabel(tester, 'Client secret');
      expect(secret.decoration?.helperText, 'No secret stored yet.');
      expect(secret.decoration?.suffixIcon, isNull);
    });

    testWidgets('starts empty, so an untouched save keeps the stored one', (
      tester,
    ) async {
      final c = await pumpSso(
        tester,
        status: statusFixture(secretConfigured: true),
      );
      expect(c.clientSecret.text, isEmpty);
    });
  });

  group('the redirect URI', () {
    testWidgets('is shown selectable, because it must match exactly', (
      tester,
    ) async {
      await pumpSso(tester, status: statusFixture());
      expect(
        find.widgetWithText(
          SelectableText,
          'https://flumip.example.org/auth/callback',
        ),
        findsOneWidget,
      );
    });

    testWidgets('is left out when the server has not computed one', (
      tester,
    ) async {
      await pumpSso(tester, status: statusFixture(redirectUri: ''));
      expect(find.textContaining('Redirect URI'), findsNothing);
    });
  });

  group('the connection test', () {
    testWidgets('reports success with the endpoint it reached', (tester) async {
      await pumpSso(tester, status: statusFixture(discoveryOk: true));
      expect(find.textContaining('Reached the provider'), findsOneWidget);
    });

    testWidgets('reports the provider error verbatim', (tester) async {
      await pumpSso(
        tester,
        status: statusFixture(
          discoveryOk: false,
          discoveryError: 'Connection refused',
        ),
      );
      expect(find.textContaining('Connection refused'), findsOneWidget);
    });

    testWidgets('calls back when pressed', (tester) async {
      var tested = false;
      await pumpSso(
        tester,
        status: statusFixture(),
        onTestConnection: () => tested = true,
      );

      await tester.tap(find.text('Test connection'));
      expect(tested, isTrue);
    });
  });

  testWidgets('warns when sign-in is on but not being enforced', (
    tester,
  ) async {
    await pumpSso(
      tester,
      status: statusFixture(enabled: true, enforcing: false),
    );
    expect(find.textContaining('not being enforced yet'), findsOneWidget);
  });

  testWidgets('says nothing about enforcement once it is enforcing', (
    tester,
  ) async {
    await pumpSso(
      tester,
      status: statusFixture(enabled: true, enforcing: true),
    );
    expect(find.textContaining('not being enforced yet'), findsNothing);
  });
}
