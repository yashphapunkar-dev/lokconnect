part of 'user_addition_bloc.dart';

abstract class UserAdditionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitUserForm extends UserAdditionEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String plotNumber;
  final Map<String, PlatformFile> documents;

  SubmitUserForm({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.plotNumber,
    required this.documents,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, phoneNumber, plotNumber, documents];
}

class UploadDocument extends UserAdditionEvent {
  final String field;
  final PlatformFile file;

  UploadDocument({required this.field, required this.file});

  @override
  List<Object?> get props => [field, file];
}

class RemoveDocument extends UserAdditionEvent {
  final String field;

  RemoveDocument({required this.field});

  @override
  List<Object?> get props => [field];
}