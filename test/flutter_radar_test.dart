import 'package:flutter/services.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_radar');

  TestWidgetsFlutterBinding.ensureInitialized();

  MethodCall? receivedCall;
  Object? response;

  setUp(() {
    receivedCall = null;
    response = '42';

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      receivedCall = methodCall;
      return response;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Radar.setExpectedAddress', () {
    test('sends the address', () async {
      await Radar.setExpectedAddress('20 Jay St, Brooklyn, NY 11201, USA');

      expect(receivedCall?.method, 'setExpectedAddress');
      expect(receivedCall?.arguments, {
        'address': '20 Jay St, Brooklyn, NY 11201, USA',
      });
    });

    test('sends null to clear the address', () async {
      await Radar.setExpectedAddress(null);

      expect(receivedCall?.method, 'setExpectedAddress');
      expect(receivedCall?.arguments, {'address': null});
    });
  });

  group('Radar.startRangingBeacons', () {
    test('invokes startRangingBeacons', () async {
      await Radar.startRangingBeacons();

      expect(receivedCall?.method, 'startRangingBeacons');
      expect(receivedCall?.arguments, isNull);
    });

    test('invokes stopRangingBeacons', () async {
      await Radar.stopRangingBeacons();

      expect(receivedCall?.method, 'stopRangingBeacons');
      expect(receivedCall?.arguments, isNull);
    });
  });

  group('Radar.validateStreetAddress', () {
    test('sends every field', () async {
      response = {'status': 'SUCCESS', 'verificationStatus': 'verified'};

      final result = await Radar.validateStreetAddress(
        street: 'BROADWAY',
        number: '841',
        unit: '5',
        city: 'NEW YORK',
        stateCode: 'NY',
        postalCode: '10003',
        countryCode: 'US',
      );

      expect(receivedCall?.method, 'validateStreetAddress');
      expect(receivedCall?.arguments, {
        'street': 'BROADWAY',
        'number': '841',
        'unit': '5',
        'city': 'NEW YORK',
        'stateCode': 'NY',
        'postalCode': '10003',
        'countryCode': 'US',
      });
      expect(result, {'status': 'SUCCESS', 'verificationStatus': 'verified'});
    });

    test('returns the error code when the platform throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERROR_BAD_REQUEST');
      });

      final result = await Radar.validateStreetAddress(
        street: 'BROADWAY',
        number: '841',
        city: 'NEW YORK',
        stateCode: 'NY',
        postalCode: '10003',
        countryCode: 'US',
      );

      expect(result, {'error': 'ERROR_BAD_REQUEST'});
    });
  });

  group('Radar.validateAddressLabel', () {
    test('sends the label and omits the unit when unset', () async {
      response = {'status': 'SUCCESS', 'verificationStatus': 'verified'};

      await Radar.validateAddressLabel(
        addressLabel: '841 BROADWAY',
        city: 'NEW YORK',
        stateCode: 'NY',
        postalCode: '10003',
        countryCode: 'US',
      );

      expect(receivedCall?.method, 'validateAddressLabel');
      expect(receivedCall?.arguments, {
        'addressLabel': '841 BROADWAY',
        'unit': null,
        'city': 'NEW YORK',
        'stateCode': 'NY',
        'postalCode': '10003',
        'countryCode': 'US',
      });
    });
  });

  group('autocomplete sessions', () {
    test('createAutocompleteSession returns the session token', () async {
      response = 'c2b6a0c8-24f5-4b41-9f44-28a0a4a9e3d2';

      final sessionToken = await Radar.createAutocompleteSession();

      expect(receivedCall?.method, 'createAutocompleteSession');
      expect(sessionToken, 'c2b6a0c8-24f5-4b41-9f44-28a0a4a9e3d2');
    });

    test('autocomplete sends the session token', () async {
      response = {'status': 'SUCCESS', 'addresses': []};

      await Radar.autocomplete(
        query: 'brooklyn roasting',
        near: {'latitude': 40.783826, 'longitude': -73.975363},
        limit: 10,
        country: 'US',
        sessionToken: 'c2b6a0c8-24f5-4b41-9f44-28a0a4a9e3d2',
      );

      expect(receivedCall?.method, 'autocomplete');
      expect(receivedCall?.arguments, {
        'query': 'brooklyn roasting',
        'near': {'latitude': 40.783826, 'longitude': -73.975363},
        'limit': 10,
        'country': 'US',
        'layers': null,
        'mailable': null,
        'sessionToken': 'c2b6a0c8-24f5-4b41-9f44-28a0a4a9e3d2',
      });
    });

    test('autocomplete sends a null session token when omitted', () async {
      response = {'status': 'SUCCESS', 'addresses': []};

      await Radar.autocomplete(query: 'brooklyn roasting');

      expect((receivedCall?.arguments as Map)['sessionToken'], isNull);
    });

    test('selectAutocompleteAddress sends the session token and address',
        () async {
      response = {
        'status': 'SUCCESS',
        'address': {
          'formattedAddress': '20 Jay St, Brooklyn, NY 11201 USA',
          'locationDetails': {'usage': 'commercial'},
        },
      };

      final result = await Radar.selectAutocompleteAddress(
        sessionToken: 'c2b6a0c8-24f5-4b41-9f44-28a0a4a9e3d2',
        address: {'formattedAddress': '20 Jay St', 'resultId': 'result-1'},
      );

      expect(receivedCall?.method, 'selectAutocompleteAddress');
      expect(receivedCall?.arguments, {
        'sessionToken': 'c2b6a0c8-24f5-4b41-9f44-28a0a4a9e3d2',
        'address': {'formattedAddress': '20 Jay St', 'resultId': 'result-1'},
      });
      expect(result?['address']?['locationDetails'], {'usage': 'commercial'});
    });
  });
}
