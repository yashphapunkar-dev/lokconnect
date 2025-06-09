import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:lokconnect/features/home/models/user_model.dart';

part 'user_details_event.dart';
part 'user_details_state.dart';

class UserDetailsBloc extends Bloc<UserDetailsEvent, UserDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserDetailsBloc() : super(UserDetailsInitial()) {
    on<LoadUserDetailsEvent>(_onLoadUserDetails);
  }

  Future<void> _onLoadUserDetails(
    LoadUserDetailsEvent event,
    Emitter<UserDetailsState> emit,
  ) async {
    print("EVENT TESTING");
    print(event);
    emit(UserDetailsLoading());

    try {
      final doc = await _firestore.collection('users').doc(event.userId).get();
      final userData = await doc.data();

      if (userData == null) {
        emit(UserDetailsError(message: "User not found"));
        return;
      }

      final user = UserModel.fromMap(userData);
                  
      final documents = userData['documents'] as Map<String, dynamic>;


      emit(UserDetailsLoaded(user: user, documents: documents));
    } catch (e) {
      print("TEST EERRROR");
      print(e);
      emit(UserDetailsError(message: "Failed to fetch user details"));
    }
  }
}
