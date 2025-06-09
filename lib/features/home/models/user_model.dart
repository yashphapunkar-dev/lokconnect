class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String plotNumber;
  final String? userId;
  final Map<String, dynamic>? documents; // <-- Optional documents list

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.plotNumber,
    this.userId,
    this.documents, // <-- Optional in constructor
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
      documents: map['documents'] != null
          ? Map<String, dynamic>.from(map['documents'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'plotNumber': plotNumber,
      'documents': documents,
    };
  }
}