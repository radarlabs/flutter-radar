#import "RadarFlutterPlugin.h"

#import <RadarSDK/RadarSDK.h>

@interface RadarFlutterPlugin() <RadarDelegate, RadarVerifiedDelegate>

@property (strong, nonatomic) FlutterMethodChannel *channel;
@property (strong, nonatomic) FlutterMethodChannel *backgroundChannel;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) FlutterEngine *sBackgroundFlutterEngine;
@property (strong, nonatomic) FlutterResult permissionsRequestResult;

@end

@implementation RadarFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    RadarFlutterPlugin *instance = [[RadarFlutterPlugin alloc] init];

    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"flutter_radar" binaryMessenger:[registrar messenger]];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    [Radar setDelegate:self];
    [Radar setVerifiedDelegate:self];
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (self.permissionsRequestResult) {
        [self getPermissionsStatus:self.permissionsRequestResult];
        self.permissionsRequestResult = nil;
    }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        [self initialize:call withResult:result];
    } else if ([@"setLogLevel" isEqualToString:call.method]) {
        [self setLogLevel:call withResult:result];
    } else if ([@"getPermissionsStatus" isEqualToString:call.method]) {
        [self getPermissionsStatus:result];
    } else if ([@"requestPermissions" isEqualToString:call.method]) {
        [self requestPermissions:call withResult:result];
    } else if ([@"setUserId" isEqualToString:call.method]) {
        [self setUserId:call withResult:result];
    } else if ([@"getUserId" isEqualToString:call.method]) {
        [self getUserId:call withResult:result];
    } else if ([@"setDescription" isEqualToString:call.method]) {
        [self setDescription:call withResult:result];
    } else if ([@"getDescription" isEqualToString:call.method]) {
        [self getDescription:call withResult:result];
    } else if ([@"setMetadata" isEqualToString:call.method]) {
        [self setMetadata:call withResult:result];
    } else if ([@"getMetadata" isEqualToString:call.method]) {
        [self getMetadata:call withResult:result];
    } else if ([@"setAnonymousTrackingEnabled" isEqualToString:call.method]) {
        [self setAnonymousTrackingEnabled:call withResult:result];
    } else if ([@"getLocation" isEqualToString:call.method]) {
        [self getLocation:call withResult:result];
    } else if ([@"trackOnce" isEqualToString:call.method]) {
        [self trackOnce:call withResult:result];
    } else if ([@"startTracking" isEqualToString:call.method]) {
        [self startTracking:call withResult:result];
    } else if ([@"startTrackingCustom" isEqualToString:call.method]) {
        [self startTrackingCustom:call withResult:result];
    } else if ([@"startTrackingVerified" isEqualToString:call.method]) {
        [self startTrackingVerified:call withResult:result];
    } else if ([@"stopTrackingVerified" isEqualToString:call.method]) {
        [self stopTrackingVerified:call withResult:result];
    } else if ([@"stopTracking" isEqualToString:call.method]) {
        [self stopTracking:call withResult:result];
    } else if ([@"isTracking" isEqualToString:call.method]) {
        [self isTracking:call withResult:result];
    } else if ([@"getTrackingOptions" isEqualToString:call.method]) {
        [self getTrackingOptions:call withResult:result];
    } else if ([@"mockTracking" isEqualToString:call.method]) {
        [self mockTracking:call withResult:result];
    } else if ([@"startTrip" isEqualToString:call.method]) {
       [self startTrip:call withResult:result];
    } else if ([@"updateTrip" isEqualToString:call.method]) {
       [self updateTrip:call withResult:result];
    } else if ([@"getTripOptions" isEqualToString:call.method]) {
        [self getTripOptions:call withResult:result];
    } else if ([@"completeTrip" isEqualToString:call.method]) {
        [self completeTrip:call withResult:result];
    } else if ([@"cancelTrip" isEqualToString:call.method]) {
        [self cancelTrip:call withResult:result];
    } else if ([@"getContext" isEqualToString:call.method]) {
        [self getContext:call withResult:result];
    } else if ([@"searchGeofences" isEqualToString:call.method]) {
        [self searchGeofences:call withResult:result];
    } else if ([@"searchPlaces" isEqualToString:call.method]) {
        [self searchPlaces:call withResult:result];
    } else if ([@"autocomplete" isEqualToString:call.method]) {
        [self autocomplete:call withResult:result];
    } else if ([@"forwardGeocode" isEqualToString:call.method]) {
      [self geocode:call withResult:result];
    } else if ([@"reverseGeocode" isEqualToString:call.method]) {
        [self reverseGeocode:call withResult:result];
    } else if ([@"ipGeocode" isEqualToString:call.method]) {
        [self ipGeocode:call withResult:result];
    } else if ([@"getDistance" isEqualToString:call.method]) {
        [self getDistance:call withResult:result];
    } else if ([@"logConversion" isEqualToString:call.method]) {
        [self logConversion:call withResult:result];        
    } else if ([@"logTermination" isEqualToString:call.method]) {
        [self logTermination:result];        
    } else if ([@"logBackgrounding" isEqualToString:call.method]) {
        [self logBackgrounding:result];        
    } else if ([@"logResigningActive" isEqualToString:call.method]) {
        [self logResigningActive:result];        
    } else if ([@"getMatrix" isEqualToString:call.method]) {
        [self getMatrix:call withResult:result];        
    } else if ([@"setNotificationOptions" isEqualToString:call.method]) {
        // do nothing
    } else if ([@"setForegroundServiceOptions" isEqualToString:call.method]) {
        // do nothing
    } else if ([@"trackVerified" isEqualToString:call.method]) {
        [self trackVerified:call withResult:result];    
    } else if ([@"isUsingRemoteTrackingOptions" isEqualToString:call.method]) {
        [self isUsingRemoteTrackingOptions:call withResult:result];    
    } else if ([@"validateAddress" isEqualToString:call.method]) {
        [self validateAddress:call withResult:result];
    } else if ([@"attachListeners" isEqualToString:call.method]) {
        [self attachListeners:call withResult:result];
    } else if ([@"detachListeners" isEqualToString:call.method]) {
        [self detachListeners:call withResult:result];
    } else if ([@"on" isEqualToString:call.method]) {
        [self on:call withResult:result];
    } else if ([@"off" isEqualToString:call.method]) {
        [self off:call withResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)initialize:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSString *publishableKey = argsDict[@"publishableKey"];
    [[NSUserDefaults standardUserDefaults] setObject:@"Flutter" forKey:@"radar-xPlatformSDKType"];
    [[NSUserDefaults standardUserDefaults] setObject:@"3.10.0" forKey:@"radar-xPlatformSDKVersion"];
    [Radar initializeWithPublishableKey:publishableKey];
    result(nil);
}

- (void)setLogLevel:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSString *logLevel = argsDict[@"logLevel"];
    if (!logLevel) {
        [Radar setLogLevel:RadarLogLevelNone];
    } else if ([logLevel isEqualToString:@"debug"]) {
        [Radar setLogLevel:RadarLogLevelDebug];
    } else if ([logLevel isEqualToString:@"info"]) {
        [Radar setLogLevel:RadarLogLevelInfo];
    } else if ([logLevel isEqualToString:@"warning"]) {
        [Radar setLogLevel:RadarLogLevelWarning];
    } else if ([logLevel isEqualToString:@"error"]) {
        [Radar setLogLevel:RadarLogLevelError];
    } else {
        [Radar setLogLevel:RadarLogLevelNone];
    }
    result(nil);
}

- (void)getPermissionsStatus:(FlutterResult)result {
    if (!result) {
        return;
    }
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    NSString *statusStr;
    switch (status) {
        case kCLAuthorizationStatusDenied:
            statusStr = @"DENIED";
            break;
        case kCLAuthorizationStatusRestricted:
            statusStr = @"DENIED";
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            statusStr = @"GRANTED_BACKGROUND";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusStr = @"GRANTED_FOREGROUND";
            break;
        case kCLAuthorizationStatusNotDetermined:
            statusStr = @"NOT_DETERMINED";
            break;
        default:
            statusStr = @"DENIED";
            break;
    }
    result(statusStr);
}

- (void)requestPermissions:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    self.permissionsRequestResult = result;

    NSDictionary *argsDict = call.arguments;

    NSNumber *backgroundNumber = argsDict[@"background"];
    BOOL background = [backgroundNumber boolValue];
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (background && status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager requestAlwaysAuthorization];
    } else if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    } else {
        [self getPermissionsStatus:result];
    }
}

- (void)setUserId:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSString *userId = argsDict[@"userId"];
    [Radar setUserId:userId];
    result(nil);
}

- (void)getUserId:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSString *userId = [Radar getUserId];
    result(userId);
}

- (void)setDescription:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSString *description = argsDict[@"description"];
    [Radar setDescription:description];
    result(nil);
}

- (void)getDescription:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSString *description = [Radar getDescription];
    result(description);
}

- (void)setMetadata:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *metadata = call.arguments;
    [Radar setMetadata:metadata];
    result(nil);
}

- (void)getMetadata:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *metadata = [Radar getMetadata];
    result(metadata);
}

- (void)setAnonymousTrackingEnabled:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSNumber* enabledNumber = argsDict[@"enabled"];
    BOOL enabled = [enabledNumber boolValue];
    [Radar setAnonymousTrackingEnabled:enabled];
    result(nil);
}


- (void)getLocation:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarLocationCompletionHandler completionHandler = ^(RadarStatus status, CLLocation *location, BOOL stopped) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
        if (location) {
            [dict setObject:[Radar dictionaryForLocation:location] forKey:@"location"];
        }
        [dict setObject:@(stopped) forKey:@"stopped"];
        result(dict);
    };

    NSDictionary *argsDict = call.arguments;

    NSString *accuracy = argsDict[@"accuracy"];
    if (!accuracy) {
        [Radar getLocationWithCompletionHandler:completionHandler];
    } else if ([accuracy isEqualToString:@"high"]) {
        [Radar getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyHigh completionHandler:completionHandler];
    } else if ([accuracy isEqualToString:@"medium"]) {
        [Radar getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyMedium completionHandler:completionHandler];
    } else if ([accuracy isEqualToString:@"low"]) {
        [Radar getLocationWithDesiredAccuracy:RadarTrackingOptionsDesiredAccuracyLow completionHandler:completionHandler];
    } else {
        [Radar getLocationWithCompletionHandler:completionHandler];
    }
}

- (void)trackOnce:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarTrackCompletionHandler completionHandler = ^(RadarStatus status, CLLocation *location, NSArray<RadarEvent *> *events, RadarUser *user) {
        if (status == RadarStatusSuccess) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
            if (location) {
                [dict setObject:[Radar dictionaryForLocation:location] forKey:@"location"];
            }
            if (events) {
                [dict setObject:[RadarEvent arrayForEvents:events] forKey:@"events"];
            }
            if (user) {
                [dict setObject:[user dictionaryValue] forKey:@"user"];
            }
            result(dict);
        }
    };

    NSDictionary *argsDict = call.arguments;

    NSDictionary *locationDict = argsDict[@"location"];
    if (locationDict != nil && [locationDict isKindOfClass:[NSDictionary class]]) {
        NSNumber *latitudeNumber = locationDict[@"latitude"];
        NSNumber *longitudeNumber = locationDict[@"longitude"];
        NSNumber *accuracyNumber = locationDict[@"accuracy"];
        double latitude = [latitudeNumber doubleValue];
        double longitude = [longitudeNumber doubleValue];
        double accuracy = accuracyNumber ? [accuracyNumber doubleValue] : -1;
        CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:accuracy verticalAccuracy:-1 timestamp:[NSDate date]];
        [Radar trackOnceWithLocation:location completionHandler:completionHandler];
    } else {
        RadarTrackingOptionsDesiredAccuracy desiredAccuracy = RadarTrackingOptionsDesiredAccuracyMedium;
        BOOL beaconsTrackingOption = NO;

        NSString *accuracy = argsDict[@"desiredAccuracy"];

        if (accuracy != nil && [accuracy isKindOfClass:[NSString class]]) {
            NSString *lowerAccuracy = [accuracy lowercaseString];
            if ([lowerAccuracy isEqualToString:@"high"]) {
                desiredAccuracy = RadarTrackingOptionsDesiredAccuracyHigh;
            } else if ([lowerAccuracy isEqualToString:@"medium"]) {
                desiredAccuracy = RadarTrackingOptionsDesiredAccuracyMedium;
            } else if ([lowerAccuracy isEqualToString:@"low"]) {
                desiredAccuracy = RadarTrackingOptionsDesiredAccuracyLow;
            }
        }
        
        BOOL beacons = argsDict[@"beacons"];

        if (beacons) {
            beaconsTrackingOption = beacons;
        }
        
        [Radar trackOnceWithDesiredAccuracy:desiredAccuracy beacons:beaconsTrackingOption completionHandler:completionHandler];
    }
}

- (void)startTracking:(FlutterMethodCall *)call withResult:(FlutterResult)result {    
    NSDictionary *argsDict = call.arguments;

    NSString *preset = argsDict[@"preset"];
    if (!preset) {
        [Radar startTrackingWithOptions:RadarTrackingOptions.presetResponsive];
    } else if ([preset isEqualToString:@"continuous"]) {
        [Radar startTrackingWithOptions:RadarTrackingOptions.presetContinuous];
    } else if ([preset isEqualToString:@"responsive"]) {
        [Radar startTrackingWithOptions:RadarTrackingOptions.presetResponsive];
    } else if ([preset isEqualToString:@"efficient"]) {
        [Radar startTrackingWithOptions:RadarTrackingOptions.presetEfficient];
    } else {
        [Radar startTrackingWithOptions:RadarTrackingOptions.presetResponsive];
    }
    result(nil);
}

- (void)startTrackingCustom:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *optionsDict = call.arguments;
    RadarTrackingOptions *options = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    [Radar startTrackingWithOptions:options];
    result(nil);
}

- (void)startTrackingVerified:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    BOOL beacons = NO;
    NSNumber *beaconsNumber = argsDict[@"beacons"];
    if (beaconsNumber != nil && [beaconsNumber isKindOfClass:[NSNumber class]]) {
        beacons = [beaconsNumber boolValue];
    }

    double interval = 1;
    NSNumber *intervalNumber = argsDict[@"interval"];
    if (intervalNumber != nil && [intervalNumber isKindOfClass:[NSNumber class]]) {
        interval = [intervalNumber doubleValue];
    }

    [Radar startTrackingVerifiedWithInterval:interval beacons:beacons];
    result(nil);
}

- (void)stopTrackingVerified:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [Radar stopTrackingVerified];
    result(nil);
}

- (void)stopTracking:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [Radar stopTracking];
    result(nil);
}

- (void)isTracking:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    BOOL isTracking = [Radar isTracking];
    result(@(isTracking));
}

- (void)isUsingRemoteTrackingOptions:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    BOOL isRemoteTracking = [Radar isUsingRemoteTrackingOptions];
    result(@(isRemoteTracking));
}

- (void)getTrackingOptions:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarTrackingOptions* options = [Radar getTrackingOptions];
    result([options dictionaryValue]);
}

- (void)mockTracking:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSDictionary *originDict = argsDict[@"origin"];
    NSNumber *originLatitudeNumber = originDict[@"latitude"];
    NSNumber *originLongitudeNumber = originDict[@"longitude"];
    double originLatitude = [originLatitudeNumber doubleValue];
    double originLongitude = [originLongitudeNumber doubleValue];
    CLLocation *origin = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(originLatitude, originLongitude) altitude:-1 horizontalAccuracy:5 verticalAccuracy:-1 timestamp:[NSDate date]];
    NSDictionary *destinationDict = argsDict[@"destination"];
    NSNumber *destinationLatitudeNumber = destinationDict[@"latitude"];
    NSNumber *destinationLongitudeNumber = destinationDict[@"longitude"];
    double destinationLatitude = [destinationLatitudeNumber doubleValue];
    double destinationLongitude = [destinationLongitudeNumber doubleValue];
    CLLocation *destination = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(destinationLatitude, destinationLongitude) altitude:-1 horizontalAccuracy:5 verticalAccuracy:-1 timestamp:[NSDate date]];
    NSString *modeStr = argsDict[@"mode"];
    RadarRouteMode mode = RadarRouteModeCar;
    if ([modeStr isEqualToString:@"FOOT"] || [modeStr isEqualToString:@"foot"]) {
        mode = RadarRouteModeFoot;
    } else if ([modeStr isEqualToString:@"BIKE"] || [modeStr isEqualToString:@"bike"]) {
        mode = RadarRouteModeBike;
    } else if ([modeStr isEqualToString:@"CAR"] || [modeStr isEqualToString:@"car"]) {
        mode = RadarRouteModeCar;
    }
    NSNumber *stepsNumber = argsDict[@"steps"];
    int steps;
    if (stepsNumber != nil && [stepsNumber isKindOfClass:[NSNumber class]]) {
        steps = [stepsNumber intValue];
    } else {
        steps = 10;
    }
    NSNumber *intervalNumber = argsDict[@"interval"];
    int interval;
    if (intervalNumber != nil && [intervalNumber isKindOfClass:[NSNumber class]]) {
        interval = [intervalNumber intValue];
    } else {
        interval = 1;
    }

    [Radar mockTrackingWithOrigin:origin destination:destination mode:mode steps:steps interval:interval completionHandler:nil];
}

- (void)startTrip:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarTripCompletionHandler completionHandler = ^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
        if (status == RadarStatusSuccess) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
            if (trip) {
                [dict setObject:[trip dictionaryValue] forKey:@"trip"];
            }
            if (events) {
                [dict setObject:[RadarEvent arrayForEvents:events] forKey:@"events"];
            }
            result(dict);
        }
    };
    NSDictionary *argsDict = call.arguments;
    NSDictionary *tripOptionsDict = argsDict[@"tripOptions"];
    RadarTripOptions *tripOptions = [RadarTripOptions tripOptionsFromDictionary:tripOptionsDict];
    NSDictionary *trackingOptionsDict = argsDict[@"trackingOptions"];
    RadarTrackingOptions *trackingOptions;
    if (trackingOptionsDict) {
        trackingOptions = [RadarTrackingOptions trackingOptionsFromDictionary:trackingOptionsDict];
    }

    [Radar startTripWithOptions:tripOptions trackingOptions:trackingOptions completionHandler:completionHandler];
}

- (void)updateTrip:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarTripCompletionHandler completionHandler = ^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
        if (status == RadarStatusSuccess) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
            if (trip) {
                [dict setObject:[trip dictionaryValue] forKey:@"trip"];
            }
            if (events) {
                [dict setObject:[RadarEvent arrayForEvents:events] forKey:@"events"];
            }
            result(dict);
        }
    };
    NSDictionary *argsDict = call.arguments;
    NSDictionary *tripOptionsDict = argsDict[@"tripOptions"];
    RadarTripOptions *tripOptions = [RadarTripOptions tripOptionsFromDictionary:tripOptionsDict];
    NSString* statusStr = argsDict[@"status"];
    RadarTripStatus status = RadarTripStatusUnknown;
    statusStr = [statusStr lowercaseString];
    if ([statusStr isEqualToString:@"started"]) {
        status = RadarTripStatusStarted;
    } else if ([statusStr isEqualToString:@"approaching"]) {
        status = RadarTripStatusApproaching;
    } else if ([statusStr isEqualToString:@"arrived"]) {
        status = RadarTripStatusArrived;
    } else if ([statusStr isEqualToString:@"completed"]) {
        status = RadarTripStatusCompleted;
    } else if ([statusStr isEqualToString:@"canceled"]) {
        status = RadarTripStatusCanceled;
    }

    [Radar updateTripWithOptions:tripOptions status:status completionHandler:completionHandler];
}

- (void)getTripOptions:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarTripOptions *options = [Radar getTripOptions];
    NSDictionary *optionsDict;
    if (options) {
      optionsDict = [options dictionaryValue];
    }
    result(optionsDict);
}

- (void)completeTrip:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarTripCompletionHandler completionHandler = ^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
        if (status == RadarStatusSuccess) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
            if (trip) {
                [dict setObject:[trip dictionaryValue] forKey:@"trip"];
            }
            if (events) {
                [dict setObject:[RadarEvent arrayForEvents:events] forKey:@"events"];
            }
            result(dict);
        }
    };
    [Radar completeTripWithCompletionHandler:completionHandler];
}

- (void)cancelTrip:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarTripCompletionHandler completionHandler = ^(RadarStatus status, RadarTrip *trip, NSArray<RadarEvent *> *events) {
        if (status == RadarStatusSuccess) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
            if (trip) {
                [dict setObject:[trip dictionaryValue] forKey:@"trip"];
            }
            if (events) {
                [dict setObject:[RadarEvent arrayForEvents:events] forKey:@"events"];
            }
            result(dict);
        }
    };
    [Radar cancelTripWithCompletionHandler:completionHandler];
}

- (void)getContext:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarContextCompletionHandler completionHandler = ^(RadarStatus status, CLLocation * _Nullable location, RadarContext * _Nullable context) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
        if (location) {
            [dict setObject:[Radar dictionaryForLocation:location] forKey:@"location"];
        }
        if (context) {
            [dict setObject:[context dictionaryValue] forKey:@"context"];
        }
        result(dict);
    };

    NSDictionary *argsDict = call.arguments;

    NSDictionary *locationDict = argsDict[@"location"];
    if (locationDict) {
        NSNumber *latitudeNumber = locationDict[@"latitude"];
        NSNumber *longitudeNumber = locationDict[@"longitude"];
        NSNumber *accuracyNumber = locationDict[@"accuracy"];
        double latitude = [latitudeNumber doubleValue];
        double longitude = [longitudeNumber doubleValue];
        double accuracy = accuracyNumber ? [accuracyNumber doubleValue] : -1;
        CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:accuracy verticalAccuracy:-1 timestamp:[NSDate date]];
        [Radar getContextForLocation:location completionHandler:completionHandler];
    } else {
        [Radar getContextWithCompletionHandler:completionHandler];
    }
}

- (void)searchGeofences:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarSearchGeofencesCompletionHandler completionHandler = ^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarGeofence *> * _Nullable geofences) {
        if (status == RadarStatusSuccess) {
          NSMutableDictionary *dict = [NSMutableDictionary new];
          [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
          if (location) {
              [dict setObject:[Radar dictionaryForLocation:location] forKey:@"location"];
          }
          if (geofences) {
              [dict setObject:[RadarGeofence arrayForGeofences:geofences] forKey:@"geofences"];
          }
          result(dict);
        }
    };

    NSDictionary *argsDict = call.arguments;

    CLLocation *near;
    NSDictionary *nearDict = argsDict[@"near"];
    if (nearDict) {
        NSNumber *latitudeNumber = nearDict[@"latitude"];
        NSNumber *longitudeNumber = nearDict[@"longitude"];
        double latitude = [latitudeNumber doubleValue];
        double longitude = [longitudeNumber doubleValue];
        near = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:5 verticalAccuracy:-1 timestamp:[NSDate date]];
    }
    NSNumber *radiusNumber = argsDict[@"radius"];
    int radius;
    if (radiusNumber != nil && [radiusNumber isKindOfClass:[NSNumber class]]) {
        radius = [radiusNumber intValue];
    } else {
        radius = 1000;
    }
    NSArray *tags = argsDict[@"tags"];
    NSDictionary *metadata = argsDict[@"metadata"];
    NSNumber *limitNumber = argsDict[@"limit"];
    int limit;
    if (limitNumber != nil && [limitNumber isKindOfClass:[NSNumber class]]) {
        limit = [limitNumber intValue];
    } else {
        limit = 10;
    }
    BOOL includeGeometry = NO;
    NSNumber *includeGeometryNumber = argsDict[@"includeGeometry"];
    if (includeGeometryNumber != nil && [includeGeometryNumber isKindOfClass:[NSNumber class]]) {
        includeGeometry = [includeGeometryNumber boolValue];
    }


    if (near != nil) {
        [Radar searchGeofencesNear:near radius:radius tags:tags metadata:metadata limit:limit includeGeometry:includeGeometry completionHandler:completionHandler];
    } else {
        [Radar searchGeofences:completionHandler];
    }
}

- (void)searchPlaces:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarSearchPlacesCompletionHandler completionHandler = ^(RadarStatus status, CLLocation * _Nullable location, NSArray<RadarPlace *> * _Nullable places) {
        if (status == RadarStatusSuccess) {
          NSMutableDictionary *dict = [NSMutableDictionary new];
          [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
          if (location) {
              [dict setObject:[Radar dictionaryForLocation:location] forKey:@"location"];
          }
          if (places) {
              [dict setObject:[RadarPlace arrayForPlaces:places] forKey:@"places"];
          }
          result(dict);
        }
    };

    NSDictionary *argsDict = call.arguments;

    CLLocation *near;
    NSDictionary *nearDict = argsDict[@"near"];
    if (nearDict) {
        NSNumber *latitudeNumber = nearDict[@"latitude"];
        NSNumber *longitudeNumber = nearDict[@"longitude"];
        double latitude = [latitudeNumber doubleValue];
        double longitude = [longitudeNumber doubleValue];
        near = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:5 verticalAccuracy:-1 timestamp:[NSDate date]];
    }
    NSNumber *radiusNumber = argsDict[@"radius"];
    int radius;
    if (radiusNumber != nil && [radiusNumber isKindOfClass:[NSNumber class]]) {
        radius = [radiusNumber intValue];
    } else {
        radius = 1000;
    }
    NSArray *chains = argsDict[@"chains"];
    NSDictionary *chainMetadata = [argsDict[@"chainMetadata"] isKindOfClass:[NSNull class]] ? nil : argsDict[@"chainMetadata"];
    NSArray *categories = [argsDict[@"categories"] isKindOfClass:[NSNull class]] ? nil : argsDict[@"categories"];
    NSArray *groups = [argsDict[@"groups"] isKindOfClass:[NSNull class]] ? nil : argsDict[@"groups"];
    NSNumber *limitNumber = argsDict[@"limit"];
    int limit;
    if (limitNumber != nil && [limitNumber isKindOfClass:[NSNumber class]]) {
        limit = [limitNumber intValue];
    } else {
        limit = 10;
    }

    if (near != nil) {
        [Radar searchPlacesNear:near radius:radius chains:chains chainMetadata:chainMetadata categories:categories groups:groups limit:limit completionHandler:completionHandler];
    } else {
        [Radar searchPlacesWithRadius:radius chains:chains chainMetadata:chainMetadata categories:categories groups:groups limit:limit completionHandler:completionHandler];
    }
}

- (void)autocomplete:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;
    
    NSString *query = argsDict[@"query"];
    CLLocation *near;
    NSDictionary *nearDict = argsDict[@"near"];
    if (nearDict) {
        NSNumber *latitudeNumber = nearDict[@"latitude"];
        NSNumber *longitudeNumber = nearDict[@"longitude"];
        double latitude = [latitudeNumber doubleValue];
        double longitude = [longitudeNumber doubleValue];
        near = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:5 verticalAccuracy:-1 timestamp:[NSDate date]];
    }
    NSNumber *limitNumber = argsDict[@"limit"];
    int limit;
    if (limitNumber != nil && [limitNumber isKindOfClass:[NSNumber class]]) {
        limit = [limitNumber intValue];
    } else {
        limit = 10;
    }
    NSArray *layers = [argsDict[@"layers"] isKindOfClass:[NSNull class]] ? nil : argsDict[@"layers"];
    NSString *country = [argsDict[@"country"] isKindOfClass:[NSNull class]] ? nil : argsDict[@"country"];
    
    RadarGeocodeCompletionHandler completionHandler = ^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
        if (addresses) {
            [dict setObject:[RadarAddress arrayForAddresses:addresses] forKey:@"addresses"];
        }
        result(dict);
    };

    
    NSNumber *mailableNumber = argsDict[@"mailable"];
    if (mailableNumber != nil && [mailableNumber isKindOfClass:[NSNumber class]]) {
        BOOL mailable = [mailableNumber boolValue];
        [Radar autocompleteQuery:query near:near layers:layers limit:limit country:country mailable:mailable completionHandler:completionHandler];
    } else {
        [Radar autocompleteQuery:query near:near layers:layers limit:limit country:country completionHandler:completionHandler];
    }
}

- (void)geocode:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSString *query = argsDict[@"query"];
    [Radar geocodeAddress:query completionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
        if (addresses) {
           [dict setObject:[RadarAddress arrayForAddresses:addresses] forKey:@"addresses"];
        }
        result(dict);
    }];
}

- (void)reverseGeocode:(FlutterMethodCall *)call withResult:(FlutterResult)result {
  RadarGeocodeCompletionHandler completionHandler = ^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
      NSMutableDictionary *dict = [NSMutableDictionary new];
      [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
      if (addresses) {
        [dict setObject:[RadarAddress arrayForAddresses:addresses] forKey:@"addresses"];
      }
      result(dict);
  };

    NSDictionary *argsDict = call.arguments;

    NSArray<NSString *> *layers = nil;
    id layersValue = argsDict[@"layers"];
    if (layersValue != nil && [layersValue isKindOfClass:[NSArray class]]) {
        NSArray *tempLayers = (NSArray *)layersValue;
        // Further check if the array contains only NSString objects
        BOOL allStrings = YES;
        for (id item in tempLayers) {
            if (![item isKindOfClass:[NSString class]]) {
                allStrings = NO;
                break;
            }
        }
        if (allStrings) {
            layers = tempLayers;
        }
    }

  NSDictionary *locationDict = nil;
  id locationDictValue = argsDict[@"location"];
  if (locationDictValue != nil && [locationDictValue isKindOfClass:[NSDictionary class]]) {
      locationDict = (NSDictionary *)locationDictValue;
  }
  if (locationDict) {
      NSNumber *latitudeNumber = locationDict[@"latitude"];
      NSNumber *longitudeNumber = locationDict[@"longitude"];
      double latitude = [latitudeNumber doubleValue];
      double longitude = [longitudeNumber doubleValue];
      CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:5 verticalAccuracy:-1 timestamp:[NSDate date]];

      [Radar reverseGeocodeLocation:location layers:layers completionHandler:completionHandler];
  } else {
      [Radar reverseGeocodeWithLayers:layers completionHandler:completionHandler];
  }
}

- (void)ipGeocode:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [Radar ipGeocodeWithCompletionHandler:^(RadarStatus status, RadarAddress * _Nullable address, BOOL proxy) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
        if (address) {
            [dict setObject:[address dictionaryValue] forKey:@"address"];
            [dict setValue:@(proxy) forKey:@"proxy"];
        }
        result(dict);
    }];
}

- (void)getDistance:(FlutterMethodCall *)call withResult:(FlutterResult)result {
  RadarRouteCompletionHandler completionHandler = ^(RadarStatus status, RadarRoutes * _Nullable routes) {
      NSMutableDictionary *dict = [NSMutableDictionary new];
      [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
      if (routes) {
          [dict setObject:[routes dictionaryValue] forKey:@"routes"];
      }
      result(dict);
  };

  NSDictionary *argsDict = call.arguments;

  CLLocation *origin;
  NSDictionary *originDict = argsDict[@"origin"];
  if (originDict) {
      NSNumber *originLatitudeNumber = originDict[@"latitude"];
      NSNumber *originLongitudeNumber = originDict[@"longitude"];
      double originLatitude = [originLatitudeNumber doubleValue];
      double originLongitude = [originLongitudeNumber doubleValue];
      origin = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(originLatitude, originLongitude) altitude:-1 horizontalAccuracy:5 verticalAccuracy:-1 timestamp:[NSDate date]];
  }
  NSDictionary *destinationDict = argsDict[@"destination"];
  NSNumber *destinationLatitudeNumber = destinationDict[@"latitude"];
  NSNumber *destinationLongitudeNumber = destinationDict[@"longitude"];
  double destinationLatitude = [destinationLatitudeNumber doubleValue];
  double destinationLongitude = [destinationLongitudeNumber doubleValue];
  CLLocation *destination = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(destinationLatitude, destinationLongitude) altitude:-1 horizontalAccuracy:5 verticalAccuracy:-1 timestamp:[NSDate date]];
  NSArray *modesArr = argsDict[@"modes"];
  RadarRouteMode modes = 0;
  if (modesArr != nil) {
      if ([modesArr containsObject:@"FOOT"] || [modesArr containsObject:@"foot"]) {
          modes = modes | RadarRouteModeFoot;
      }
      if ([modesArr containsObject:@"BIKE"] || [modesArr containsObject:@"bike"]) {
          modes = modes | RadarRouteModeBike;
      }
      if ([modesArr containsObject:@"CAR"] || [modesArr containsObject:@"car"]) {
          modes = modes | RadarRouteModeCar;
      }
  } else {
      modes = RadarRouteModeCar;
  }
  NSString *unitsStr = argsDict[@"units"];
  RadarRouteUnits units;
  if (unitsStr != nil && [unitsStr isKindOfClass:[NSString class]]) {
      units = [unitsStr isEqualToString:@"METRIC"] || [unitsStr isEqualToString:@"metric"] ? RadarRouteUnitsMetric : RadarRouteUnitsImperial;
  } else {
      units = RadarRouteUnitsImperial;
  }

  if (call.arguments[@"origin"]) {
     [Radar getDistanceFromOrigin:origin destination:destination modes:modes units:units completionHandler:completionHandler];
  } else {
     [Radar getDistanceToDestination:destination modes:modes units:units completionHandler:completionHandler];
  }
}

- (void)logConversion:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    RadarLogConversionCompletionHandler completionHandler = ^(RadarStatus status, RadarEvent *event) {
        if (status == RadarStatusSuccess) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
            if (event) {
                [dict setObject:[event dictionaryValue] forKey:@"event"];
            }
            result(dict);
        }
    };

    NSDictionary *argsDict = call.arguments;

    NSDictionary *metadata = argsDict[@"metadata"];
    NSString *name = argsDict[@"name"];
    NSNumber *revenueNumber = argsDict[@"revenue"];
    if (revenueNumber != nil && [revenueNumber isKindOfClass:[NSNumber class]]) {
        [Radar logConversionWithName:name revenue:revenueNumber metadata:metadata completionHandler:completionHandler];
    } else {
        [Radar logConversionWithName:name metadata:metadata completionHandler:completionHandler];
    }
}

- (void)logTermination:(FlutterResult)result {
    [Radar logTermination];
    result(nil);
}

- (void)logBackgrounding:(FlutterResult)result {
    [Radar logBackgrounding];
    result(nil);
}

- (void)logResigningActive:(FlutterResult)result {
    [Radar logResigningActive];
    result(nil);
}

- (void)getMatrix:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;
    
    NSArray<NSDictionary *> *originsArr = argsDict[@"origins"];
    NSMutableArray<CLLocation *> *origins = [NSMutableArray new];
    for (NSDictionary *originDict in originsArr) {        
        NSNumber *latitudeNumber = originDict[@"latitude"];
        NSNumber *longitudeNumber = originDict[@"longitude"];
        NSNumber *accuracyNumber = originDict[@"accuracy"];
        double latitude = [latitudeNumber doubleValue];
        double longitude = [longitudeNumber doubleValue];
        double accuracy = accuracyNumber ? [accuracyNumber doubleValue] : -1;
        CLLocation *origin = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:accuracy verticalAccuracy:-1 timestamp:[NSDate date]];
        [origins addObject:origin];
    }
    NSArray<NSDictionary *> *destinationsArr = argsDict[@"destinations"];
    NSMutableArray<CLLocation *> *destinations = [NSMutableArray new];
    for (NSDictionary *destinationDict in destinationsArr) {
        NSNumber *latitudeNumber = destinationDict[@"latitude"];
        NSNumber *longitudeNumber = destinationDict[@"longitude"];
        NSNumber *accuracyNumber = destinationDict[@"accuracy"];
        double latitude = [latitudeNumber doubleValue];
        double longitude = [longitudeNumber doubleValue];
        double accuracy = accuracyNumber ? [accuracyNumber doubleValue] : -1;
        CLLocation *destination = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:accuracy verticalAccuracy:-1 timestamp:[NSDate date]];
        [destinations addObject:destination];
    }
    NSString *modeStr = argsDict[@"mode"];
    RadarRouteMode mode = RadarRouteModeCar;
    if ([modeStr isEqualToString:@"FOOT"] || [modeStr isEqualToString:@"foot"]) {
        mode = RadarRouteModeFoot;
    } else if ([modeStr isEqualToString:@"BIKE"] || [modeStr isEqualToString:@"bike"]) {
        mode = RadarRouteModeBike;
    } else if ([modeStr isEqualToString:@"CAR"] || [modeStr isEqualToString:@"car"]) {
        mode = RadarRouteModeCar;
    } else if ([modeStr isEqualToString:@"TRUCK"] || [modeStr isEqualToString:@"truck"]) {
        mode = RadarRouteModeTruck;
    } else if ([modeStr isEqualToString:@"MOTORBIKE"] || [modeStr isEqualToString:@"motorbike"]) {
        mode = RadarRouteModeMotorbike;
    }
    NSString *unitsStr = argsDict[@"units"];
    RadarRouteUnits units;
    if (unitsStr != nil && [unitsStr isKindOfClass:[NSString class]]) {
        units = [unitsStr isEqualToString:@"METRIC"] || [unitsStr isEqualToString:@"metric"] ? RadarRouteUnitsMetric : RadarRouteUnitsImperial;
    } else {
        units = RadarRouteUnitsImperial;
    }
    
    [Radar getMatrixFromOrigins:origins destinations:destinations mode:mode units:units completionHandler:^(RadarStatus status, RadarRouteMatrix * _Nullable matrix) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
        if (matrix) {
            [dict setObject:[matrix arrayValue] forKey:@"matrix"];
        }
        result(dict);
    }];    
}

- (void)trackVerified:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    BOOL beacons = NO;
    NSNumber *beaconsNumber = argsDict[@"beacons"];
    if (beaconsNumber != nil && [beaconsNumber isKindOfClass:[NSNumber class]]) {
        beacons = [beaconsNumber boolValue];
    }

    RadarTrackVerifiedCompletionHandler completionHandler = ^(RadarStatus status, RadarVerifiedLocationToken* token) {
        if (status == RadarStatusSuccess) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
            [dict setObject:[token dictionaryValue] forKey:@"token"];
            result(dict);
        }
    };

    [Radar trackVerifiedWithBeacons:beacons completionHandler:completionHandler];
}

- (void)validateAddress:(FlutterMethodCall *)call withResult:(FlutterResult)result {
  RadarValidateAddressCompletionHandler completionHandler = ^(RadarStatus status, RadarAddress * _Nullable address, RadarAddressVerificationStatus verificationStatus) {
      NSMutableDictionary *dict = [NSMutableDictionary new];
      [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
      if (address) {
        [dict setObject:[address dictionaryValue] forKey:@"address"];
      }
      [dict setObject:[Radar stringForVerificationStatus:verificationStatus] forKey:@"verificationStatus"];
      result(dict);
  };

  NSDictionary *argsDict = call.arguments;

  NSDictionary *addressDict = argsDict[@"address"];
  RadarAddress *address = [RadarAddress addressFromObject:addressDict];
  [Radar validateAddress:address completionHandler:completionHandler];
}

-(void)attachListeners:(FlutterMethodCall *)call withResult:(FlutterResult)result {    
    NSNumber* callbackDispatcherHandle = call.arguments[@"callbackDispatcherHandle"];

    // Retrieve the callback information
    FlutterCallbackInformation *callbackInfo = [FlutterCallbackCache lookupCallbackInformation:[callbackDispatcherHandle longValue]];

    // Create the background Flutter engine
    FlutterEngine *sBackgroundFlutterEngine;
    sBackgroundFlutterEngine = [[FlutterEngine alloc] init];
    self.sBackgroundFlutterEngine = sBackgroundFlutterEngine;

    FlutterMethodChannel *backgroundChannel = [FlutterMethodChannel methodChannelWithName:@"flutter_radar_background" binaryMessenger:[sBackgroundFlutterEngine binaryMessenger]];
    self.backgroundChannel = backgroundChannel;

    [self.sBackgroundFlutterEngine runWithEntrypoint:callbackInfo.callbackName libraryURI: callbackInfo.callbackLibraryPath] ;    
    result(nil);
}

-(void)detachListeners:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    self.backgroundChannel = nil;
    result(nil);
}

-(void)on:(FlutterMethodCall *)call withResult:(FlutterResult)result {    
    NSDictionary *argsDict = call.arguments;
    NSString* listener = argsDict[@"listener"];
    NSNumber *callbackHandleNumber = argsDict[@"callbackHandle"];
    long callbackHandle = [callbackHandleNumber longValue];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:callbackHandleNumber forKey:listener];
    result(nil);
}

-(void)off:(FlutterMethodCall *)call withResult:(FlutterResult)result { 
    NSDictionary *argsDict = call.arguments;
    NSString* listener = argsDict[@"listener"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:listener];   
    result(nil);
}

- (void)didReceiveEvents:(NSArray<RadarEvent *> *)events user:(RadarUser *)user {
    NSDictionary *dict = @{@"events": [RadarEvent arrayForEvents:events], @"user": user ? [user dictionaryValue] : @""};
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger callbackHandle = [userDefaults integerForKey:@"events"];
    if (callbackHandle == 0) {
        return;
    }
    NSArray* args = @[[NSNumber numberWithInteger:callbackHandle], dict];
    [self.backgroundChannel invokeMethod:@"" arguments:args];
}

- (void)didUpdateLocation:(CLLocation *)location user:(RadarUser *)user {
    NSDictionary *dict = @{@"location": [Radar dictionaryForLocation:location], @"user": [user dictionaryValue]};
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger callbackHandle = [userDefaults integerForKey:@"location"];
    if (callbackHandle == 0) {
        return;
    }
    NSArray* args = @[[NSNumber numberWithInteger:callbackHandle], dict];
    [self.backgroundChannel invokeMethod:@"" arguments:args];
}

- (void)didUpdateClientLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source {
    NSDictionary *dict = @{@"location": [Radar dictionaryForLocation:location], @"stopped": @(stopped), @"source": [Radar stringForLocationSource:source]};
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger callbackHandle = [userDefaults integerForKey:@"clientLocation"];
    if (callbackHandle == 0) {
        return;
    }
    NSArray* args = @[[NSNumber numberWithInteger:callbackHandle], dict];
    [self.backgroundChannel invokeMethod:@"" arguments:args];
}

- (void)didFailWithStatus:(RadarStatus)status {
    NSDictionary *dict = @{@"status": [Radar stringForStatus:status]};
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger callbackHandle = [userDefaults integerForKey:@"error"];
    if (callbackHandle == 0) {
        return;
    }
    NSArray* args = @[[NSNumber numberWithInteger:callbackHandle], dict];
    [self.backgroundChannel invokeMethod:@"" arguments:args];
}

- (void)didLogMessage:(NSString *)message {
    NSDictionary *dict = @{@"message": message};    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber* callbackHandle = [userDefaults objectForKey:@"log"];
    if (callbackHandle == 0) {
        return;
    }
    NSArray* args = @[callbackHandle, dict];
    [self.backgroundChannel invokeMethod:@"" arguments:args];
}

- (void)didUpdateToken:(RadarVerifiedLocationToken *)token {
    NSDictionary *dict = [token dictionaryValue];    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber* callbackHandle = [userDefaults objectForKey:@"token"];
    if (callbackHandle == 0) {
        return;
    }
    NSArray* args = @[callbackHandle, dict];
    [self.backgroundChannel invokeMethod:@"" arguments:args];
}

@end

@implementation RadarStreamHandler

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
  self.sink = eventSink;
  return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
  self.sink = nil;
  return nil;
}

@end
