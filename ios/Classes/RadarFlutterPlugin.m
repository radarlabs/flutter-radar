#import "RadarFlutterPlugin.h"

#import <RadarSDK/RadarSDK.h>

@interface RadarFlutterPlugin() <RadarDelegate>

@property (strong, nonatomic) FlutterMethodChannel *channel;
@property (strong, nonatomic) RadarStreamHandler *eventsHandler;
@property (strong, nonatomic) RadarStreamHandler *locationHandler;
@property (strong, nonatomic) RadarStreamHandler *clientLocationHandler;
@property (strong, nonatomic) RadarStreamHandler *errorHandler;
@property (strong, nonatomic) RadarStreamHandler *logHandler;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) FlutterResult permissionsRequestResult;

@end

@implementation RadarFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    RadarFlutterPlugin *instance = [[RadarFlutterPlugin alloc] init];

    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"flutter_radar" binaryMessenger:[registrar messenger]];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel *eventsChannel = [FlutterEventChannel eventChannelWithName:@"flutter_radar/events" binaryMessenger:[registrar messenger]];
    instance.eventsHandler = [RadarStreamHandler new];
    [eventsChannel setStreamHandler:instance.eventsHandler];
    
    FlutterEventChannel *locationChannel = [FlutterEventChannel eventChannelWithName:@"flutter_radar/location" binaryMessenger:[registrar messenger]];
    instance.locationHandler = [RadarStreamHandler new];
    [locationChannel setStreamHandler:instance.locationHandler];

    FlutterEventChannel *clientLocationChannel = [FlutterEventChannel eventChannelWithName:@"flutter_radar/clientLocation" binaryMessenger:[registrar messenger]];
    instance.clientLocationHandler = [RadarStreamHandler new];
    [clientLocationChannel setStreamHandler:instance.clientLocationHandler];

    FlutterEventChannel *errorChannel = [FlutterEventChannel eventChannelWithName:@"flutter_radar/error" binaryMessenger:[registrar messenger]];
    instance.errorHandler = [RadarStreamHandler new];
    [errorChannel setStreamHandler:instance.errorHandler];
    
    FlutterEventChannel *logChannel = [FlutterEventChannel eventChannelWithName:@"flutter_radar/log" binaryMessenger:[registrar messenger]];
    instance.logHandler = [RadarStreamHandler new];
    [logChannel setStreamHandler:instance.logHandler];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    [Radar setDelegate:self];
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
    } else if ([@"setAdIdEnabled" isEqualToString:call.method]) {
        [self setAdIdEnabled:call withResult:result];
    } else if ([@"getLocation" isEqualToString:call.method]) {
        [self getLocation:call withResult:result];
    } else if ([@"trackOnce" isEqualToString:call.method]) {
        [self trackOnce:call withResult:result];
    } else if ([@"startTracking" isEqualToString:call.method]) {
        [self startTracking:call withResult:result];
    } else if ([@"startTrackingCustom" isEqualToString:call.method]) {
        [self startTrackingCustom:call withResult:result];
    } else if ([@"stopTracking" isEqualToString:call.method]) {
        [self stopTracking:call withResult:result];
    } else if ([@"isTracking" isEqualToString:call.method]) {
        [self isTracking:call withResult:result];
    } else if ([@"mockTracking" isEqualToString:call.method]) {
        [self mockTracking:call withResult:result];
    } else if ([@"startTrip" isEqualToString:call.method]) {
       [self startTrip:call withResult:result];
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
    } else if ([@"startForegroundService" isEqualToString:call.method]) {
        // do nothing
    } else if ([@"stopForegroundService" isEqualToString:call.method]) {
        // do nothing
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)initialize:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSString *publishableKey = argsDict[@"publishableKey"];
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

    BOOL background = argsDict[@"background"];
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

- (void)setAdIdEnabled:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    BOOL enabled = argsDict[@"enabled"];
    [Radar setAdIdEnabled:enabled];
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
    if (locationDict) {
        NSDictionary *locationDict = call.arguments[@"location"];
        NSNumber *latitudeNumber = locationDict[@"latitude"];
        NSNumber *longitudeNumber = locationDict[@"longitude"];
        NSNumber *accuracyNumber = locationDict[@"accuracy"];
        double latitude = [latitudeNumber doubleValue];
        double longitude = [longitudeNumber doubleValue];
        double accuracy = accuracyNumber ? [accuracyNumber doubleValue] : -1;
        CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:accuracy verticalAccuracy:-1 timestamp:[NSDate date]];
        [Radar trackOnceWithLocation:location completionHandler:completionHandler];
    } else {
        [Radar trackOnceWithCompletionHandler:completionHandler];
    }
}

- (void)startTracking:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *argsDict = call.arguments;

    NSString *preset = argsDict[@"preset"];
    if (!preset) {
        [Radar startTrackingWithOptions:RadarTrackingOptions.responsive];
    } else if ([preset isEqualToString:@"continuous"]) {
        [Radar startTrackingWithOptions:RadarTrackingOptions.continuous];
    } else if ([preset isEqualToString:@"responsive"]) {
        [Radar startTrackingWithOptions:RadarTrackingOptions.responsive];
    } else if ([preset isEqualToString:@"efficient"]) {
        [Radar startTrackingWithOptions:RadarTrackingOptions.efficient];
    } else {
        [Radar startTrackingWithOptions:RadarTrackingOptions.responsive];
    }
    result(nil);
}

- (void)startTrackingCustom:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    NSDictionary *optionsDict = call.arguments;
    RadarTrackingOptions *options = [RadarTrackingOptions trackingOptionsFromDictionary:optionsDict];
    [Radar startTrackingWithOptions:options];
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
    NSDictionary *argsDict = call.arguments;

    NSString *externalId = argsDict[@"externalId"];
    RadarTripOptions *options = [[RadarTripOptions alloc] initWithExternalId:externalId];
    options.destinationGeofenceTag = argsDict[@"destinationGeofenceTag"];
    options.destinationGeofenceExternalId = argsDict[@"destinationGeofenceExternalId"];
    NSString *modeStr = argsDict[@"mode"];
    if ([modeStr isEqualToString:@"foot"]) {
        options.mode = RadarRouteModeFoot;
    } else if ([modeStr isEqualToString:@"bike"]) {
        options.mode = RadarRouteModeBike;
    } else {
        options.mode = RadarRouteModeCar;
    }
    NSDictionary *metadata = argsDict[@"metadata"];
    if (metadata) {
        options.metadata = metadata;
    }
    [Radar startTripWithOptions:options];
    result(nil);
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
    [Radar completeTrip];
    result(nil);
}

- (void)cancelTrip:(FlutterMethodCall *)call withResult:(FlutterResult)result {
    [Radar cancelTrip];
    result(nil);
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

    if (near != nil) {
        [Radar searchGeofencesNear:near radius:radius tags:tags metadata:metadata limit:limit completionHandler:completionHandler];
    } else {
        [Radar searchGeofencesWithRadius:radius tags:tags metadata:metadata limit:limit completionHandler:completionHandler];
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
    NSArray *categories = argsDict[@"categories"];
    NSArray *groups = argsDict[@"groups"];
    NSNumber *limitNumber = argsDict[@"limit"];
    int limit;
    if (limitNumber != nil && [limitNumber isKindOfClass:[NSNumber class]]) {
        limit = [limitNumber intValue];
    } else {
        limit = 10;
    }

    if (near != nil) {
        [Radar searchPlacesNear:near radius:radius chains:chains categories:categories groups:groups limit:limit completionHandler:completionHandler];
    } else {
        [Radar searchPlacesWithRadius:radius chains:chains categories:categories groups:groups limit:limit completionHandler:completionHandler];
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

    [Radar autocompleteQuery:query near:near limit:limit completionHandler:^(RadarStatus status, NSArray<RadarAddress *> * _Nullable addresses) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setObject:[Radar stringForStatus:status] forKey:@"status"];
        if (addresses) {
            [dict setObject:[RadarAddress arrayForAddresses:addresses] forKey:@"addresses"];
        }
        result(dict);
    }];
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

  NSDictionary *locationDict = argsDict[@"location"];
  if (locationDict) {
      NSNumber *latitudeNumber = locationDict[@"latitude"];
      NSNumber *longitudeNumber = locationDict[@"longitude"];
      double latitude = [latitudeNumber doubleValue];
      double longitude = [longitudeNumber doubleValue];
      CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude) altitude:-1 horizontalAccuracy:5 verticalAccuracy:-1 timestamp:[NSDate date]];

      [Radar reverseGeocodeLocation:location completionHandler:completionHandler];
  } else {
      [Radar reverseGeocodeWithCompletionHandler:completionHandler];
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

- (void)didReceiveEvents:(NSArray<RadarEvent *> *)events user:(RadarUser *)user {
    NSDictionary *dict = @{@"events": [RadarEvent arrayForEvents:events], @"user": [user dictionaryValue]};
    if (self.eventsHandler && self.eventsHandler.sink) {
        self.eventsHandler.sink(dict);
    }
}

- (void)didUpdateLocation:(CLLocation *)location user:(RadarUser *)user {
    NSDictionary *dict = @{@"location": [Radar dictionaryForLocation:location], @"user": [user dictionaryValue]};
    if (self.locationHandler && self.locationHandler.sink) {
        self.locationHandler.sink(dict);
    }
}

- (void)didUpdateClientLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source {
    NSDictionary *dict = @{@"location": [Radar dictionaryForLocation:location], @"stopped": @(stopped), @"source": [Radar stringForSource:source]};
    if (self.clientLocationHandler && self.clientLocationHandler.sink) {
        self.clientLocationHandler.sink(dict);
    }
}

- (void)didFailWithStatus:(RadarStatus)status {
    NSDictionary *dict = @{@"status": [Radar stringForStatus:status]};
    if (self.errorHandler && self.errorHandler.sink) {
        self.errorHandler.sink(dict);
    }
}

- (void)didLogMessage:(NSString *)message {
    NSDictionary *dict = @{@"message": message};
    if (self.logHandler && self.logHandler.sink) {
        self.logHandler.sink(dict);
    }
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
