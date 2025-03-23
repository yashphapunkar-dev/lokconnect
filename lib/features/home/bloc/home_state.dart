part of 'home_bloc.dart';

@immutable
sealed class HomeState {}

abstract class HomeActionState extends HomeState{}

final class HomeInitial extends HomeState {}

class HomeLoadingState extends HomeState{} 

class HomeSuccessState extends HomeState{}

class HomeErrorState extends HomeState{}

class NavigateAddUserState extends HomeActionState{}

