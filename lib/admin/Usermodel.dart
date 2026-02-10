class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' or 'client'
  final List<String> accessibleCollections; // List of collection names this user can access

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.accessibleCollections,
  });

  // Create a UserModel from a map (e.g., Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      role: map['role'] ?? 'client',
      accessibleCollections: List<String>.from(map['accessibleCollections'] ?? []),
    );
  }

  // Convert UserModel to a map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'accessibleCollections': accessibleCollections,
    };
  }
}