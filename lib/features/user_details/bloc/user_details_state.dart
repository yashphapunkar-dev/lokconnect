part of 'user_details_bloc.dart';

@immutable
abstract class UserDetailsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserDetailsInitial extends UserDetailsState {}

class UserDetailsLoading extends UserDetailsState {}

class UserDetailsLoaded extends UserDetailsState {
  final UserModel user;
  final Map<String, dynamic> documents;

  UserDetailsLoaded({required this.user, required this.documents});

  @override
  List<Object?> get props => [user, documents];
}

class UserDetailsError extends UserDetailsState {
  final String message;

  UserDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}
