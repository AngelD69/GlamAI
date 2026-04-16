class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final String? profilePicture;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        gender: json['gender'] as String?,
        dateOfBirth: json['date_of_birth'] as String?,
        profilePicture: json['profile_picture'] as String?,
      );

  User copyWith({
    String? name,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? profilePicture,
  }) =>
      User(
        id: id,
        email: email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        profilePicture: profilePicture ?? this.profilePicture,
      );
}
