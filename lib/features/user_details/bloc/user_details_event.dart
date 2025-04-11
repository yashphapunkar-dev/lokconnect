part of 'user_details_bloc.dart';

abstract class UserDetailsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUserDetailsEvent extends UserDetailsEvent {
  final String userId;

  LoadUserDetailsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
