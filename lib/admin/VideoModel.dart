import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String videoUrl;
  final String collectionName; // TV name
  final int order;
  final String status; // 'active' or 'deleted'
  final String type; // 'video' or 'image'
  final Timestamp createdAt;
  final String uploadedBy; // User ID
  final String uploadedByEmail; // User email
  final Timestamp? deletedAt;
  final String? deletedBy; // User ID
  final String? deletedByEmail; // User email
  final int? activeDays; // Days the video was active before deletion
  final int priority; // 1-10 playback priority
  final int duration; // Duration in seconds (for images)

  VideoModel({
    required this.id,
    required this.videoUrl,
    required this.collectionName,
    required this.order,
    required this.status,
    this.type = 'video',
    required this.createdAt,
    required this.uploadedBy,
    required this.uploadedByEmail,
    this.deletedAt,
    this.deletedBy,
    this.deletedByEmail,
    this.activeDays,
    this.priority = 5,
    this.duration = 10,
  });

  // Create from a map (Firestore document)
  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    return VideoModel(
      id: docId,
      videoUrl: map['videoUrl'] ?? '',
      collectionName: map['collectionName'] ?? '',
      order: map['order'] ?? 0,
      status: map['status'] ?? 'active',
      type: map['type'] ?? 'video',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedByEmail: map['uploadedByEmail'] ?? '',
      deletedAt: map['deletedAt'] as Timestamp?,
      deletedBy: map['deletedBy'],
      deletedByEmail: map['deletedByEmail'],
      activeDays: map['activeDays'],
      priority: map['priority'] ?? 5,
      duration: map['duration'] ?? 10,
    );
  }

  // Convert to a map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'collectionName': collectionName,
      'order': order,
      'status': status,
      'type': type,
      'createdAt': createdAt,
      'uploadedBy': uploadedBy,
      'uploadedByEmail': uploadedByEmail,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
      'deletedByEmail': deletedByEmail,
      'activeDays': activeDays,
      'priority': priority,
      'duration': duration,
    };
  }
}