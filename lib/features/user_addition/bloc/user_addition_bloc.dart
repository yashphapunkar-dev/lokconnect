import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'dart:io';
part 'user_addition_event.dart';
part 'user_addition_state.dart';

class UserAdditionBloc extends Bloc<UserAdditionEvent, UserAdditionState> {
  UserAdditionBloc() : super(UserAdditionState(uploadedDocuments: {})) {
    on<UserAdditionEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
