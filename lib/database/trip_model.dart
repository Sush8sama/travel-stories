import 'data_model.dart';

class Trip implements DataModel{
  @override
  final int? id;
  final String title;
  final String description;
  final DateTime createdAt;

  Trip({
    this.id,
    required this.title,
    required this.description,
    required this.createdAt
  });

  @override
  String get tableName => 'trips';

  // Convert a Trip into a Map (for inserting into DB)
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(), // Convert DateTime to String
    };
  }

  // Extract a Trip object from a Map (reading from DB)
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']), // Convert String back to DateTime
    );
  }
}