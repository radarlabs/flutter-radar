/// Config for the e2e suite, read from `--dart-define-from-file=.env.e2e`.
/// See `example/.env.e2e.example`.
class E2EConfig {
  static const publishableKey = String.fromEnvironment('RADAR_PUBLISHABLE_KEY');
  static const host = String.fromEnvironment('RADAR_HOST');
  static const verifiedHost = String.fromEnvironment('RADAR_VERIFIED_HOST');
  static const verifiedEnabled = bool.fromEnvironment('RADAR_E2E_VERIFIED');

  static const _productionHost = 'https://api.radar.io';
  static const _productionVerifiedHost = 'https://api-verified.radar.io';

  /// Why the whole suite is skipped, or null if it can run.
  static String? get skipReason =>
      publishableKey.isEmpty
          ? 'RADAR_PUBLISHABLE_KEY is not set. Copy example/.env.e2e.example to '
              'example/.env.e2e, fill it in, and run scripts/e2e.sh.'
          : null;

  /// Why the trackVerified tests are skipped, or null if they can run.
  static String? get verifiedSkipReason {
    if (!verifiedEnabled) {
      return 'RADAR_E2E_VERIFIED is not true (needs a project with verified '
          'tracking enabled).';
    }
    final productionHosts =
        (host.isEmpty || host == _productionHost) &&
        (verifiedHost.isEmpty || verifiedHost == _productionVerifiedHost);
    if (!productionHosts) {
      return 'trackVerified needs the production hosts: the bundled fraud SDK '
          "can't override its payload encryption key for other servers yet.";
    }
    return null;
  }
}
