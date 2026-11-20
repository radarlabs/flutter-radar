import 'package:flutter/services.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_radar');

  TestWidgetsFlutterBinding.ensureInitialized();

  MethodCall? receivedCall;

  setUp(() {
    receivedCall = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      receivedCall = methodCall;
      return '42';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Radar.setExpectedAddress', () {
    test('sends the address to native', () async {
      await Radar.setExpectedAddress('841 Broadway, New York, NY 10003');

      expect(receivedCall?.method, 'setExpectedAddress');
      expect(receivedCall?.arguments, {
        'address': '841 Broadway, New York, NY 10003',
      });
    });

    test('sends null to clear the address', () async {
      await Radar.setExpectedAddress(null);

      expect(receivedCall?.method, 'setExpectedAddress');
      expect(receivedCall?.arguments, {'address': null});
    });
  });

  group('Radar beacon ranging', () {
    test('startRangingBeacons takes no arguments', () async {
      await Radar.startRangingBeacons();

      expect(receivedCall?.method, 'startRangingBeacons');
      expect(receivedCall?.arguments, isNull);
    });

    test('stopRangingBeacons takes no arguments', () async {
      await Radar.stopRangingBeacons();

      expect(receivedCall?.method, 'stopRangingBeacons');
      expect(receivedCall?.arguments, isNull);
    });
  });

  group('Radar.validateStreetAddress', () {
    test('sends every field, with a null unit when omitted', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        receivedCall = methodCall;
        return {'status': 'SUCCESS', 'verificationStatus': 'verified'};
      });

      final result = await Radar.validateStreetAddress(
        street: 'BROADWAY',
        number: '841',
        city: 'NEW YORK',
        stateCode: 'NY',
        postalCode: '10003',
        countryCode: 'US',
      );

      expect(receivedCall?.method, 'validateStreetAddress');
      expect(receivedCall?.arguments, {
        'street': 'BROADWAY',
        'number': '841',
        'unit': null,
        'city': 'NEW YORK',
        'stateCode': 'NY',
        'postalCode': '10003',
        'countryCode': 'US',
      });
      expect(result, {'status': 'SUCCESS', 'verificationStatus': 'verified'});
    });

    test('returns the error code when native fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERROR_BAD_REQUEST');
      });

      final result = await Radar.validateStreetAddress(
        street: '',
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
    test('sends the label and the remaining fields', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        receivedCall = methodCall;
        return {'status': 'SUCCESS', 'verificationStatus': 'verified'};
      });

      await Radar.validateAddressLabel(
        addressLabel: '841 BROADWAY',
        unit: '2',
        city: 'NEW YORK',
        stateCode: 'NY',
        postalCode: '10003',
        countryCode: 'US',
      );

      expect(receivedCall?.method, 'validateAddressLabel');
      expect(receivedCall?.arguments, {
        'addressLabel': '841 BROADWAY',
        'unit': '2',
        'city': 'NEW YORK',
        'stateCode': 'NY',
        'postalCode': '10003',
        'countryCode': 'US',
      });
    });
  });
}
