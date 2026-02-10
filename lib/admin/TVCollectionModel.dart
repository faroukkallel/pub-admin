class TVCollectionModel {
  final String id;
  final String displayName;
  final String collectionName; // Technical identifier

  TVCollectionModel({
    required this.id,
    required this.displayName,
    required this.collectionName,
  });

  // Create from Firestore document
  factory TVCollectionModel.fromMap(Map<String, dynamic> map, String docId) {
    return TVCollectionModel(
      id: docId,
      displayName: map['displayName'] ?? map['collectionName'] ?? 'Unknown TV',
      collectionName: map['collectionName'] ?? '',
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'collectionName': collectionName,
    };
  }
}