part of 'user_addition_bloc.dart';

@immutable
sealed class UserAdditionEvent {}

class UploadDocument extends UserAdditionEvent {
  final String field;
  final File file;

  UploadDocument({required this.field, required this.file});
}

class RemoveDocument extends UserAdditionEvent {
  final String field;
  RemoveDocument({required this.field});
}