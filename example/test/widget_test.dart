import 'package:flutter_radar_example/environment.dart';
import 'package:flutter_radar_example/environment_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// These run on the host (not Android), so the SDK host overrides use the iOS
// keys.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Backs SharedPreferencesAsync, which writes the SDK's host keys.
  late SharedPreferencesAsyncPlatform sdkStore;
  late SharedPreferencesAsync sdkPrefs;

  setUp(() {
    sdkStore = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = sdkStore;
    sdkPrefs = SharedPreferencesAsync();
  });

  test('defaults to production with the placeholder key', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await EnvironmentSettings.load();

    expect(settings.environment, RadarEnvironment.production);
    expect(settings.resolvedPublishableKey, defaultPublishableKey);
    expect(settings.hasKey, isFalse);
  });

  test('production clears the host overrides', () async {
    await sdkPrefs.setString('radar-host', 'https://api.radar-staging.com');
    await sdkPrefs.setString(
      'radar-verifiedHost',
      'https://api-verified.radar-staging.com',
    );
    SharedPreferences.setMockInitialValues({});
    final settings = await EnvironmentSettings.load();
    await settings.applyHosts();

    expect(await sdkPrefs.getString('radar-host'), isNull);
    expect(await sdkPrefs.getString('radar-verifiedHost'), isNull);
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
    // Written without the legacy API's `flutter.` prefix, where the SDK
    // reads them.
    expect(
      await sdkPrefs.getString('radar-host'),
      'https://api.radar-staging.com',
    );
    expect(
      await sdkPrefs.getString('radar-verifiedHost'),
      'https://api-verified.radar-staging.com',
    );
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
