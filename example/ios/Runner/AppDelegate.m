#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <RadarSDK/RadarSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  [Radar nativeSetup];
  [Radar initializeWithPublishableKey:@"prj_test_pk_0000000000000000000000000000000000000000"];
  BOOL res = [super application:application didFinishLaunchingWithOptions:launchOptions];
  return res;
}

@end
