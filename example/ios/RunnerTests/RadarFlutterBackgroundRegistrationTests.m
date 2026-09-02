//
//  RadarFlutterBackgroundRegistrationTests.m
//  Runner
//
//  Created by Alan Charles on 8/6/26.
//

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>
@import RadarSDK;

#import "../../../ios/Classes/RadarFlutterBackgroundHandlerStore.h"
#import "../../../ios/Classes/RadarFlutterPlugin.h"
#import "../../../ios/Classes/RadarFlutterEventCoordinator.h"

@interface RadarFlutterPlugin (Testing)

- (instancetype)initWithBackgroundHandlerStore:
    (RadarFlutterBackgroundHandlerStore *)backgroundHandlerStore;

- (instancetype)initWithBackgroundHandlerStore:
                    (RadarFlutterBackgroundHandlerStore *)backgroundHandlerStore
                              eventCoordinator:
                    (RadarFlutterEventCoordinator *)eventCoordinator;

- (void)didUpdateClientLocation:(CLLocation *)location
                        stopped:(BOOL)stopped
                         source:(RadarLocationSource)source;

- (void)didFailWithStatus:(RadarStatus)status;
- (void)didLogMessage:(NSString *)message;
- (void)didChangeIP;
- (void)didChangeSharing:(BOOL)sharing;
- (void)didUpdateLocation:(CLLocation *)location user:(RadarUser *)user;
- (void)didReceiveEvents:(NSArray<RadarEvent *> *)events
                    user:(RadarUser *)user;
- (void)didUpdateToken:(RadarVerifiedLocationToken *)token;
@end

@interface RadarFlutterTestUser : RadarUser

@property(nonatomic, strong) NSDictionary *testDictionary;

@end

@implementation RadarFlutterTestUser

- (NSDictionary *)dictionaryValue {
    return self.testDictionary;
}

@end

@interface RadarFlutterTestEvent : RadarEvent

@property(nonatomic, strong) NSDictionary *testDictionary;

@end

@implementation RadarFlutterTestEvent

- (NSDictionary *)dictionaryValue {
    return self.testDictionary;
}

@end

@interface RadarFlutterTestToken : RadarVerifiedLocationToken

@property(nonatomic, strong) NSDictionary *testDictionary;

@end

@implementation RadarFlutterTestToken

- (NSDictionary *)dictionaryValue {
    return self.testDictionary;
}

@end

@interface RadarFlutterTestEventCoordinator : RadarFlutterEventCoordinator

@property(nonatomic, strong) id<RadarFlutterEventSink> attachedSink;
@property(nonatomic, strong) id<RadarFlutterEventSink> clearedSink;
@property(nonatomic, assign) NSInteger clearPendingEventsCallCount;
@property(nonatomic, copy) NSString *routedMethod;
@property(nonatomic, strong) NSDictionary *routedPayload;

@end

@implementation RadarFlutterTestEventCoordinator

- (void)setPrimarySink:(id<RadarFlutterEventSink>)sink {
    self.attachedSink = sink;
}

- (void)clearPrimarySink:(id<RadarFlutterEventSink>)sink {
    self.clearedSink = sink;
}

- (void)clearPendingEvents {
    self.clearPendingEventsCallCount++;
}

- (void)routeMethod:(NSString *)method
            payload:(NSDictionary *)payload {
    self.routedMethod = method;
    self.routedPayload = payload;
}

@end

@interface RadarFlutterBackgroundRegistrationTests : XCTestCase

@property(nonatomic, strong) NSString *suiteName;
@property(nonatomic, strong) NSUserDefaults *userDefaults;
@property(nonatomic, strong) RadarFlutterBackgroundHandlerStore *store;
@property(nonatomic, strong) RadarFlutterPlugin *plugin;
@property(nonatomic, strong)
    RadarFlutterTestEventCoordinator *coordinator;


@end

@implementation RadarFlutterBackgroundRegistrationTests

- (void)setUp {
    [super setUp];

    self.suiteName = [NSString stringWithFormat:
        @"RadarFlutterBackgroundRegistrationTests.%@",
        NSUUID.UUID.UUIDString];

    self.userDefaults =
        [[NSUserDefaults alloc] initWithSuiteName:self.suiteName];
    [self.userDefaults removePersistentDomainForName:self.suiteName];

    self.store = [[RadarFlutterBackgroundHandlerStore alloc]
        initWithUserDefaults:self.userDefaults];

    self.coordinator = [[RadarFlutterTestEventCoordinator alloc]
        initWithBackgroundHandlerStore:self.store];

    self.plugin = [[RadarFlutterPlugin alloc]
        initWithBackgroundHandlerStore:self.store
                      eventCoordinator:self.coordinator];
}

- (void)tearDown {
    self.plugin = nil;

    [self.userDefaults removePersistentDomainForName:self.suiteName];
    self.userDefaults = nil;
    self.suiteName = nil;
    self.coordinator = nil;
    self.store = nil;

    [super tearDown];
}

- (id)invokeMethod:(NSString *)method arguments:(id)arguments {
    FlutterMethodCall *call =
        [FlutterMethodCall methodCallWithMethodName:method
                                         arguments:arguments];

    __block BOOL completed = NO;
    __block id response = nil;

    [self.plugin handleMethodCall:call
                          result:^(id result) {
                              completed = YES;
                              response = result;
                          }];

    XCTAssertTrue(completed);
    return response;
}

- (void)testRegisterBackgroundHandlerPersistsBothHandles {
    int64_t dispatcherHandle = INT64_C(4294967296);
    int64_t callbackHandle = INT64_C(8589934592);

    id response = [self invokeMethod:@"registerBackgroundHandler"
                           arguments:@{
                               @"dispatcherHandle": @(dispatcherHandle),
                               @"callbackHandle": @(callbackHandle),
                           }];

    XCTAssertNil(response);

    RadarFlutterBackgroundHandlerHandles *handles =
        [self.store loadHandles];

    XCTAssertEqual(handles.dispatcherHandle, dispatcherHandle);
    XCTAssertEqual(handles.callbackHandle, callbackHandle);
}

- (void)testRegisterBackgroundHandlerReplacesExistingHandles {
    [self.store saveDispatcherHandle:1 callbackHandle:2];

    [self invokeMethod:@"registerBackgroundHandler"
             arguments:@{
                 @"dispatcherHandle": @3,
                 @"callbackHandle": @4,
             }];

    RadarFlutterBackgroundHandlerHandles *handles =
        [self.store loadHandles];

    XCTAssertEqual(handles.dispatcherHandle, 3);
    XCTAssertEqual(handles.callbackHandle, 4);
}

- (void)testRegisterBackgroundHandlerRejectsInvalidArguments {
    NSArray *invalidArguments = @[
        NSNull.null,
        @"invalid",
        @[],
        @{@"callbackHandle": @2},
        @{@"dispatcherHandle": @1},
        @{
            @"dispatcherHandle": @"1",
            @"callbackHandle": @2,
        },
        @{
            @"dispatcherHandle": @1,
            @"callbackHandle": @"2",
        },
    ];

    for (id arguments in invalidArguments) {
        [self.store saveDispatcherHandle:11 callbackHandle:22];

        id response =
            [self invokeMethod:@"registerBackgroundHandler"
                     arguments:arguments];

        XCTAssertTrue([response isKindOfClass:FlutterError.class]);
        XCTAssertEqualObjects(
            ((FlutterError *)response).code,
            @"invalid_background_handler");

        RadarFlutterBackgroundHandlerHandles *handles =
            [self.store loadHandles];

        XCTAssertEqual(handles.dispatcherHandle, 11);
        XCTAssertEqual(handles.callbackHandle, 22);
    }
}

- (void)testUnregisterBackgroundHandlerClearsStoredHandles {
    [self.store saveDispatcherHandle:1 callbackHandle:2];

    id response =
        [self invokeMethod:@"unregisterBackgroundHandler"
                 arguments:nil];

    XCTAssertNil(response);
    XCTAssertNil([self.store loadHandles]);
}

- (void)testRegisterBackgroundHandlerMarksPrimarySinkReady {
    [self invokeMethod:@"registerBackgroundHandler"
             arguments:@{
        @"dispatcherHandle": @1,
        @"callbackHandle": @2,
    }];
    
    XCTAssertTrue(
                  self.coordinator.attachedSink ==
                  (id<RadarFlutterEventSink>)self.plugin);
}

- (void)testUnregisterBackgroundHandlerDetachesSinkAndClearsQueue {
    [self invokeMethod:@"registerBackgroundHandler"
             arguments:@{
                 @"dispatcherHandle": @1,
                 @"callbackHandle": @2,
             }];

    [self invokeMethod:@"unregisterBackgroundHandler"
             arguments:nil];

    XCTAssertTrue(
        self.coordinator.clearedSink ==
        (id<RadarFlutterEventSink>)self.plugin);
    XCTAssertEqual(self.coordinator.clearPendingEventsCallCount, 1);
}

- (void)testDetachFromEngineClearsPrimarySink {
    [self invokeMethod:@"registerBackgroundHandler"
             arguments:@{
                 @"dispatcherHandle": @1,
                 @"callbackHandle": @2,
             }];

    NSObject<FlutterPluginRegistrar> *registrar =
        (NSObject<FlutterPluginRegistrar> *)[NSObject new];

    [self.plugin detachFromEngineForRegistrar:registrar];

    XCTAssertTrue(
        self.coordinator.clearedSink ==
        (id<RadarFlutterEventSink>)self.plugin);
}

- (void)testClientLocationRoutesDurablePayload {
    CLLocation *location =
        [[CLLocation alloc] initWithLatitude:47.61 longitude:-122.33];

    [self.plugin
        didUpdateClientLocation:location
                        stopped:YES
                         source:RadarLocationSourceBackgroundLocation];

    XCTAssertEqualObjects(self.coordinator.routedMethod, @"clientLocation");
    XCTAssertEqualObjects(self.coordinator.routedPayload[@"stopped"], @YES);
    XCTAssertEqualObjects(
        self.coordinator.routedPayload[@"source"],
        @"BACKGROUND_LOCATION");

    NSDictionary *locationPayload =
        self.coordinator.routedPayload[@"location"];

    XCTAssertEqualWithAccuracy(
        [locationPayload[@"latitude"] doubleValue],
        47.61,
        0.000001);
    XCTAssertEqualWithAccuracy(
        [locationPayload[@"longitude"] doubleValue],
        -122.33,
        0.000001);
}

- (void)testSimpleCallbacksRouteDurablePayloads {
    [self.plugin didFailWithStatus:RadarStatusErrorLocation];

    XCTAssertEqualObjects(self.coordinator.routedMethod, @"error");
    XCTAssertEqualObjects(
        self.coordinator.routedPayload,
        (@{@"status": @"ERROR_LOCATION"}));

    [self.plugin didLogMessage:@"Test message"];

    XCTAssertEqualObjects(self.coordinator.routedMethod, @"log");
    XCTAssertEqualObjects(
        self.coordinator.routedPayload,
        (@{@"message": @"Test message"}));

    [self.plugin didChangeIP];

    XCTAssertEqualObjects(self.coordinator.routedMethod, @"ipChanged");
    XCTAssertEqualObjects(self.coordinator.routedPayload, @{});

    [self.plugin didChangeSharing:YES];

    XCTAssertEqualObjects(self.coordinator.routedMethod, @"sharingChanged");
    XCTAssertEqualObjects(
        self.coordinator.routedPayload,
        (@{@"sharing": @YES}));
}

- (void)testModelCallbacksRouteDurablePayloads {
    RadarFlutterTestUser *user = [RadarFlutterTestUser new];
    user.testDictionary = @{@"_id": @"user-id"};

    CLLocation *location =
        [[CLLocation alloc] initWithLatitude:47.61 longitude:-122.33];

    [self.plugin didUpdateLocation:location user:user];

    XCTAssertEqualObjects(self.coordinator.routedMethod, @"location");
    XCTAssertEqualObjects(
        self.coordinator.routedPayload[@"user"],
        user.testDictionary);
    XCTAssertEqualWithAccuracy(
        [self.coordinator.routedPayload[@"location"][@"latitude"]
            doubleValue],
        47.61,
        0.000001);

    RadarFlutterTestEvent *event = [RadarFlutterTestEvent new];
    event.testDictionary = @{@"_id": @"event-id"};

    [self.plugin didReceiveEvents:@[event] user:user];

    XCTAssertEqualObjects(self.coordinator.routedMethod, @"events");
    XCTAssertEqualObjects(
        self.coordinator.routedPayload,
        (@{
            @"events": @[event.testDictionary],
            @"user": user.testDictionary,
        }));

    RadarFlutterTestToken *token = [RadarFlutterTestToken new];
    token.testDictionary = @{@"token": @"signed-token"};

    [self.plugin didUpdateToken:token];

    XCTAssertEqualObjects(self.coordinator.routedMethod, @"token");
    XCTAssertEqualObjects(
        self.coordinator.routedPayload,
        (@{@"token": token.testDictionary}));
}
@end
