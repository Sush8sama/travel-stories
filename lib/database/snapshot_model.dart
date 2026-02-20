import 'dart:convert'; // Required for jsonEncode/jsonDecode
import 'data_model.dart';

class Snapshot implements DataModel{
  final int? id;
  final int tripId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String memo;
  final List<String> photoPaths; // The array
  final int markerColor;         // Store Color as int
  final String markerIcon;
  final String lineStyle;

  Snapshot({
    this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.memo,
    required this.photoPaths,
    required this.markerColor,
    required this.markerIcon,
    required this.lineStyle,
  });

  @override
  String get tableName => 'snapshots';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'memo': memo,
      // Convert List<String> -> JSON String
      'photo_paths': jsonEncode(photoPaths),
      'marker_color': markerColor,
      'marker_icon': markerIcon,
      'line_style': lineStyle,
    };
  }

  factory Snapshot.fromMap(Map<String, dynamic> map) {
    return Snapshot(
      id: map['id'],
      tripId: map['trip_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: DateTime.parse(map['timestamp']),
      memo: map['memo'],
      // Convert JSON String -> List<String>
      photoPaths: List<String>.from(jsonDecode(map['photo_paths'])),
      markerColor: map['marker_color'],
      markerIcon: map['marker_icon'],
      lineStyle: map['line_style'],
    );
  }
}