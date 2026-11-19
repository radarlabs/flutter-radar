#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

// Flutter's UIScene lifecycle initializes the implicit engine before plugin
// registration. This is required for safe OS-initiated background launches.
// https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
- (void)didInitializeImplicitFlutterEngine:
    (NSObject<FlutterImplicitEngineBridge> *)engineBridge {
  [GeneratedPluginRegistrant
      registerWithRegistry:engineBridge.pluginRegistry];
  [self registerE2EChannel:engineBridge.pluginRegistry];
}

// Test-only hook for example/integration_test. The Radar SDK has no public
// host setter; it reads these UserDefaults keys on every request, so writing
// them before Radar.initialize points the SDK at another API host. A null
// value removes the key so the SDK falls back to production.
- (void)registerE2EChannel:(NSObject<FlutterPluginRegistry> *)registry {
  NSObject<FlutterPluginRegistrar> *registrar =
      [registry registrarForPlugin:@"RadarExampleE2E"];
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"io.radar.example/e2e"
                                  binaryMessenger:[registrar messenger]];
  [channel setMethodCallHandler:^(FlutterMethodCall *call,
                                  FlutterResult result) {
    if (![call.method isEqualToString:@"setHosts"]) {
      result(FlutterMethodNotImplemented);
      return;
    }
    NSDictionary *args = call.arguments;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary<NSString *, NSString *> *keys = @{
      @"host" : @"radar-host",
      @"verifiedHost" : @"radar-verifiedHost",
    };
    for (NSString *arg in keys) {
      id value = args[arg];
      if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
        [defaults setObject:value forKey:keys[arg]];
      } else {
        [defaults removeObjectForKey:keys[arg]];
      }
    }
    result(nil);
  }];
}

@end
