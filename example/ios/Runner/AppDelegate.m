#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <RadarSDK/RadarSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  [Radar initializeWithPublishableKey:@"org_test_pk_5857c63d9c1565175db8b00750808a66a002acb8"];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
