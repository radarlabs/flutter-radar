import 'package:flutter/services.dart';
import 'package:flutter_radar_example/environment.dart';
import 'package:flutter_radar_example/environment_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('io.radar.example/environment');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  test('defaults to production with the placeholder key', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await EnvironmentSettings.load();

    expect(settings.environment, RadarEnvironment.production);
    expect(settings.resolvedPublishableKey, defaultPublishableKey);
    expect(settings.hasKey, isFalse);
  });

  test('production clears the host overrides', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await EnvironmentSettings.load();
    await settings.applyHosts();

    expect(calls.single.method, 'setHosts');
    expect(calls.single.arguments, {'host': null, 'verifiedHost': null});
  });

  test('staging writes the staging hosts and uses its own key', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await EnvironmentSettings.load();
    await settings.save(
      environment: RadarEnvironment.staging,
      publishableKey: ' prj_test_pk_staging ',
      localUrl: '',
      localVerifiedUrl: '',
    );
    await settings.applyHosts();

    expect(settings.resolvedPublishableKey, 'prj_test_pk_staging');
    expect(
      settings.publishableKey(RadarEnvironment.production),
      defaultPublishableKey,
    );
    expect(calls.single.arguments, {
      'host': 'https://api.radar-staging.com',
      'verifiedHost': 'https://api-verified.radar-staging.com',
    });
  });

  test('local uses the Local URL for both hosts unless one is set', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await EnvironmentSettings.load();
    await settings.save(
      environment: RadarEnvironment.local,
      publishableKey: 'prj_test_pk_local',
      localUrl: 'http://10.0.2.2:8081/',
      localVerifiedUrl: '',
    );
    expect(settings.host(RadarEnvironment.local), 'http://10.0.2.2:8081');
    expect(
      settings.verifiedHost(RadarEnvironment.local),
      'http://10.0.2.2:8081',
    );

    await settings.save(
      environment: RadarEnvironment.local,
      publishableKey: 'prj_test_pk_local',
      localUrl: 'http://10.0.2.2:8081',
      localVerifiedUrl: 'http://10.0.2.2:8082',
    );
    expect(
      settings.verifiedHost(RadarEnvironment.local),
      'http://10.0.2.2:8082',
    );
  });

  test('an unchecked key never reports a mismatch', () {
    const notChecked = KeyCheck.notChecked();
    expect(notChecked.mismatches(RadarEnvironment.production), isFalse);
    expect(notChecked.summary, 'not checked');
  });

  test('keyPrefix never shows the whole key', () {
    expect(keyPrefix('prj_test_pk_1a2b3c4d5e'), 'prj_test_pk_1a2b…');
    expect(keyPrefix('prj_live_pk_9f8e7d'), 'prj_live_pk_9f8e…');
    expect(keyPrefix(''), 'no key');
    expect(keyPrefix('abc'), 'abc');
  });
}
