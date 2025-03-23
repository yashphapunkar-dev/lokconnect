part of 'user_addition_bloc.dart';

// @immutable
// sealed class UserAdditionState {}

// final class UserAdditionInitial extends UserAdditionState {}

class UserAdditionState {
  final Map<String, File?> uploadedDocuments;

  UserAdditionState({required this.uploadedDocuments});

  UserAdditionState copyWith({Map<String, File?>? uploadedDocuments}) {
    return UserAdditionState(
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
    );
  }
}