#import <Flutter/Flutter.h>
#import <CoreLocation/CoreLocation.h>

@interface RadarFlutterPlugin : NSObject<FlutterPlugin, CLLocationManagerDelegate>

@end

@interface RadarStreamHandler : NSObject<FlutterStreamHandler>

@property FlutterEventSink sink;

@end
