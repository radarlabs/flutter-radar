//
//  RadarFlutterPluginArgumentTests.m
//  Runner
//
//  Created by Alan Charles on 9/2/26.
//

#import <XCTest/XCTest.h>

#import "../../../ios/Classes/RadarFlutterPlugin.h"

@interface RadarFlutterPlugin (ArgumentTesting)

- (CLLocation *)nearLocationFromValue:(id)value;
- (BOOL)booleanFromValue:(id)value defaultValue:(BOOL)defaultValue;

@end

@interface RadarFlutterPluginArgumentTests : XCTestCase

@property(nonatomic, strong) RadarFlutterPlugin *plugin;

@end

@implementation RadarFlutterPluginArgumentTests

- (void)setUp {
    [super setUp];
    self.plugin = [[RadarFlutterPlugin alloc] init];
}

- (void)tearDown {
    self.plugin = nil;
    [super tearDown];
}

- (void)testNearLocationReturnsNilForInvalidValues {
    XCTAssertNil([self.plugin nearLocationFromValue:nil]);

    NSArray *invalidValues = @[
        NSNull.null,
        @"invalid",
        @[],
        @{},
        @{@"latitude": @47.6062},
        @{@"longitude": @(-122.3321)},
        @{
            @"latitude": @"47.6062",
            @"longitude": @(-122.3321),
        },
        @{
            @"latitude": @47.6062,
            @"longitude": @"-122.3321",
        },
    ];

    for (id value in invalidValues) {
        XCTAssertNil([self.plugin nearLocationFromValue:value]);
    }
}

- (void)testNearLocationReturnsLocationForValidCoordinates {
    CLLocation *location = [self.plugin
        nearLocationFromValue:@{
            @"latitude": @47.6062,
            @"longitude": @(-122.3321),
        }];

    XCTAssertNotNil(location);
    XCTAssertEqualWithAccuracy(location.coordinate.latitude, 47.6062, 0.000001);
    XCTAssertEqualWithAccuracy(
        location.coordinate.longitude,
        -122.3321,
        0.000001);
    XCTAssertEqualWithAccuracy(location.horizontalAccuracy, 5, 0.001);
}

- (void)testBooleanReturnsDefaultForInvalidValues {
    XCTAssertFalse([self.plugin booleanFromValue:nil defaultValue:NO]);
    XCTAssertTrue([self.plugin booleanFromValue:nil defaultValue:YES]);

    NSArray *invalidValues = @[
        NSNull.null,
        @"false",
        @[],
        @{},
    ];

    for (id value in invalidValues) {
        XCTAssertFalse(
            [self.plugin booleanFromValue:value defaultValue:NO]);
        XCTAssertTrue(
            [self.plugin booleanFromValue:value defaultValue:YES]);
    }
}

- (void)testBooleanReturnsNSNumberValue {
    XCTAssertFalse([self.plugin booleanFromValue:@NO defaultValue:YES]);
    XCTAssertTrue([self.plugin booleanFromValue:@YES defaultValue:NO]);
}

@end
