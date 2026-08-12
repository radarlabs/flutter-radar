#import "RadarFlutterBackgroundHandlerStore.h"

static NSString *const RadarFlutterBackgroundHandlerKey =
    @"flutter_radar_background_handler";

static NSString *const RadarFlutterDispatcherHandleKey =
    @"dispatcher_handle";

static NSString *const RadarFlutterCallbackHandleKey =
    @"callback_handle";

@implementation RadarFlutterBackgroundHandlerHandles

- (instancetype)initWithDispatcherHandle:(int64_t)dispatcherHandle
                          callbackHandle:(int64_t)callbackHandle {
    self = [super init];
    if (self) {
        _dispatcherHandle = dispatcherHandle;
        _callbackHandle = callbackHandle;
    }
    return self;
}

@end

@interface RadarFlutterBackgroundHandlerStore ()

@property(nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation RadarFlutterBackgroundHandlerStore

+ (instancetype)defaultStore {
    return [[self alloc] initWithUserDefaults:NSUserDefaults.standardUserDefaults];
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
    }
    return self;
}

- (void)saveDispatcherHandle:(int64_t)dispatcherHandle
              callbackHandle:(int64_t)callbackHandle {
    NSDictionary *handles = @{
        RadarFlutterDispatcherHandleKey: @(dispatcherHandle),
        RadarFlutterCallbackHandleKey: @(callbackHandle),
    };

    [self.userDefaults setObject:handles
                         forKey:RadarFlutterBackgroundHandlerKey];
}

- (RadarFlutterBackgroundHandlerHandles *)loadHandles {
    id storedValue =
        [self.userDefaults objectForKey:RadarFlutterBackgroundHandlerKey];

    if (![storedValue isKindOfClass:NSDictionary.class]) {
        return nil;
    }

    NSDictionary *handles = storedValue;
    id dispatcherHandle = handles[RadarFlutterDispatcherHandleKey];
    id callbackHandle = handles[RadarFlutterCallbackHandleKey];

    if (![dispatcherHandle isKindOfClass:NSNumber.class] ||
        ![callbackHandle isKindOfClass:NSNumber.class]) {
        return nil;
    }

    return [[RadarFlutterBackgroundHandlerHandles alloc]
        initWithDispatcherHandle:[dispatcherHandle longLongValue]
                  callbackHandle:[callbackHandle longLongValue]];
}

- (void)clear {
    [self.userDefaults removeObjectForKey:RadarFlutterBackgroundHandlerKey];
}

@end
