part of 'home_bloc.dart';

@immutable
sealed class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

abstract class HomeActionState extends HomeState {}

final class HomeInitial extends HomeState {}

class HomeLoadingState extends HomeState {}

class HomeMoreUsersLoadedState extends HomeState {
  final List<UserModel> users;
  final bool hasMore;

  HomeMoreUsersLoadedState({required this.users, required this.hasMore});

  @override
  List<Object?> get props => [users, hasMore];
}


class HomeSuccessState extends HomeState {
  final List<UserModel> users;
  final bool hasMore;

  HomeSuccessState({required this.users, required this.hasMore});

  @override
  List<Object?> get props => [users, hasMore];
}

class HomeErrorState extends HomeState {
  final String message;
  const HomeErrorState({required this.message});
  @override
  List<Object?> get props => [message];
}

class NavigateAddUserState extends HomeActionState {}