#import <Foundation/Foundation.h>

@class RadarFlutterBackgroundHandlerStore;

NS_ASSUME_NONNULL_BEGIN

typedef void (^RadarFlutterEventCompletion)(void);

@protocol RadarFlutterEventSink <NSObject>

- (void)sendMethod:(NSString *)method
         arguments:(NSDictionary *)arguments
        completion:(RadarFlutterEventCompletion)completion;

@end

@interface RadarFlutterEventCoordinator : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithBackgroundHandlerStore:
    (RadarFlutterBackgroundHandlerStore *)backgroundHandlerStore
    NS_DESIGNATED_INITIALIZER;

- (void)routeMethod:(NSString *)method
            payload:(NSDictionary *)payload;

- (void)setPrimarySink:(id<RadarFlutterEventSink>)sink;

- (void)clearPrimarySink:(id<RadarFlutterEventSink>)sink;

- (void)clearPendingEvents;

@end

NS_ASSUME_NONNULL_END