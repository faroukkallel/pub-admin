import 'package:cloud_firestore/cloud_firestore.dart';

class TVSettings {
  final String id;
  final String collectionName;
  final String displayName;
  final String location;
  final Timestamp lastUpdated;
  final String updatedBy;

  TVSettings({
    required this.id,
    required this.collectionName,
    required this.displayName,
    required this.location,
    required this.lastUpdated,
    required this.updatedBy,
  });

  factory TVSettings.fromMap(Map<String, dynamic> map, String docId) {
    return TVSettings(
      id: docId,
      collectionName: map['collectionName'] ?? '',
      displayName: map['displayName'] ?? '',
      location: map['location'] ?? '',
      lastUpdated: map['lastUpdated'] as Timestamp? ?? Timestamp.now(),
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collectionName': collectionName,
      'displayName': displayName,
      'location': location,
      'lastUpdated': lastUpdated,
      'updatedBy': updatedBy,
    };
  }
}