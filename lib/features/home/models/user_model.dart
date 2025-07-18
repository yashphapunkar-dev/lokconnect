import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String plotNumber;
  final String membershipNumber;
  final String? userId;
  final Map<String, dynamic>? documents; // <-- Optional documents list
  bool aprooved;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.plotNumber,
    required this.membershipNumber,
    this.userId,
    this.aprooved = false,
    this.documents, // <-- Optional in constructor
  });

  factory UserModel.fromMap(Map<String, dynamic> map, [String? userId]) {
    return UserModel(
      userId: userId,
      id: map['id'] ?? '',
      membershipNumber: map["membershipNumber"] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      plotNumber: map['plotNumber'] ?? '',
      documents: map['documents'] != null
          ? Map<String, dynamic>.from(map['documents'])
          : null,
      aprooved: map['aprooved'] ?? false    
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, snapshot.id);
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