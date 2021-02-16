#import <Flutter/Flutter.h>

@interface RadarFlutterPlugin : NSObject<FlutterPlugin>

@end

@interface RadarStreamHandler : NSObject<FlutterStreamHandler>

@property FlutterEventSink sink;

@end
