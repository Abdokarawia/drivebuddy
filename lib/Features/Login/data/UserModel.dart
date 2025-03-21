import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Optional: For Firestore integration

class UserModel {
  final String uid; // Unique user ID from Firebase Authentication
  final String email; // User's email address
  final String? displayName; // Optional display name
  final bool isEmailVerified; // Whether the user's email is verified
  final DateTime? createdAt; // Account creation timestamp
  final DateTime? lastLoginAt; // Last login timestamp
  final String? photoUrl; // Optional profile picture URL

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.isEmailVerified = false,
    this.createdAt,
    this.lastLoginAt,
    this.photoUrl,
  });

  // Factory constructor to create UserModel from Firebase User object
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
      lastLoginAt: user.metadata.lastSignInTime,
      photoUrl: user.photoURL,
    );
  }

  // Factory constructor to create UserModel from a Map (e.g., Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      lastLoginAt: map['lastLoginAt'] != null
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : null,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  // Convert UserModel to a Map for storage (e.g., in Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'photoUrl': photoUrl,
    };
  }

  // CopyWith method for creating a new instance with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, '
        'isEmailVerified: $isEmailVerified, createdAt: $createdAt, '
        'lastLoginAt: $lastLoginAt, photoUrl: $photoUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}