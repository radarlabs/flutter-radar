//
//  RadarFlutterEventCoordinatorTests.m
//  Runner
//
//  Created by Alan Charles on 8/11/26.
//

#import <XCTest/XCTest.h>

#import "../../../ios/Classes/RadarFlutterBackgroundHandlerStore.h"
#import "../../../ios/Classes/RadarFlutterEventCoordinator.h"

@interface RadarFlutterTestEventSink : NSObject <RadarFlutterEventSink>

@property(nonatomic, strong)
    NSMutableArray<NSDictionary *> *deliveries;
@property(nonatomic, assign) BOOL completesAutomatically;
@property(nonatomic, strong) NSMutableArray *pendingCompletions;

@end

@implementation RadarFlutterTestEventSink

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _deliveries = [NSMutableArray array];
    _completesAutomatically = YES;
    _pendingCompletions = [NSMutableArray array];

    return self;
}

- (void)sendMethod:(NSString *)method
         arguments:(NSDictionary *)arguments
        completion:(RadarFlutterEventCompletion)completion {
    [self.deliveries addObject:@{
        @"method": method,
        @"arguments": arguments,
    }];

    if (self.completesAutomatically) {
        completion();
    } else {
        [self.pendingCompletions addObject:[completion copy]];
    }
}

- (void)completeNextDelivery {
    RadarFlutterEventCompletion completion =
        self.pendingCompletions.firstObject;

    NSAssert(completion != nil, @"No delivery is waiting for completion.");

    [self.pendingCompletions removeObjectAtIndex:0];
    completion();
}

@end

@interface RadarFlutterEventCoordinatorTests : XCTestCase

@property(nonatomic, strong) NSString *suiteName;
@property(nonatomic, strong) NSUserDefaults *userDefaults;
@property(nonatomic, strong) RadarFlutterBackgroundHandlerStore *store;
@property(nonatomic, strong) RadarFlutterEventCoordinator *coordinator;
@property(nonatomic, strong) RadarFlutterTestEventSink *sink;

@end

@implementation RadarFlutterEventCoordinatorTests

- (void)setUp {
    [super setUp];

    self.suiteName = [NSString stringWithFormat:
        @"RadarFlutterEventCoordinatorTests.%@",
        NSUUID.UUID.UUIDString];

    self.userDefaults =
        [[NSUserDefaults alloc] initWithSuiteName:self.suiteName];
    [self.userDefaults removePersistentDomainForName:self.suiteName];

    self.store = [[RadarFlutterBackgroundHandlerStore alloc]
        initWithUserDefaults:self.userDefaults];
    [self.store saveDispatcherHandle:11 callbackHandle:22];

    self.coordinator = [[RadarFlutterEventCoordinator alloc]
        initWithBackgroundHandlerStore:self.store];
    self.sink = [[RadarFlutterTestEventSink alloc] init];
}

- (void)tearDown {
    self.sink = nil;
    self.coordinator = nil;
    self.store = nil;

    [self.userDefaults removePersistentDomainForName:self.suiteName];
    self.userDefaults = nil;
    self.suiteName = nil;

    [super tearDown];
}

- (void)testQueuesEventUntilPrimarySinkIsReady {
    NSDictionary *payload = @{
        @"location": @{
            @"latitude": @47.0,
            @"longitude": @-122.0,
        },
        @"stopped": @NO,
        @"source": @"background",
    };

    [self.coordinator routeMethod:@"clientLocation" payload:payload];

    XCTAssertEqual(self.sink.deliveries.count, 0);

    [self.coordinator setPrimarySink:self.sink];

    XCTAssertEqual(self.sink.deliveries.count, 1);
    XCTAssertEqualObjects(self.sink.deliveries.firstObject, (@{
        @"method": @"clientLocation",
        @"arguments": @{
            @"callbackHandle": @22,
            @"payload": payload,
        },
    }));
}

- (void)testWaitsForEachDeliveryToCompleteBeforeSendingTheNext {
    self.sink.completesAutomatically = NO;
    [self.coordinator setPrimarySink:self.sink];

    [self.coordinator routeMethod:@"location"
                          payload:@{@"sequence": @1}];
    [self.coordinator routeMethod:@"location"
                          payload:@{@"sequence": @2}];

    XCTAssertEqual(self.sink.deliveries.count, 1);
    XCTAssertEqualObjects(
        self.sink.deliveries.firstObject[@"arguments"][@"payload"],
        (@{@"sequence": @1}));

    [self.sink completeNextDelivery];

    XCTAssertEqual(self.sink.deliveries.count, 2);
    XCTAssertEqualObjects(
        self.sink.deliveries.lastObject[@"arguments"][@"payload"],
        (@{@"sequence": @2}));
}

- (void)testDropsEventsWhenNoHandlerIsPersisted {
    [self.store clear];

    [self.coordinator routeMethod:@"location"
                          payload:@{@"sequence": @1}];
    [self.coordinator setPrimarySink:self.sink];

    XCTAssertEqual(self.sink.deliveries.count, 0);
}

- (void)testClearPendingEventsPreventsQueuedDelivery {
    [self.coordinator routeMethod:@"location"
                          payload:@{@"sequence": @1}];
    [self.coordinator routeMethod:@"location"
                          payload:@{@"sequence": @2}];

    [self.coordinator clearPendingEvents];
    [self.coordinator setPrimarySink:self.sink];

    XCTAssertEqual(self.sink.deliveries.count, 0);
}

- (void)testUsesCurrentCallbackHandleWhenQueuedEventIsDelivered {
    [self.coordinator routeMethod:@"location"
                          payload:@{@"sequence": @1}];

    [self.store saveDispatcherHandle:33 callbackHandle:44];
    [self.coordinator setPrimarySink:self.sink];

    XCTAssertEqual(self.sink.deliveries.count, 1);
    XCTAssertEqualObjects(
        self.sink.deliveries.firstObject[@"arguments"][@"callbackHandle"],
        @44);
}

- (void)testClearingActiveSinkQueuesEventsUntilReplacementAttaches {
    RadarFlutterTestEventSink *replacement =
        [[RadarFlutterTestEventSink alloc] init];

    [self.coordinator setPrimarySink:self.sink];
    [self.coordinator clearPrimarySink:self.sink];

    [self.coordinator routeMethod:@"location"
                          payload:@{@"sequence": @1}];

    XCTAssertEqual(self.sink.deliveries.count, 0);
    XCTAssertEqual(replacement.deliveries.count, 0);

    [self.coordinator setPrimarySink:replacement];

    XCTAssertEqual(replacement.deliveries.count, 1);
    XCTAssertEqualObjects(
        replacement.deliveries.firstObject[@"arguments"][@"payload"],
        (@{@"sequence": @1}));
}

- (void)testClearingStaleSinkDoesNotDetachActiveSink {
    RadarFlutterTestEventSink *staleSink =
        [[RadarFlutterTestEventSink alloc] init];

    [self.coordinator setPrimarySink:self.sink];
    [self.coordinator clearPrimarySink:staleSink];

    [self.coordinator routeMethod:@"location"
                          payload:@{@"sequence": @1}];

    XCTAssertEqual(self.sink.deliveries.count, 1);
    XCTAssertEqual(staleSink.deliveries.count, 0);
}

@end
