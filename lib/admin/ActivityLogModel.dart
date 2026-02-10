import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String action; // 'upload' or 'delete'
  final String videoUrl;
  final String videoId;
  final String collectionName; // TV name
  final String clientId;
  final String clientEmail;
  final Timestamp timestamp;
  final Timestamp? videoCreatedAt;
  final int? activeDays; // Only for delete actions - days the video was live

  ActivityLogModel({
    required this.id,
    required this.action,
    required this.videoUrl,
    required this.videoId,
    required this.collectionName,
    required this.clientId,
    required this.clientEmail,
    required this.timestamp,
    this.videoCreatedAt,
    this.activeDays,
  });

  // Create from a map (Firestore document)
  factory ActivityLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return ActivityLogModel(
      id: docId,
      action: map['action'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      videoId: map['videoId'] ?? '',
      collectionName: map['collectionName'] ?? '',
      clientId: map['clientId'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      timestamp: map['timestamp'] as Timestamp? ?? Timestamp.now(),
      videoCreatedAt: map['videoCreatedAt'] as Timestamp?,
      activeDays: map['activeDays'],
    );
  }

  // Convert to a map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'videoUrl': videoUrl,
      'videoId': videoId,
      'collectionName': collectionName,
      'clientId': clientId,
      'clientEmail': clientEmail,
      'timestamp': timestamp,
      'videoCreatedAt': videoCreatedAt,
      'activeDays': activeDays,
    };
  }
}