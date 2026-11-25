import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_section.dart';
import 'console.dart';
import 'describe.dart';
import 'environment.dart';
import 'settings_page.dart';

const _manhattan = RadarLocation(latitude: 40.783826, longitude: -73.975363);

const _brooklyn = RadarLocation(latitude: 40.703900, longitude: -73.986700);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The hosts must be written before Radar.initialize.
  final settings = await EnvironmentSettings.load();
  await settings.applyHosts();
  runApp(MyApp(settings: settings));
}

void _onLocation(RadarLocationUpdate update) =>
    console.logEvent('onLocation', describe(update));

void _onClientLocation(RadarClientLocationUpdate update) =>
    console.logEvent('onClientLocation', describe(update));

void _onError(RadarErrorUpdate update) =>
    console.logEvent('onError', describe(update));

void _onLog(RadarLogUpdate update) => console.logEvent('onLog', update.message);

void _onEvents(RadarEventsUpdate update) =>
    console.logEvent('onEvents', describe(update));

void _onToken(RadarTokenUpdate update) =>
    console.logEvent('onToken', describe(update));

void _onIpChanged(RadarIpChangedUpdate update) =>
    console.logEvent('onIpChanged', describe(update));

void _onSharingChanged(RadarSharingChangedUpdate update) =>
    console.logEvent('onSharingChanged', describe(update));

@pragma('vm:entry-point')
Future<void> _onBackgroundUpdate(RadarUpdate update) async {
  switch (update) {
    case RadarEventsUpdate(:final events):
      debugPrint('radar background: ${events.length} events');
    case RadarClientLocationUpdate(:final location, :final source):
      debugPrint('radar background: $location from ${source.name}');
    default:
      debugPrint('radar background: ${describe(update)}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settings});

  final EnvironmentSettings settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_radar example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B5BFF),
      ),
      home: HomePage(settings: settings),
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
  const HomePage({super.key, required this.settings});

  final EnvironmentSettings settings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String _permissionStatus = 'UNKNOWN';
  KeyCheck _keyCheck = const KeyCheck.notChecked();
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
    _checkKey();
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

  Future<void> _checkKey() async {
    final settings = widget.settings;
    if (!settings.hasKey) return;
    final result = await KeyCheck.check(settings.resolvedPublishableKey);
    if (!mounted) return;
    setState(() => _keyCheck = result);
    if (result.mismatches(settings.environment)) {
      console.logError(
        'environment',
        'The key is ${result.summary}, but the app is running '
            '${settings.environment.label}.',
      );
    }
  }

  Future<void> _initRadar() async {
    final settings = widget.settings;
    final env = settings.environment;
    final host = settings.host(env);
    console.log(
      'environment',
      '${env.label} · ${host.isEmpty ? 'no Local URL' : host} · '
          '${keyPrefix(settings.resolvedPublishableKey)}',
    );
    await Radar.initialize(
      settings.resolvedPublishableKey,
      options: RadarInitializeOptions(
        fraud: true,
        trackVerifiedAutoFailover: true,
        networkTimeout: const Duration(seconds: 20),
        ipChangeDebounceInterval: const Duration(seconds: 5),
      ),
    );
    await Radar.registerBackgroundHandler(_onBackgroundUpdate);
    await Radar.setUserId('flutter');
    await Radar.setDescription('Flutter');
    await Radar.setMetadata({'foo': 'bar', 'bax': true, 'qux': 1});
    await Radar.setLogLevel(RadarLogLevel.info);
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
      setState(() => _permissionStatus = status.name);
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
      console.log(action.label, describe(result));
    } catch (e) {
      console.logError(action.label, e);
    }
  }

  /// Leg operations need IDs minted by the server, so the multi-destination
  /// trip response is stashed for the buttons that follow it.
  void _captureTrip(RadarTrip? trip) {
    if (trip == null) return;
    setState(() {
      _tripId = trip.id;
      _legIds = trip.legs.map((leg) => leg.id).whereType<String>().toList();
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
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => SettingsPage.open(
              context,
              settings: widget.settings,
              keyCheck: _keyCheck,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          EnvironmentBadge(settings: widget.settings, keyCheck: _keyCheck),
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
      'env: ${widget.settings.environment.label}',
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
            ApiAction('setLogLevel(info)', () async {
              await Radar.setLogLevel(RadarLogLevel.info);
              return 'info';
            }),
            ApiAction('setLogLevel(debug)', () async {
              await Radar.setLogLevel(RadarLogLevel.debug);
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
                () => Radar.trackOnce(location: _manhattan)),
            ApiAction('trackOnce() -> user.locationInsights', () async {
              if (!Platform.isIOS) {
                return 'iOS only: the Radar Android SDK has no locationInsights.';
              }
              return (await Radar.trackOnce()).user?.locationInsights;
            }),
            ApiAction('getLocation(high)', () => Radar.getLocation(
                desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high)),
            for (final (name, options) in [
              ('responsive', RadarTrackingOptions.responsive),
              ('continuous', RadarTrackingOptions.continuous),
              ('efficient', RadarTrackingOptions.efficient),
            ])
              ApiAction('startTracking($name)', () async {
                await Radar.startTracking(options);
                return name;
              }),
            ApiAction('startTracking(custom)', () async {
              await Radar.startTracking(
                RadarTrackingOptions.responsive.copyWith(
                  showBlueBar: true,
                  foregroundServiceEnabled: true,
                ),
              );
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
                  mode: RadarRouteMode.car,
                  steps: 3,
                  interval: const Duration(seconds: 3),
                )),
            ApiAction('setForegroundServiceOptions()', () async {
              await Radar.setForegroundServiceOptions(
                const RadarForegroundServiceOptions(
                  title: 'Tracking',
                  text: 'Flutter example is tracking',
                  iconString: 'ic_notification',
                  iconColor: Color(0xFFFF6B8D),
                  importance: 2,
                  activity: 'io.radar.example.MainActivity',
                ),
              );
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
            ApiAction('trackVerified() -> token.format',
                () async => (await Radar.trackVerified()).format),
            ApiAction('startRangingBeacons()', () async {
              await Radar.startRangingBeacons();
              return 'ranging';
            }),
            ApiAction('stopRangingBeacons()', () async {
              await Radar.stopRangingBeacons();
              return 'stopped';
            }),
            ApiAction('startTrackingVerified()', () async {
              await Radar.startTrackingVerified(
                  const Duration(seconds: 30), false);
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
            ApiAction('revealRisk() -> revealRisk.format',
                () async => (await Radar.revealRisk()).format),
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
            ApiAction('setExpectedAddress(841 Broadway)', () async {
              await Radar.setExpectedAddress(
                  '841 Broadway, New York, NY 10003');
              return '841 Broadway, New York, NY 10003';
            }),
            ApiAction('setExpectedAddress(clear)', () async {
              await Radar.setExpectedAddress(null);
              return 'cleared';
            }),
            ApiAction('trackOnce() -> user.expectedAddress',
                () async => (await Radar.trackOnce()).user?.expectedAddress),
          ],
        ),
        ApiSection(
          title: 'Trips',
          icon: Icons.route_outlined,
          actions: [
            ApiAction('startTrip (single destination)', () async {
              final response = await Radar.startTrip(
                tripOptions: RadarTripOptions(
                  externalId:
                      'flutter-${DateTime.now().millisecondsSinceEpoch}',
                  destinationGeofenceTag: 'store',
                  destinationGeofenceExternalId: '123',
                  mode: RadarRouteMode.car,
                  metadata: {'test': 123},
                ),
              );
              _captureTrip(response.trip);
              return response;
            }),
            ApiAction('startTrip (multi-destination)', () async {
              final response = await Radar.startTrip(
                tripOptions: RadarTripOptions(
                  externalId:
                      'flutter-multi-${DateTime.now().millisecondsSinceEpoch}',
                  mode: RadarRouteMode.car,
                  legs: [
                    const RadarTripLeg.geofence(
                      tag: 'store',
                      externalId: '123',
                    ),
                    const RadarTripLeg.address('841 Broadway, New York, NY'),
                    RadarTripLeg.coordinates(
                      _brooklyn.coordinate,
                      arrivalRadius: 100,
                    ),
                  ],
                ),
              );
              _captureTrip(response.trip);
              return response;
            }),
            ApiAction('getTrip()', () async {
              final trip = await Radar.getTrip();
              _captureTrip(trip);
              return trip;
            }),
            ApiAction('getTripOptions()', () => Radar.getTripOptions()),
            ApiAction('updateTrip(arrived)', () => Radar.updateTrip(
                  status: RadarTripStatus.arrived,
                  options: const RadarTripOptions(
                    externalId: 'flutter-trip',
                    metadata: {'parkingSpot': '5'},
                  ),
                )),
            ApiAction('updateTripLeg (first leg)', () async {
              if (_legIds.isEmpty) {
                return 'No leg IDs captured. Run "startTrip (multi-destination)" first.';
              }
              return Radar.updateTripLeg(
                tripId: _tripId,
                legId: _legIds.first,
                status: RadarTripLegStatus.arrived,
              );
            }),
            ApiAction('updateCurrentTripLeg(arrived)', () =>
                Radar.updateCurrentTripLeg(status: RadarTripLegStatus.arrived)),
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
                  near: _manhattan,
                  radius: 1000,
                  limit: 10,
                  includeGeometry: true,
                )),
            ApiAction('searchPlaces()', () => Radar.searchPlaces(
                  near: _manhattan,
                  radius: 1000,
                  chains: ['starbucks'],
                  chainMetadata: {'customFlag': 'true'},
                  limit: 10,
                )),
            ApiAction('autocomplete()', () => Radar.autocomplete(
                  query: 'brooklyn roasting',
                  near: _manhattan,
                  limit: 10,
                  layers: ['address', 'street'],
                  country: 'US',
                  mailable: false,
                )),
            ApiAction('geocode()', () => Radar.geocode('20 jay st brooklyn')),
            ApiAction('reverseGeocode()', () => Radar.reverseGeocode()),
            ApiAction('ipGeocode()', () => Radar.ipGeocode()),
            ApiAction('getContext()',
                () => Radar.getContext(_manhattan)),
            ApiAction('getDistance()', () => Radar.getDistance(
                  origin: _manhattan,
                  destination: _brooklyn,
                  modes: {RadarRouteMode.car, RadarRouteMode.foot},
                  units: RadarRouteUnits.imperial,
                )),
            ApiAction('getMatrix()', () => Radar.getMatrix(
                  origins: [_manhattan, _brooklyn],
                  destinations: const [
                    RadarLocation(latitude: 40.64189, longitude: -73.78779),
                    RadarLocation(latitude: 35.99801, longitude: -78.94294),
                  ],
                  mode: RadarRouteMode.car,
                  units: RadarRouteUnits.imperial,
                )),
            ApiAction('validateStreetAddress()',
                () => Radar.validateStreetAddress(
                      street: 'BROADWAY',
                      number: '841',
                      city: 'NEW YORK',
                      stateCode: 'NY',
                      postalCode: '10003',
                      countryCode: 'US',
                    )),
            ApiAction('validateAddressLabel()',
                () => Radar.validateAddressLabel(
                      addressLabel: '841 BROADWAY',
                      city: 'NEW YORK',
                      stateCode: 'NY',
                      postalCode: '10003',
                      countryCode: 'US',
                    )),
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
              await Radar.setNotificationOptions(
                const RadarNotificationOptions(iconString: 'icon'),
              );
              return 'ok';
            }),
            ApiAction('setPushNotificationToken()', () async {
              final token = await _prompt('setPushNotificationToken');
              if (token == null) return 'cancelled';
              await Radar.setPushNotificationToken(token);
              return token.isEmpty ? 'cleared' : token;
            }),
            ApiAction('showInAppMessage()', () async {
              await Radar.showInAppMessage(
                const RadarInAppMessage(
                  title: RadarInAppMessageText(
                    text: 'This is the title',
                    color: Color(0xFF000000),
                  ),
                  body: RadarInAppMessageText(
                    text: 'This is a demo message',
                    color: Color(0xFF666666),
                  ),
                  button: RadarInAppMessageButton(
                    text: 'Send it',
                    color: Color(0xFFFFFFFF),
                    backgroundColor: Color(0xFFEB0083),
                  ),
                ),
              );
              return 'shown';
            }),
          ],
        ),
      ];
}
