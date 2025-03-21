class ProfileModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;

  ProfileModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'phoneNumber': phoneNumber,
  };

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      phoneNumber: json['phoneNumber'],
    );
  }

  ProfileModel copyWith({
    String? name,
    String? email,
    String? displayName,
    String? phoneNumber,
  }) {
    return ProfileModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}