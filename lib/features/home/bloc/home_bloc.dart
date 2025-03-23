import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<HomeInitialEvent>(homeInitialEvent);
    on<NavigateToAddUser>(navigateToAddUser);
  }

  FutureOr<void> homeInitialEvent(HomeInitialEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());

    await Future.delayed(Duration(seconds: 1));

    emit(HomeSuccessState());
  }

  FutureOr<void> navigateToAddUser(NavigateToAddUser event, Emitter<HomeState> emit) {
     emit(NavigateAddUserState());
  }
}
