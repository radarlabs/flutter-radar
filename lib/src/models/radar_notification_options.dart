import 'dart:ui' show Color;

import 'package:meta/meta.dart';

import 'parsing.dart';

/// Icons, colors, and deep link for the notifications the Android SDK shows,
/// set with `Radar.setNotificationOptions`.
///
/// Android only. iOS ignores these options.
final class RadarNotificationOptions {
  const RadarNotificationOptions({
    this.iconString,
    this.iconColor,
    this.foregroundServiceIconString,
    this.foregroundServiceIconColor,
    this.eventIconString,
    this.eventIconColor,
    this.deepLink,
  });

  /// The name of a drawable resource used as the default icon for all
  /// notifications, like `"ic_notification"`.
  final String? iconString;

  /// The default icon color for all notifications. Sent as `#RRGGBB`, so the
  /// alpha is ignored.
  final Color? iconColor;

  /// The foreground service notification icon. Defaults to [iconString].
  final String? foregroundServiceIconString;

  /// The foreground service notification icon color. Defaults to [iconColor].
  final Color? foregroundServiceIconColor;

  /// The event notification icon. Defaults to [iconString].
  final String? eventIconString;

  /// The event notification icon color. Defaults to [iconColor].
  final Color? eventIconColor;

  /// A deep link opened when a notification is tapped.
  final String? deepLink;

  @internal
  Map<String, Object?> toMap() => compact({
    'iconString': iconString,
    'iconColor': iconColor == null ? null : colorToHex(iconColor!),
    'foregroundServiceIconString': foregroundServiceIconString,
    'foregroundServiceIconColor':
        foregroundServiceIconColor == null
            ? null
            : colorToHex(foregroundServiceIconColor!),
    'eventIconString': eventIconString,
    'eventIconColor':
        eventIconColor == null ? null : colorToHex(eventIconColor!),
    'deepLink': deepLink,
  });
}
