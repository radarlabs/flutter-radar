#import <Foundation/Foundation.h>

@class RadarFlutterBackgroundHandlerStore;

NS_ASSUME_NONNULL_BEGIN

typedef void (^RadarFlutterEventCompletion)(void);

@protocol RadarFlutterEventSink <NSObject>

- (void)sendMethod:(NSString *)method
         arguments:(NSDictionary *)arguments
        completion:(RadarFlutterEventCompletion)completion;

@end

/**
 * Serializes durable Radar events across iOS process and Flutter engine
 * lifecycle transitions.
 *
 * Events are retained while Flutter's implicit engine is unavailable or its
 * durable handler has not registered. Once a primary sink is ready, events are
 * delivered one at a time and the next event waits for completion.
 *
 * This routing and queueing policy is Radar-specific; the callback-handle and
 * dispatcher mechanism follows Flutter's background-plugin pattern.
 */
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