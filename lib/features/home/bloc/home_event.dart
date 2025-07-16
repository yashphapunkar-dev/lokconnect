part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

class HomeInitialEvent extends HomeEvent {}
class LoadMoreUsersEvent extends HomeEvent {}
class SearchUsersEvent extends HomeEvent {
  final String query;
  SearchUsersEvent({required this.query});
}
class HomeLoadMoreUsersEvent extends HomeEvent {}
class NavigateToAddUser extends HomeEvent {}

class HomeDeleteUserEvent extends HomeEvent {
  final String userId;

  HomeDeleteUserEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}