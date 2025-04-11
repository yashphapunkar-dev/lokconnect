class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String plotNumber;
  final String? userId;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.userId,
    required this.email,
    required this.plotNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, [String? userId]) {
    return UserModel(
      userId: userId,
      id: map['id'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      plotNumber: map['plotNumber'] ?? '',
    );
  }
}