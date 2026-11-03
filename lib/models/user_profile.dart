import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> d) => UserProfile(
        uid: d['uid'] ?? '',
        email: d['email'] ?? '',
        displayName: d['displayName'] ?? '',
        createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
