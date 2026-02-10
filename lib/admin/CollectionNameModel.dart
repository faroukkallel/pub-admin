import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionNameModel {
  final String id;
  final String collectionName;
  final String displayName;

  CollectionNameModel({
    required this.id,
    required this.collectionName,
    required this.displayName,
  });

  factory CollectionNameModel.fromMap(Map<String, dynamic> map, String docId) {
    return CollectionNameModel(
      id: docId,
      collectionName: map['collectionName'] ?? '',
      displayName: map['displayName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collectionName': collectionName,
      'displayName': displayName,
    };
  }
}