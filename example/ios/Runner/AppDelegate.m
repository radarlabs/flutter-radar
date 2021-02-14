#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <RadarSDK/RadarSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [Radar initializeWithPublishableKey:@"<yourRadarPublishableKey>"];
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
