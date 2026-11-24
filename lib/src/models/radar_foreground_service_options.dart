import 'dart:ui' show Color;

import 'package:meta/meta.dart';

import 'parsing.dart';

/// The foreground service notification the Android SDK shows while tracking,
/// set with `Radar.setForegroundServiceOptions`.
///
/// Android only. iOS ignores these options. The service only runs when
/// `RadarTrackingOptions.foregroundServiceEnabled` is true.
final class RadarForegroundServiceOptions {
  const RadarForegroundServiceOptions({
    this.text,
    this.title,
    this.icon,
    this.iconString,
    this.iconColor,
    this.updatesOnly = false,
    this.activity,
    this.importance,
    this.id,
    this.channelName,
    this.deepLink,
  });

  /// The notification text. The SDK defaults to `"Location tracking started"`.
  final String? text;

  /// The notification title.
  final String? title;

  /// The notification icon as a drawable resource ID. Prefer [iconString].
  final int? icon;

  /// The name of a drawable resource used as the notification icon, like
  /// `"ic_notification"`.
  final String? iconString;

  /// The notification icon color. Sent as `#RRGGBB`, so the alpha is ignored.
  final Color? iconColor;

  /// Whether to show the notification only during location updates, rather
  /// than for as long as tracking is on.
  final bool updatesOnly;

  /// The fully qualified activity class to start when the notification is
  /// tapped, like `"com.example.app.MainActivity"`.
  final String? activity;

  /// The notification importance, one of Android's
  /// `NotificationManager.IMPORTANCE_*` values.
  final int? importance;

  /// The notification ID. The SDK defaults to `20160525`.
  final int? id;

  /// The user-facing notification channel name. The SDK defaults to
  /// `"Location Services"`.
  final String? channelName;

  /// A deep link opened when the notification is tapped.
  final String? deepLink;

  @internal
  Map<String, Object?> toMap() => compact({
    'text': text,
    'title': title,
    'icon': icon,
    'iconString': iconString,
    'iconColor': iconColor == null ? null : colorToHex(iconColor!),
    'updatesOnly': updatesOnly,
    'activity': activity,
    'importance': importance,
    'id': id,
    'channelName': channelName,
    'deepLink': deepLink,
  });
}
