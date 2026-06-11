import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The tools available in the whiteboard toolbar.
enum WhiteboardTool {
  selection,
  pen,
  rectangle,
  ellipse,
  line,
  arrow,
  text,
}

/// The persisted type of a single element on the whiteboard.
enum WhiteboardElementType {
  freehand,
  rectangle,
  ellipse,
  line,
  arrow,
  text,
}

extension WhiteboardElementTypeName on WhiteboardElementType {
  String get name {
    switch (this) {
      case WhiteboardElementType.freehand:
        return 'freehand';
      case WhiteboardElementType.rectangle:
        return 'rectangle';
      case WhiteboardElementType.ellipse:
        return 'ellipse';
      case WhiteboardElementType.line:
        return 'line';
      case WhiteboardElementType.arrow:
        return 'arrow';
      case WhiteboardElementType.text:
        return 'text';
    }
  }

  static WhiteboardElementType fromName(String value) {
    return WhiteboardElementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WhiteboardElementType.freehand,
    );
  }
}

/// A single drawable element on the whiteboard.
///
/// Coordinates are stored in the whiteboard's own (unscaled) coordinate space,
/// independent of the current pan/zoom of the viewport.
///
/// - [freehand]/[line]/[arrow] use [points] (absolute coordinates).
/// - [rectangle]/[ellipse] use [points] holding two opposite corners.
/// - [text] uses the first entry of [points] as the top-left anchor.
class WhiteboardElement {
  WhiteboardElement({
    required this.id,
    required this.type,
    required this.points,
    this.text = '',
    this.strokeColor = 0xFF1F1F1F,
    this.fillColor,
    this.strokeWidth = 2.0,
    this.fontSize = 16.0,
  });

  final String id;
  final WhiteboardElementType type;

  /// Absolute points in whiteboard coordinate space.
  List<Offset> points;

  String text;

  /// ARGB color value for the stroke / text color.
  int strokeColor;

  /// ARGB color value for the fill, or null for no fill.
  int? fillColor;

  double strokeWidth;
  double fontSize;

  /// The axis-aligned bounding box that encloses the element.
  Rect get bounds {
    if (points.isEmpty) {
      return Rect.zero;
    }
    double minX = points.first.dx;
    double minY = points.first.dy;
    double maxX = points.first.dx;
    double maxY = points.first.dy;
    for (final p in points) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }

    // Text has no second point, so give it an estimated extent so it can be
    // selected and moved.
    if (type == WhiteboardElementType.text) {
      final width = math.max(40.0, text.length * fontSize * 0.55);
      return Rect.fromLTWH(minX, minY, width, fontSize * 1.4);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Returns whether [point] (in whiteboard coordinates) hits this element,
  /// using [tolerance] to make thin elements easier to grab.
  bool hitTest(Offset point, {double tolerance = 8.0}) {
    switch (type) {
      case WhiteboardElementType.line:
      case WhiteboardElementType.arrow:
        if (points.length < 2) return false;
        return _distanceToSegment(point, points.first, points.last) <=
            tolerance + strokeWidth;
      case WhiteboardElementType.freehand:
        for (var i = 0; i < points.length - 1; i++) {
          if (_distanceToSegment(point, points[i], points[i + 1]) <=
              tolerance + strokeWidth) {
            return true;
          }
        }
        return bounds.inflate(tolerance).contains(point) &&
            points.length == 1;
      case WhiteboardElementType.rectangle:
      case WhiteboardElementType.ellipse:
      case WhiteboardElementType.text:
        return bounds.inflate(tolerance).contains(point);
    }
  }

  /// Moves the element by [delta] in whiteboard coordinates.
  void translate(Offset delta) {
    points = points.map((p) => p + delta).toList();
  }

  WhiteboardElement copy() {
    return WhiteboardElement(
      id: id,
      type: type,
      points: List<Offset>.from(points),
      text: text,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      fontSize: fontSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'points': points.map((p) => [p.dx, p.dy]).toList(),
      'text': text,
      'strokeColor': strokeColor,
      'fillColor': fillColor,
      'strokeWidth': strokeWidth,
      'fontSize': fontSize,
    };
  }

  factory WhiteboardElement.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List?) ?? const [];
    final points = rawPoints
        .map<Offset>(
          (p) => Offset(
            (p[0] as num).toDouble(),
            (p[1] as num).toDouble(),
          ),
        )
        .toList();
    return WhiteboardElement(
      id: json['id'] as String,
      type: WhiteboardElementTypeName.fromName(json['type'] as String),
      points: points,
      text: (json['text'] as String?) ?? '',
      strokeColor: (json['strokeColor'] as num?)?.toInt() ?? 0xFF1F1F1F,
      fillColor: (json['fillColor'] as num?)?.toInt(),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
    );
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLengthSquared == 0) {
      return (p - a).distance;
    }
    var t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLengthSquared;
    t = t.clamp(0.0, 1.0);
    final projection = a + ab * t;
    return (p - projection).distance;
  }
}

/// Serializes a list of elements to a compact JSON string for storage in the
/// block node attributes.
String encodeWhiteboardElements(List<WhiteboardElement> elements) {
  return jsonEncode(elements.map((e) => e.toJson()).toList());
}

/// Parses the stored JSON string back into a list of elements. Returns an
/// empty list on any malformed input so the canvas never fails to load.
List<WhiteboardElement> decodeWhiteboardElements(String? raw) {
  if (raw == null || raw.isEmpty) {
    return [];
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(WhiteboardElement.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}
