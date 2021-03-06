#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <RadarSDK/RadarSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  [Radar initializeWithPublishableKey:@"prj_test_pk_0000000000000000000000000000000000000000"];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
