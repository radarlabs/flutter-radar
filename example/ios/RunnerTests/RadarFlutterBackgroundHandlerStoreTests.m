//
//  RadarFlutterBackgroundHandlerStoreTests.h
//  Runner
//
//  Created by Alan Charles on 8/6/26.
//


#import <XCTest/XCTest.h>

#import "../../../ios/Classes/RadarFlutterBackgroundHandlerStore.h"

@interface RadarFlutterBackgroundHandlerStoreTests : XCTestCase

@property(nonatomic, strong) NSString *suiteName;
@property(nonatomic, strong) NSUserDefaults *userDefaults;
@property(nonatomic, strong) RadarFlutterBackgroundHandlerStore *store;

@end

@implementation RadarFlutterBackgroundHandlerStoreTests

- (void)setUp {
    [super setUp];

    self.suiteName = [NSString stringWithFormat:
        @"RadarFlutterBackgroundHandlerStoreTests.%@",
        NSUUID.UUID.UUIDString];

    self.userDefaults =
        [[NSUserDefaults alloc] initWithSuiteName:self.suiteName];

    [self.userDefaults removePersistentDomainForName:self.suiteName];

    self.store = [[RadarFlutterBackgroundHandlerStore alloc]
        initWithUserDefaults:self.userDefaults];
}

- (void)tearDown {
    [self.userDefaults removePersistentDomainForName:self.suiteName];

    self.store = nil;
    self.userDefaults = nil;
    self.suiteName = nil;

    [super tearDown];
}

- (void)testLoadReturnsNilWhenNoHandlerIsStored {
    XCTAssertNil([self.store loadHandles]);
}

- (void)testSaveAndLoadPreserveBothHandles {
    int64_t dispatcherHandle = INT64_C(4294967296);
    int64_t callbackHandle = INT64_C(8589934592);

    [self.store saveDispatcherHandle:dispatcherHandle
                      callbackHandle:callbackHandle];

    RadarFlutterBackgroundHandlerHandles *handles =
        [self.store loadHandles];

    XCTAssertNotNil(handles);
    XCTAssertEqual(handles.dispatcherHandle, dispatcherHandle);
    XCTAssertEqual(handles.callbackHandle, callbackHandle);
}

- (void)testSaveReplacesPreviouslyStoredHandles {
    [self.store saveDispatcherHandle:1 callbackHandle:2];
    [self.store saveDispatcherHandle:3 callbackHandle:4];

    RadarFlutterBackgroundHandlerHandles *handles =
        [self.store loadHandles];

    XCTAssertEqual(handles.dispatcherHandle, 3);
    XCTAssertEqual(handles.callbackHandle, 4);
}

- (void)testClearRemovesStoredHandles {
    [self.store saveDispatcherHandle:1 callbackHandle:2];

    [self.store clear];

    XCTAssertNil([self.store loadHandles]);
}

- (void)testLoadRejectsNonDictionaryStoredValue {
    [self.userDefaults setObject:@"invalid"
                         forKey:@"flutter_radar_background_handler"];

    XCTAssertNil([self.store loadHandles]);
}

- (void)testLoadRejectsIncompleteStoredHandles {
    [self.userDefaults
        setObject:@{@"dispatcher_handle": @1}
           forKey:@"flutter_radar_background_handler"];

    XCTAssertNil([self.store loadHandles]);
}

- (void)testLoadRejectsHandlesWithInvalidTypes {
    [self.userDefaults
        setObject:@{
            @"dispatcher_handle": @"1",
            @"callback_handle": @2,
        }
           forKey:@"flutter_radar_background_handler"];

    XCTAssertNil([self.store loadHandles]);
}

@end