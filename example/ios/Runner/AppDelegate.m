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
}

@end
