// Model maps shared by more than one test file.

const addressMap = <Object?, Object?>{
  'latitude': 40.7342,
  'longitude': -73.9911,
  'formattedAddress': '841 Broadway, New York, NY 10003 US',
  'country': 'United States',
  'countryCode': 'US',
  'countryFlag': '🇺🇸',
  'dma': 'New York',
  'dmaCode': '501',
  'state': 'New York',
  'stateCode': 'NY',
  'postalCode': '10003',
  'city': 'New York',
  'borough': 'Manhattan',
  'county': 'New York County',
  'neighborhood': 'Greenwich Village',
  'street': 'Broadway',
  'number': '841',
  'addressLabel': '841 Broadway',
  'placeLabel': 'Radar',
  'unit': 'Fl 2',
  'plus4': '4703',
  'distance': 12,
  'layer': 'address',
  'metadata': {'foo': 'bar'},
  'confidence': 'exact',
  'timeZone': {
    'id': 'America/New_York',
    'name': 'Eastern Standard Time',
    'code': 'EST',
    'currentTime': '2026-11-19T10:00:00-05:00',
    'utcOffset': -18000,
    'dstOffset': 0,
  },
  'categories': ['office'],
  'resultId': 'res_1',
};

const circleGeofenceMap = <Object?, Object?>{
  '_id': 'g1',
  'description': 'Store',
  'tag': 'store',
  'externalId': '123',
  'metadata': {'a': 1},
  'operatingHours': {
    'monday': [
      ['08:00', '17:00'],
    ],
  },
  'geometryCenter': {
    'type': 'Point',
    'coordinates': [-73.99, 40.73],
  },
  'geometryRadius': 100,
  'type': 'Circle',
  'dwellThreshold': 5,
  'stopDetection': true,
};

const fraud = <Object?, Object?>{
  'passed': true,
  'bypassed': false,
  'verified': true,
  'proxy': false,
  'mocked': false,
  'compromised': false,
  'jumped': false,
  'inaccurate': false,
  'sharing': false,
  'blocked': false,
};

// The trip as iOS's [RadarTrip dictionaryValue] serializes it: `eta` always
// present, mode always present.
const iosTrip = <Object?, Object?>{
  '_id': 'trip-2',
  'externalId': 'order-2',
  'mode': 'foot',
  'eta': {'distance': 0, 'duration': 0},
  'status': 'arrived',
  'legs': [
    {
      '_id': 'leg-3',
      'status': 'arrived',
      'destination': {'address': '841 Broadway, New York, NY'},
    },
  ],
};

// A user as iOS's [RadarUser dictionaryValue] serializes it.
const iosUser = <Object?, Object?>{
  '_id': 'user-2',
  'deviceId': 'device-2',
  'location': {
    'type': 'Point',
    'coordinates': [-122.4194, 37.7749],
  },
  'activityType': 'stationary',
  'geofences': <Object?>[],
  'stopped': false,
  'foreground': true,
  'nearbyPlaceChains': <Object?>[],
  'segments': <Object?>[],
  'topChains': <Object?>[],
  'source': 'VISIT_ARRIVAL',
  'debug': true,
  'fraud': fraud,
  'locationInsights': {
    'atHome': true,
    'atWork': false,
    'traveling': false,
    'commuting': false,
  },
};
