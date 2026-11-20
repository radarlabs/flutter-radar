import 'package:meta/meta.dart';

import 'parsing.dart';

/// A banner message shown with `Radar.showInAppMessage`.
///
/// Colors are hex strings like `"#000000"`. iOS only parses `#RRGGBB` (or
/// `RRGGBB`) and drops any text, button, or image whose color it cannot parse.
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
  static RadarInAppMessage? fromMap(ChannelMap? map) {
    if (map == null) return null;
    final title = RadarInAppMessageText.fromMap(readMap(map['title']));
    final body = RadarInAppMessageText.fromMap(readMap(map['body']));
    if (title == null || body == null) return null;
    return RadarInAppMessage(
      title: title,
      body: body,
      button: RadarInAppMessageButton.fromMap(readMap(map['button'])),
      image: RadarInAppMessageImage.fromMap(readMap(map['image'])),
      metadata: readJson(map['metadata']) ?? const {},
    );
  }

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

  /// The text color, as a hex string like `"#000000"`.
  final String color;

  @internal
  static RadarInAppMessageText? fromMap(ChannelMap? map) {
    if (map == null) return null;
    final text = readString(map['text']);
    final color = readString(map['color']);
    if (text == null || color == null) return null;
    return RadarInAppMessageText(text: text, color: color);
  }

  @internal
  Map<String, Object?> toMap() => {'text': text, 'color': color};
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

  /// The text color, as a hex string like `"#FFFFFF"`.
  final String color;

  /// The background color, as a hex string like `"#000000"`.
  final String backgroundColor;

  /// A deep link opened when the button is tapped.
  final String? deepLink;

  @internal
  static RadarInAppMessageButton? fromMap(ChannelMap? map) {
    if (map == null) return null;
    final text = readString(map['text']);
    final color = readString(map['color']);
    final backgroundColor = readString(map['backgroundColor']);
    if (text == null || color == null || backgroundColor == null) return null;
    final deepLink = readString(map['deepLink']);
    return RadarInAppMessageButton(
      text: text,
      color: color,
      backgroundColor: backgroundColor,
      deepLink: deepLink == null || deepLink.isEmpty ? null : deepLink,
    );
  }

  @internal
  Map<String, Object?> toMap() => compact({
    'text': text,
    'color': color,
    'backgroundColor': backgroundColor,
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
  static RadarInAppMessageImage? fromMap(ChannelMap? map) {
    if (map == null) return null;
    final name = readString(map['name']);
    if (name == null) return null;
    final url = readString(map['url']);
    return RadarInAppMessageImage(
      name: name,
      url: url == null || url.isEmpty ? null : url,
    );
  }

  @internal
  Map<String, Object?> toMap() => compact({'name': name, 'url': url});
}
