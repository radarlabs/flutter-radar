import 'dart:ui' show Color;

import 'package:meta/meta.dart';

import 'parsing.dart';

/// A banner message shown with `Radar.showInAppMessage`.
///
/// Colors are sent to the native SDKs as `#RRGGBB`, so their alpha is ignored.
final class RadarInAppMessage {
  const RadarInAppMessage({
    required this.title,
    required this.body,
    this.button,
    this.image,
    this.metadata = const {},
  });

  final RadarInAppMessageText title;
  final RadarInAppMessageText body;
  final RadarInAppMessageButton? button;
  final RadarInAppMessageImage? image;

  /// Custom data attached to the message. Values must be JSON-encodable.
  final Map<String, Object?> metadata;

  @internal
  Map<String, Object?> toMap() => compact({
    'title': title.toMap(),
    'body': body.toMap(),
    'button': button?.toMap(),
    'image': image?.toMap(),
    'metadata': metadata,
  });
}

/// The title or body text of a [RadarInAppMessage].
final class RadarInAppMessageText {
  const RadarInAppMessageText({required this.text, required this.color});

  final String text;

  /// The text color.
  final Color color;

  @internal
  Map<String, Object?> toMap() => {'text': text, 'color': colorToHex(color)};
}

/// The call-to-action button of a [RadarInAppMessage].
final class RadarInAppMessageButton {
  const RadarInAppMessageButton({
    required this.text,
    required this.color,
    required this.backgroundColor,
    this.deepLink,
  });

  final String text;

  /// The text color.
  final Color color;

  /// The background color.
  final Color backgroundColor;

  /// A deep link opened when the button is tapped.
  final String? deepLink;

  @internal
  Map<String, Object?> toMap() => compact({
    'text': text,
    'color': colorToHex(color),
    'backgroundColor': colorToHex(backgroundColor),
    'deepLink': deepLink,
  });
}

/// The image of a [RadarInAppMessage].
final class RadarInAppMessageImage {
  const RadarInAppMessageImage({required this.name, this.url});

  final String name;

  /// The image URL. iOS requires it and drops an image without one.
  final String? url;

  @internal
  Map<String, Object?> toMap() => compact({'name': name, 'url': url});
}
