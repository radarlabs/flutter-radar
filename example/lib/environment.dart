import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The publishable key used when none is saved for an environment. Replace it,
/// or set a key per environment in the app's Environment card.
const String defaultPublishableKey =
    'prj_test_pk_0000000000000000000000000000000000000000';

/// The Radar API environment the example app talks to.
///
/// [local] points the SDK at a dev server: `http://localhost:8081` in the iOS
/// Simulator, `http://10.0.2.2:8081` on the Android emulator, or your
/// machine's LAN IP on a device. The example app permits cleartext HTTP for
/// this (see Info.plist and network_security_config.xml).
enum RadarEnvironment {
  production(
    'Production',
    'https://api.radar.io',
    'https://api-verified.radar.io',
  ),
  staging(
    'Staging',
    'https://api.radar-staging.com',
    'https://api-verified.radar-staging.com',
  ),
  local('Local', null, null);

  const RadarEnvironment(this.label, this.fixedHost, this.fixedVerifiedHost);

  final String label;

  /// Fixed hosts; null for [local], which uses the saved Local URLs.
  final String? fixedHost;
  final String? fixedVerifiedHost;

  /// Environments with fixed hosts, which the key check probes.
  static const checkable = [production, staging];

  static RadarEnvironment fromName(String? name) =>
      values.firstWhere((env) => env.name == name, orElse: () => production);
}

/// The saved environment settings. The environment applied at launch stays
/// fixed for the life of the process: changes are saved, then the app quits,
/// so the SDK never runs with one environment's host and another's key.
class EnvironmentSettings {
  EnvironmentSettings._(this._prefs);

  final SharedPreferences _prefs;

  static const _keyEnvironment = 'radarEnvironment';
  static const _keyLocalUrl = 'radarLocalUrl';
  static const _keyLocalVerifiedUrl = 'radarLocalVerifiedUrl';
  static String _keyPublishableKey(RadarEnvironment env) =>
      'radarPublishableKey.${env.name}';

  static Future<EnvironmentSettings> load() async =>
      EnvironmentSettings._(await SharedPreferences.getInstance());

  /// The environment this process was launched with.
  RadarEnvironment get environment =>
      RadarEnvironment.fromName(_prefs.getString(_keyEnvironment));

  String get localUrl => _prefs.getString(_keyLocalUrl) ?? '';

  /// The Local verified host; empty means the same as [localUrl].
  String get localVerifiedUrl => _prefs.getString(_keyLocalVerifiedUrl) ?? '';

  /// The key saved for [env], falling back to [defaultPublishableKey].
  String publishableKey(RadarEnvironment env) {
    final saved = _prefs.getString(_keyPublishableKey(env)) ?? '';
    return saved.isEmpty ? defaultPublishableKey : saved;
  }

  /// The key for the running environment.
  String get resolvedPublishableKey => publishableKey(environment);

  String host(RadarEnvironment env) => env.fixedHost ?? localUrl;

  String verifiedHost(RadarEnvironment env) =>
      env.fixedVerifiedHost ??
      (localVerifiedUrl.isEmpty ? localUrl : localVerifiedUrl);

  /// Whether the running environment has a usable key.
  bool get hasKey =>
      resolvedPublishableKey.isNotEmpty &&
      resolvedPublishableKey != defaultPublishableKey;

  /// Persists the settings. They take effect on the next launch.
  Future<void> save({
    required RadarEnvironment environment,
    required String publishableKey,
    required String localUrl,
    required String localVerifiedUrl,
  }) async {
    await _prefs.setString(_keyEnvironment, environment.name);
    await _prefs.setString(
      _keyPublishableKey(environment),
      publishableKey.trim(),
    );
    await _prefs.setString(_keyLocalUrl, _normalizeHost(localUrl));
    await _prefs.setString(
      _keyLocalVerifiedUrl,
      _normalizeHost(localVerifiedUrl),
    );
  }

  /// Writes the host overrides the native SDKs read. Production clears them,
  /// so the SDK uses its built-in hosts. Call before `Radar.initialize`.
  Future<void> applyHosts() {
    final env = environment;
    return _setHosts(
      host: env == RadarEnvironment.production ? null : host(env),
      verifiedHost:
          env == RadarEnvironment.production ? null : verifiedHost(env),
    );
  }

  static String _normalizeHost(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}

const _channel = MethodChannel('io.radar.example/environment');

/// Neither native SDK has a public host setter: they read these storage keys
/// on every request (UserDefaults `radar-host` / `radar-verifiedHost` on iOS,
/// SharedPreferences `RadarSDK` `host` / `verified_host` on Android). The
/// example app's native code writes them (AppDelegate.m, MainActivity.java).
/// A null host removes the override.
Future<void> _setHosts({String? host, String? verifiedHost}) {
  return _channel.invokeMethod<void>('setHosts', {
    'host': host,
    'verifiedHost': verifiedHost,
  });
}

/// Which environments a publishable key is valid on. A key's string doesn't
/// say whether it belongs to staging or production, so [check] asks each
/// environment's `/v1/config`.
class KeyCheck {
  const KeyCheck._(this.validOn, this.unknown, {this.checked = true});

  const KeyCheck.notChecked() : this._(const [], const [], checked: false);

  final bool checked;
  final List<RadarEnvironment> validOn;

  /// Environments that couldn't be reached or gave an unexpected response.
  final List<RadarEnvironment> unknown;

  /// Whether the key is known not to work on [env]. Local is never checked.
  bool mismatches(RadarEnvironment env) =>
      checked &&
      RadarEnvironment.checkable.contains(env) &&
      !validOn.contains(env) &&
      !unknown.contains(env);

  String get summary {
    if (!checked) return 'not checked';
    final valid =
        validOn.isEmpty
            ? 'valid on neither'
            : 'valid on ${validOn.map((e) => e.label).join(' and ')}';
    return unknown.isEmpty
        ? valid
        : '$valid (${unknown.map((e) => e.label).join(', ')} unreachable)';
  }

  static Future<KeyCheck> check(String publishableKey) async {
    final validOn = <RadarEnvironment>[];
    final unknown = <RadarEnvironment>[];
    await Future.wait(
      RadarEnvironment.checkable.map((env) async {
        switch (await _probe(env.fixedHost!, publishableKey)) {
          case true:
            validOn.add(env);
          case false:
            break;
          case null:
            unknown.add(env);
        }
      }),
    );
    return KeyCheck._(validOn, unknown);
  }

  /// true = accepted, false = rejected (401/403), null = unreachable or an
  /// unexpected response.
  static Future<bool?> _probe(String host, String publishableKey) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(
        Uri.parse('$host/v1/config?installId=example-key-check&usage=keyCheck'),
      );
      request.headers.set(HttpHeaders.authorizationHeader, publishableKey);
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      await response.drain<void>();
      final code = response.statusCode;
      if (code >= 200 && code < 300) return true;
      if (code == 401 || code == 403) return false;
      return null;
    } on Exception {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
