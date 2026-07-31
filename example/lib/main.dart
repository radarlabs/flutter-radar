import 'package:flutter/material.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_section.dart';
import 'console.dart';

const String publishableKey =
    'prj_test_pk_0000000000000000000000000000000000000000g';

const Map<String, double> _manhattan = {
  'latitude': 40.783826,
  'longitude': -73.975363,
};

const Map<String, double> _brooklyn = {
  'latitude': 40.703900,
  'longitude': -73.986700,
};

void main() => runApp(const MyApp());

// Radar can invoke these from a background isolate, so they must be top-level
// entry points rather than methods on widget state.
@pragma('vm:entry-point')
void _onLocation(Map res) => console.logEvent('onLocation', res);

@pragma('vm:entry-point')
void _onClientLocation(Map res) => console.logEvent('onClientLocation', res);

@pragma('vm:entry-point')
void _onError(Map res) => console.logEvent('onError', res);

@pragma('vm:entry-point')
void _onLog(Map res) => console.logEvent('onLog', res);

@pragma('vm:entry-point')
void _onEvents(Map res) => console.logEvent('onEvents', res);

@pragma('vm:entry-point')
void _onToken(Map res) => console.logEvent('onToken', res);

@pragma('vm:entry-point')
void _onIpChanged() => console.logEvent('onIpChanged', 'IP address changed');

@pragma('vm:entry-point')
void _onSharingChanged(bool sharing) =>
    console.logEvent('onSharingChanged', {'sharing': sharing});

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_radar example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B5BFF),
      ),
      home: const HomePage(),
    );
  }
}

class _ListenerDef {
  final String name;
  final void Function() enable;
  final void Function() disable;

  const _ListenerDef(this.name, this.enable, this.disable);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String _permissionStatus = 'UNKNOWN';
  String? _tripId;
  List<String> _legIds = [];

  final Set<String> _enabledListeners = {};

  late final List<_ListenerDef> _listenerDefs = [
    _ListenerDef('onLocation', () => Radar.onLocation(_onLocation),
        () => Radar.offLocation()),
    _ListenerDef('onClientLocation',
        () => Radar.onClientLocation(_onClientLocation), () => Radar.offClientLocation()),
    _ListenerDef('onError', () => Radar.onError(_onError), () => Radar.offError()),
    _ListenerDef('onLog', () => Radar.onLog(_onLog), () => Radar.offLog()),
    _ListenerDef('onEvents', () => Radar.onEvents(_onEvents), () => Radar.offEvents()),
    _ListenerDef('onToken', () => Radar.onToken(_onToken), () => Radar.offToken()),
    _ListenerDef('onIpChanged', () => Radar.onIpChanged(_onIpChanged),
        () => Radar.offIpChanged()),
    _ListenerDef('onSharingChanged',
        () => Radar.onSharingChanged(_onSharingChanged), () => Radar.offSharingChanged()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initRadar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      Radar.logResigningActive();
    } else if (state == AppLifecycleState.paused) {
      Radar.logBackgrounding();
    }
  }

  Future<void> _initRadar() async {
    await Radar.initialize(
      publishableKey,
      options: RadarInitializeOptions(
        fraud: true,
        trackVerifiedAutoFailover: true,
        networkTimeout: const Duration(seconds: 20),
        ipChangeDebounceInterval: const Duration(seconds: 5),
      ),
    );
    await Radar.setUserId('flutter');
    await Radar.setDescription('Flutter');
    await Radar.setMetadata({'foo': 'bar', 'bax': true, 'qux': 1});
    await Radar.setLogLevel('info');
    await Radar.setAnonymousTrackingEnabled(false);

    for (final def in _listenerDefs) {
      _setListener(def, true);
    }

    await _refreshPermissions();
    console.log('initialize', 'Radar initialized');
  }

  Future<void> _refreshPermissions() async {
    final status = await Radar.getPermissionsStatus();
    if (mounted) {
      setState(() => _permissionStatus = status ?? 'UNKNOWN');
    }
  }

  void _setListener(_ListenerDef def, bool enabled) {
    try {
      if (enabled) {
        def.enable();
      } else {
        def.disable();
      }
      setState(() {
        if (enabled) {
          _enabledListeners.add(def.name);
        } else {
          _enabledListeners.remove(def.name);
        }
      });
    } catch (e) {
      console.logError(def.name, e);
    }
  }

  Future<void> _run(ApiAction action) async {
    try {
      final result = await action.run();
      console.log(action.label, result);
    } catch (e) {
      console.logError(action.label, e);
    }
  }

  /// Leg operations need IDs minted by the server, so the multi-destination
  /// trip response is stashed for the buttons that follow it.
  void _captureTrip(Object? response) {
    if (response is! Map) return;
    final trip = response['trip'];
    if (trip is! Map) return;
    final legs = trip['legs'];
    setState(() {
      _tripId = trip['_id'] as String?;
      _legIds = legs is List
          ? legs
              .whereType<Map>()
              .map((leg) => leg['_id'])
              .whereType<String>()
              .toList()
          : <String>[];
    });
  }

  Future<String?> _prompt(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();

    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_radar'),
        actions: [
          IconButton(
            tooltip: 'Refresh permissions',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPermissions,
          ),
        ],
      ),
      body: Column(
        children: [
          _statusBar(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              children: [
                for (int i = 0; i < sections.length; i++)
                  ApiSectionCard(
                    section: sections[i],
                    onRun: _run,
                    initiallyExpanded: i == 0,
                  ),
                _listenersCard(context),
              ],
            ),
          ),
          const ConsolePanel(),
        ],
      ),
    );
  }

  Widget _statusBar(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <String>[
      'permissions: $_permissionStatus',
      if (_tripId != null) 'trip: ${_tripId!.substring(0, 8)}…',
      if (_legIds.isNotEmpty) 'legs: ${_legIds.length}',
    ];

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final chip in chips)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(chip, style: theme.textTheme.labelSmall),
            ),
        ],
      ),
    );
  }

  Widget _listenersCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: Icon(Icons.podcasts, color: theme.colorScheme.primary),
        title: Text('Listeners', style: theme.textTheme.titleSmall),
        subtitle: Text(
          '${_enabledListeners.length} of ${_listenerDefs.length} active',
          style: theme.textTheme.bodySmall,
        ),
        children: [
          for (final def in _listenerDefs)
            SwitchListTile(
              dense: true,
              title: Text(def.name, style: theme.textTheme.bodyMedium),
              value: _enabledListeners.contains(def.name),
              onChanged: (value) => _setListener(def, value),
            ),
        ],
      ),
    );
  }

  List<ApiSection> _sections() => [
        ApiSection(
          title: 'Setup & Status',
          icon: Icons.tune,
          actions: [
            ApiAction('isInitialized()', () => Radar.isInitialized()),
            ApiAction('sdkVersion()', () => Radar.sdkVersion()),
            ApiAction('getPermissionsStatus()', () => Radar.getPermissionsStatus()),
            ApiAction('requestPermissions(foreground)', () async {
              final status = await Radar.requestPermissions(false);
              await _refreshPermissions();
              return status;
            }),
            ApiAction('requestPermissions(background)', () async {
              final status = await Radar.requestPermissions(true);
              await _refreshPermissions();
              return status;
            }),
            ApiAction('activityRecognition permission', () async {
              final status = await Permission.activityRecognition.request();
              return status.toString();
            }),
            ApiAction("setLogLevel('info')", () async {
              await Radar.setLogLevel('info');
              return 'info';
            }),
            ApiAction("setLogLevel('debug')", () async {
              await Radar.setLogLevel('debug');
              return 'debug';
            }),
          ],
        ),
        ApiSection(
          title: 'User & Metadata',
          icon: Icons.person_outline,
          actions: [
            ApiAction('setUserId()', () async {
              final value = await _prompt('setUserId', initial: 'flutter');
              if (value == null) return 'cancelled';
              await Radar.setUserId(value);
              return value;
            }),
            ApiAction('getUserId()', () => Radar.getUserId()),
            ApiAction('setDescription()', () async {
              final value = await _prompt('setDescription', initial: 'Flutter');
              if (value == null) return 'cancelled';
              await Radar.setDescription(value);
              return value;
            }),
            ApiAction('getDescription()', () => Radar.getDescription()),
            ApiAction('setMetadata()', () async {
              await Radar.setMetadata({'foo': 'bar', 'bax': true, 'qux': 1});
              return {'foo': 'bar', 'bax': true, 'qux': 1};
            }),
            ApiAction('getMetadata()', () => Radar.getMetadata()),
            ApiAction("setUserLanguage('es')", () async {
              await Radar.setUserLanguage('es');
              return 'es';
            }),
            ApiAction('getUserLanguage()', () => Radar.getUserLanguage()),
            ApiAction("setProduct('flutter-qa')", () async {
              await Radar.setProduct('flutter-qa');
              return 'flutter-qa';
            }),
            ApiAction('getProduct()', () => Radar.getProduct()),
            ApiAction('setTags([qa, flutter])', () async {
              await Radar.setTags(['qa', 'flutter']);
              return ['qa', 'flutter'];
            }),
            ApiAction('getTags()', () => Radar.getTags()),
            ApiAction("addTags(['beta'])", () async {
              await Radar.addTags(['beta']);
              return Radar.getTags();
            }),
            ApiAction("removeTags(['beta'])", () async {
              await Radar.removeTags(['beta']);
              return Radar.getTags();
            }),
            ApiAction('setAnonymousTracking(true)', () async {
              await Radar.setAnonymousTrackingEnabled(true);
              return 'enabled';
            }),
            ApiAction('setAnonymousTracking(false)', () async {
              await Radar.setAnonymousTrackingEnabled(false);
              return 'disabled';
            }),
          ],
        ),
        ApiSection(
          title: 'Tracking',
          icon: Icons.my_location,
          actions: [
            ApiAction('trackOnce()', () => Radar.trackOnce()),
            ApiAction('trackOnce(location)',
                () => Radar.trackOnce(location: Map<String, dynamic>.from(_manhattan))),
            ApiAction("getLocation('high')", () => Radar.getLocation('high')),
            ApiAction("startTracking('responsive')", () async {
              await Radar.startTracking('responsive');
              return 'responsive';
            }),
            ApiAction("startTracking('continuous')", () async {
              await Radar.startTracking('continuous');
              return 'continuous';
            }),
            ApiAction("startTracking('efficient')", () async {
              await Radar.startTracking('efficient');
              return 'efficient';
            }),
            ApiAction('startTrackingCustom()', () async {
              await Radar.startTrackingCustom({
                ...Radar.presetResponsive,
                'showBlueBar': true,
                'foregroundServiceEnabled': true,
              });
              return Radar.getTrackingOptions();
            }),
            ApiAction('stopTracking()', () async {
              await Radar.stopTracking();
              return 'stopped';
            }),
            ApiAction('isTracking()', () => Radar.isTracking()),
            ApiAction('getTrackingOptions()', () => Radar.getTrackingOptions()),
            ApiAction('isUsingRemoteTrackingOptions()',
                () => Radar.isUsingRemoteTrackingOptions()),
            ApiAction('mockTracking()', () => Radar.mockTracking(
                  origin: _manhattan,
                  destination: _brooklyn,
                  mode: 'car',
                  steps: 3,
                  interval: 3,
                )),
            ApiAction('setForegroundServiceOptions()', () async {
              await Radar.setForegroundServiceOptions({
                'title': 'Tracking',
                'text': 'Flutter example is tracking',
                'iconString': 'ic_notification',
                'iconColor': '#FF6B8D',
                'importance': 2,
                'updatesOnly': false,
                'activity': 'io.radar.example.MainActivity',
              });
              return 'ok';
            }),
          ],
        ),
        ApiSection(
          title: 'Verified & Fraud',
          icon: Icons.verified_user_outlined,
          actions: [
            ApiAction('trackVerified()', () => Radar.trackVerified()),
            ApiAction('trackVerified(beacons)',
                () => Radar.trackVerified(beacons: true, reason: 'qa')),
            ApiAction('startTrackingVerified()', () async {
              await Radar.startTrackingVerified(30, false);
              return 'started';
            }),
            ApiAction('stopTrackingVerified()', () async {
              await Radar.stopTrackingVerified();
              return 'stopped';
            }),
            ApiAction('isTrackingVerified()', () => Radar.isTrackingVerified()),
            ApiAction('getVerifiedLocationToken()',
                () => Radar.getVerifiedLocationToken()),
            ApiAction('clearVerifiedLocationToken()', () async {
              await Radar.clearVerifiedLocationToken();
              return 'cleared';
            }),
            ApiAction('revealRisk()', () => Radar.revealRisk()),
            ApiAction('isSharing()', () => Radar.isSharing()),
            ApiAction('clearSharing()', () async {
              await Radar.clearSharing();
              return 'cleared';
            }),
            ApiAction('setExpectedJurisdiction(US/NY)', () async {
              await Radar.setExpectedJurisdiction(
                  countryCode: 'US', stateCode: 'NY');
              return 'US / NY';
            }),
            ApiAction('setExpectedJurisdiction(clear)', () async {
              await Radar.setExpectedJurisdiction();
              return 'cleared';
            }),
          ],
        ),
        ApiSection(
          title: 'Trips',
          icon: Icons.route_outlined,
          actions: [
            ApiAction('startTrip (single destination)', () async {
              final response = await Radar.startTrip(tripOptions: {
                'externalId': 'flutter-${DateTime.now().millisecondsSinceEpoch}',
                'destinationGeofenceTag': 'store',
                'destinationGeofenceExternalId': '123',
                'mode': 'car',
                'metadata': {'test': 123},
              });
              _captureTrip(response);
              return response;
            }),
            ApiAction('startTrip (multi-destination)', () async {
              final response = await Radar.startTrip(tripOptions: {
                'externalId': 'flutter-multi-${DateTime.now().millisecondsSinceEpoch}',
                'mode': 'car',
                'legs': [
                  {
                    'destinationGeofenceTag': 'store',
                    'destinationGeofenceExternalId': '123',
                  },
                  {'address': '841 Broadway, New York, NY'},
                  {
                    // GeoJSON order, and both SDKs index it positionally: a
                    // {latitude, longitude} map passes the length check and
                    // then crashes on element access.
                    'coordinates': [
                      _brooklyn['longitude'],
                      _brooklyn['latitude'],
                    ],
                    'arrivalRadius': 100,
                  },
                ],
              });
              _captureTrip(response);
              return response;
            }),
            ApiAction('getTrip()', () async {
              final response = await Radar.getTrip();
              _captureTrip({'trip': response});
              return response;
            }),
            ApiAction('getTripOptions()', () => Radar.getTripOptions()),
            ApiAction("updateTrip('arrived')", () => Radar.updateTrip(
                  status: 'arrived',
                  options: {
                    'externalId': 'flutter-trip',
                    'metadata': {'parkingSpot': '5'},
                  },
                )),
            ApiAction('updateTripLeg (first leg)', () async {
              if (_legIds.isEmpty) {
                return 'No leg IDs captured. Run "startTrip (multi-destination)" first.';
              }
              return Radar.updateTripLeg(
                tripId: _tripId,
                legId: _legIds.first,
                status: 'arrived',
              );
            }),
            ApiAction("updateCurrentTripLeg('arrived')",
                () => Radar.updateCurrentTripLeg(status: 'arrived')),
            ApiAction('reorderTripLegs (reversed)', () async {
              if (_legIds.length < 2) {
                return 'Need at least two legs. Run "startTrip (multi-destination)" first.';
              }
              return Radar.reorderTripLegs(
                tripId: _tripId,
                legIds: _legIds.reversed.toList(),
              );
            }),
            ApiAction('completeTrip()', () => Radar.completeTrip()),
            ApiAction('cancelTrip()', () => Radar.cancelTrip()),
          ],
        ),
        ApiSection(
          title: 'Geofences & Search',
          icon: Icons.search,
          actions: [
            ApiAction('searchGeofences()', () => Radar.searchGeofences(
                  near: Map<String, dynamic>.from(_manhattan),
                  radius: 1000,
                  limit: 10,
                  includeGeometry: true,
                  tags: List.empty(),
                  metadata: {},
                )),
            ApiAction('searchPlaces()', () => Radar.searchPlaces(
                  near: Map<String, dynamic>.from(_manhattan),
                  radius: 1000,
                  chains: ['starbucks'],
                  chainMetadata: {'customFlag': 'true'},
                  limit: 10,
                )),
            ApiAction('autocomplete()', () => Radar.autocomplete(
                  query: 'brooklyn roasting',
                  near: Map<String, dynamic>.from(_manhattan),
                  limit: 10,
                  layers: ['address', 'street'],
                  country: 'US',
                  mailable: false,
                )),
            ApiAction('geocode()', () => Radar.geocode('20 jay st brooklyn')),
            ApiAction('reverseGeocode()', () => Radar.reverseGeocode()),
            ApiAction('ipGeocode()', () => Radar.ipGeocode()),
            ApiAction('getContext()',
                () => Radar.getContext(Map<String, dynamic>.from(_manhattan))),
            ApiAction('getDistance()', () => Radar.getDistance(
                  origin: _manhattan,
                  destination: _brooklyn,
                  modes: ['car', 'foot'],
                  units: 'imperial',
                )),
            ApiAction('getMatrix()', () => Radar.getMatrix(
                  origins: [_manhattan, _brooklyn],
                  destinations: [
                    {'latitude': 40.64189, 'longitude': -73.78779},
                    {'latitude': 35.99801, 'longitude': -78.94294},
                  ],
                  mode: 'car',
                  units: 'imperial',
                )),
            ApiAction('validateAddress()', () => Radar.validateAddress({
                  'city': 'NEW YORK',
                  'stateCode': 'NY',
                  'postalCode': '10003',
                  'countryCode': 'US',
                  'street': 'BROADWAY',
                  'number': '841',
                })),
          ],
        ),
        ApiSection(
          title: 'Events & Conversions',
          icon: Icons.event_note_outlined,
          actions: [
            ApiAction('logConversion()', () => Radar.logConversion(
                  name: 'in_app_purchase',
                  revenue: 0.2,
                  metadata: {'price': '150USD'},
                )),
            ApiAction('acceptEvent()', () async {
              final eventId = await _prompt('acceptEvent — event ID');
              if (eventId == null || eventId.isEmpty) return 'cancelled';
              await Radar.acceptEvent(eventId);
              return 'accepted $eventId';
            }),
            ApiAction('rejectEvent()', () async {
              final eventId = await _prompt('rejectEvent — event ID');
              if (eventId == null || eventId.isEmpty) return 'cancelled';
              await Radar.rejectEvent(eventId);
              return 'rejected $eventId';
            }),
            ApiAction('logBackgrounding()', () async {
              await Radar.logBackgrounding();
              return 'ok';
            }),
            ApiAction('logResigningActive()', () async {
              await Radar.logResigningActive();
              return 'ok';
            }),
            ApiAction('logTermination()', () async {
              await Radar.logTermination();
              return 'ok';
            }),
          ],
        ),
        ApiSection(
          title: 'Notifications & Messaging',
          icon: Icons.notifications_none,
          actions: [
            ApiAction('setNotificationOptions()', () async {
              await Radar.setNotificationOptions({'iconString': 'icon'});
              return 'ok';
            }),
            ApiAction('setPushNotificationToken()', () async {
              final token = await _prompt('setPushNotificationToken');
              if (token == null) return 'cancelled';
              await Radar.setPushNotificationToken(token);
              return token.isEmpty ? 'cleared' : token;
            }),
            ApiAction('showInAppMessage()', () async {
              await Radar.showInAppMessage({
                'type': 'banner',
                'title': {'text': 'This is the title', 'color': '#000000'},
                'body': {'text': 'This is a demo message', 'color': '#666666'},
                'button': {
                  'text': 'Send it',
                  'color': '#FFFFFF',
                  'backgroundColor': '#EB0083',
                },
              });
              return 'shown';
            }),
          ],
        ),
      ];
}
