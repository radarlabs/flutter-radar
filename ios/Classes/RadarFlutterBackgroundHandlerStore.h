#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarFlutterBackgroundHandlerHandles : NSObject

@property(nonatomic, readonly) int64_t dispatcherHandle;
@property(nonatomic, readonly) int64_t callbackHandle;

- (instancetype)initWithDispatcherHandle:(int64_t)dispatcherHandle
                          callbackHandle:(int64_t)callbackHandle;

@end

@interface RadarFlutterBackgroundHandlerStore : NSObject

+ (instancetype)defaultStore;

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (void)saveDispatcherHandle:(int64_t)dispatcherHandle
              callbackHandle:(int64_t)callbackHandle;

- (nullable RadarFlutterBackgroundHandlerHandles *)loadHandles;

- (void)clear;

@end

NS_ASSUME_NONNULL_END
