import 'package:flutter/services.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_radar');
  final List<MethodCall> calls = [];
  Object? response;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    calls.clear();
    response = '42';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      calls.add(methodCall);
      return response;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('setExpectedAddress sends the address', () async {
    await Radar.setExpectedAddress('841 Broadway, New York, NY');

    expect(calls.single.method, 'setExpectedAddress');
    expect(calls.single.arguments, {'address': '841 Broadway, New York, NY'});
  });

  test('setExpectedAddress sends null to clear', () async {
    await Radar.setExpectedAddress(null);

    expect(calls.single.method, 'setExpectedAddress');
    expect(calls.single.arguments, {'address': null});
  });

  test('startRangingBeacons and stopRangingBeacons invoke the channel',
      () async {
    await Radar.startRangingBeacons();
    await Radar.stopRangingBeacons();

    expect(calls.map((c) => c.method),
        ['startRangingBeacons', 'stopRangingBeacons']);
  });

  test('validateAddressWithStreet sends every field', () async {
    response = {'status': 'SUCCESS', 'verificationStatus': 'VERIFIED'};

    final result = await Radar.validateAddressWithStreet(
      street: 'Broadway',
      number: '841',
      unit: '4',
      city: 'New York',
      stateCode: 'NY',
      postalCode: '10003',
      countryCode: 'US',
    );

    expect(calls.single.method, 'validateAddressWithStreet');
    expect(calls.single.arguments, {
      'street': 'Broadway',
      'number': '841',
      'unit': '4',
      'city': 'New York',
      'stateCode': 'NY',
      'postalCode': '10003',
      'countryCode': 'US',
    });
    expect(result, {'status': 'SUCCESS', 'verificationStatus': 'VERIFIED'});
  });

  test('validateAddressWithAddressLabel sends every field', () async {
    response = {'status': 'SUCCESS', 'verificationStatus': 'VERIFIED'};

    await Radar.validateAddressWithAddressLabel(
      addressLabel: '841 Broadway',
      city: 'New York',
      stateCode: 'NY',
      postalCode: '10003',
      countryCode: 'US',
    );

    expect(calls.single.method, 'validateAddressWithAddressLabel');
    expect(calls.single.arguments, {
      'addressLabel': '841 Broadway',
      'unit': null,
      'city': 'New York',
      'stateCode': 'NY',
      'postalCode': '10003',
      'countryCode': 'US',
    });
  });

  test('validateAddressWithStreet returns the error code on failure',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      throw PlatformException(code: 'ERROR_BAD_REQUEST');
    });

    final result = await Radar.validateAddressWithStreet(
      street: '',
      number: '',
      city: '',
      stateCode: '',
      postalCode: '',
      countryCode: '',
    );

    expect(result, {'error': 'ERROR_BAD_REQUEST'});
  });

  group('RadarAutocompleteSession', () {
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('mints a distinct v4 UUID per session', () {
      final first = RadarAutocompleteSession();
      final second = RadarAutocompleteSession();

      expect(first.sessionToken, matches(uuidPattern));
      expect(second.sessionToken, matches(uuidPattern));
      expect(first.sessionToken, isNot(second.sessionToken));
    });

    test('withSessionToken keeps the given token', () {
      const token = '6f1c2a3b-4d5e-4f60-8a7b-9c0d1e2f3a4b';

      expect(
        RadarAutocompleteSession.withSessionToken(token).sessionToken,
        token,
      );
    });

    test('autocomplete sends the session token and query', () async {
      response = {
        'status': 'SUCCESS',
        'addresses': [
          {'formattedAddress': '20 Jay St', 'resultId': 'r1'},
        ],
      };
      final session = RadarAutocompleteSession();

      final result = await session.autocomplete(
        query: 'brooklyn roasting',
        near: {'latitude': 40.7, 'longitude': -73.9},
        limit: 5,
        country: 'US',
        layers: ['address'],
        mailable: true,
      );

      expect(calls.single.method, 'autocompleteSession');
      expect(calls.single.arguments, {
        'sessionToken': session.sessionToken,
        'query': 'brooklyn roasting',
        'near': {'latitude': 40.7, 'longitude': -73.9},
        'limit': 5,
        'country': 'US',
        'layers': ['address'],
        'mailable': true,
      });
      expect((result!['addresses'] as List).single['resultId'], 'r1');
    });

    test('select sends the session token and address', () async {
      response = {
        'status': 'SUCCESS',
        'address': {
          'formattedAddress': '20 Jay St, Brooklyn, NY 11201 US',
          'locationDetails': {
            'usage': 'commercial',
            'dwelling': 'n/a',
            'grounds': [],
            'places': [],
          },
        },
      };
      final session = RadarAutocompleteSession();
      final address = {'formattedAddress': '20 Jay St', 'resultId': 'r1'};

      final result = await session.select(address);

      expect(calls.single.method, 'selectAutocompleteAddress');
      expect(calls.single.arguments, {
        'sessionToken': session.sessionToken,
        'address': address,
      });
      expect(result!['address']['locationDetails']['usage'], 'commercial');
    });

    test('select returns the error code on failure', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERROR_BAD_REQUEST');
      });

      final result = await RadarAutocompleteSession.withSessionToken('nope')
          .select({'formattedAddress': '20 Jay St'});

      expect(result, {'error': 'ERROR_BAD_REQUEST'});
    });
  });
}
