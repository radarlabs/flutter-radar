#import "RadarFlutterEventCoordinator.h"

#import "RadarFlutterBackgroundHandlerStore.h"

@interface RadarFlutterEventCoordinator ()

@property(nonatomic, strong)
    RadarFlutterBackgroundHandlerStore *backgroundHandlerStore;
@property(nonatomic, strong)
    NSMutableArray<NSDictionary *> *pendingEvents;
@property(nonatomic, strong, nullable)
    id<RadarFlutterEventSink> activePrimarySink;
@property(nonatomic, assign) BOOL deliveryInFlight;

- (void)drain;

@end

@implementation RadarFlutterEventCoordinator

- (instancetype)initWithBackgroundHandlerStore:
    (RadarFlutterBackgroundHandlerStore *)backgroundHandlerStore {
    self = [super init];
    if (!self) {
        return nil;
    }

    _backgroundHandlerStore = backgroundHandlerStore;
    _pendingEvents = [NSMutableArray array];

    return self;
}

- (void)routeMethod:(NSString *)method
            payload:(NSDictionary *)payload {
    if ([self.backgroundHandlerStore loadHandles] == nil) {
        return;
    }

    [self.pendingEvents addObject:@{
        @"method": [method copy],
        @"payload": [payload copy],
    }];

    [self drain];
}

- (void)setPrimarySink:(id<RadarFlutterEventSink>)sink {
    self.activePrimarySink = sink;
    [self drain];
}

- (void)clearPrimarySink:(id<RadarFlutterEventSink>)sink {
    if (self.activePrimarySink == sink) {
        self.activePrimarySink = nil;
    }
}

- (void)clearPendingEvents {
    [self.pendingEvents removeAllObjects];
}

- (void)drain {
    if (self.activePrimarySink == nil ||
        self.deliveryInFlight ||
        self.pendingEvents.count == 0) {
        return;
    }

    RadarFlutterBackgroundHandlerHandles *handles =
        [self.backgroundHandlerStore loadHandles];

    if (handles == nil) {
        [self.pendingEvents removeAllObjects];
        return;
    }

    NSDictionary *event = self.pendingEvents.firstObject;
    [self.pendingEvents removeObjectAtIndex:0];

    self.deliveryInFlight = YES;

    __weak typeof(self) weakSelf = self;
    [self.activePrimarySink
        sendMethod:event[@"method"]
        arguments:@{
            @"callbackHandle": @(handles.callbackHandle),
            @"payload": event[@"payload"],
        }
        completion:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }

            strongSelf.deliveryInFlight = NO;
            [strongSelf drain];
        }];
}

@end