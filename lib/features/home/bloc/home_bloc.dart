import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lokconnect/features/home/models/user_model.dart';
import 'package:meta/meta.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final int _limit = 10;
  final String role;
   bool _hasMoreUsers = true;
   bool get hasReachedMax => !_hasMoreUsers;

  HomeBloc({required this.role}) : super(HomeInitial()) {
    on<HomeInitialEvent>(onInitial);
    on<HomeLoadMoreUsersEvent>(_onLoadMore);
    on<SearchUsersEvent>(_onSearch);
    on<NavigateToAddUser>(_onNavigateToAddUser);
    on<HomeDeleteUserEvent>(_onHomeDeleteUserEvent);
  }
  

  Future<void> onInitial(
      HomeInitialEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());
    _users.clear();
    _lastDocument = null;
    _hasMore = true;

    final result = await _fetchUsers(isLoadMore: false);
    if (result != null) {
      emit(HomeSuccessState(users: result.users, hasMore: result.hasMore));
    } else {
      emit(HomeErrorState(message: "Failed to fetch users"));
    }
  }

   Future<void> _onHomeDeleteUserEvent(
      HomeDeleteUserEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState()); 
    try {
      await _firestore.collection('users').doc(event.userId).delete(); 
      await onInitial(HomeInitialEvent(), emit); 
    } catch (e) {
      emit(HomeErrorState(message: "Failed to delete user: $e"));
    }
  }

Future<FetchUsersResult?> _fetchUsers({required bool isLoadMore}) async {
    try {
      Query query =
          _firestore.collection('users').orderBy("firstName").limit(_limit);

      if (role != 'superadmin') {
        query = query.where("aprooved", isEqualTo: true);
      }

      // Only add the startAfterDocument cursor if it's a "load more"
      // and we have a last document from the previous fetch.
      if (isLoadMore && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();

      // Check for an empty snapshot first.
      if (snapshot.docs.isNotEmpty) {
        // We have new documents, so add them to our list
        final newUsers = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _users.addAll(newUsers);

        // Update the last document cursor for the next fetch
        _lastDocument = snapshot.docs.last;
        
        // Determine if there are more users. If the number of documents
        // returned is less than the limit, it means we've reached the end.
        _hasMore = snapshot.docs.length == _limit;
      } else {
        // If the snapshot is empty, there are no more users to load.
        _hasMore = false;
      }

      return FetchUsersResult(users: _users, hasMore: _hasMore);
    } catch (e) {
      print(e);
      // It's good practice to handle the error more gracefully.
      // Maybe return a specific error result or re-throw.
      return null;
    }
  }

  Future<void> _onSearch(
      SearchUsersEvent event, Emitter<HomeState> emit) async {
    if (event.query.isEmpty) {
      add(HomeInitialEvent());
      return;
    }

    emit(HomeLoadingState());
    try {
      Query query = _firestore.collection('users');

      // Check if numeric query
      if (RegExp(r'^\d+$').hasMatch(event.query)) {
        query = query.where('plotNumber', isEqualTo: event.query);
      } else {
        query = query
            .where('firstName', isGreaterThanOrEqualTo: event.query)
            .where('firstName', isLessThanOrEqualTo: '${event.query}\uf8ff');
      }

      if (role != 'superadmin') {
        query = query.where("aprooved", isEqualTo: true);
      }

      QuerySnapshot snapshot = await query.get();

      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      emit(HomeSuccessState(users: users, hasMore: false));
    } catch (e) {
      emit(HomeErrorState(message: "Search failed"));
    }
  }

 Future<void> _onLoadMore(
    HomeLoadMoreUsersEvent event, Emitter<HomeState> emit) async {

  // CRUCIAL: Check if a fetch is already in progress.
  // This prevents race conditions from the UI's scroll listener.
  if (state is HomeLoadingState || state is HomeMoreUsersLoadedState) {
    return;
  }
  
  if (!_hasMore) {
    // We have no more users to load, so emit a state indicating the end.
    // This handles the case where the BLoC is asked to load more,
    // but the last fetch already determined there's no more data.
    emit(HomeMoreUsersLoadedState(users: _users, hasMore: false));
    return;
  }

  // OPTIONAL: You could emit a temporary loading state here if you want
  // to show a loader while waiting for the result.
  // emit(HomeLoadingMoreState()); // You would need to define this state

  final result = await _fetchUsers(isLoadMore: true);
  
  if (result != null) {
    emit(HomeMoreUsersLoadedState(
        users: result.users, hasMore: result.hasMore));
  } else {
    // It's good to provide a message in the state for user feedback.
    emit(HomeErrorState(message: "Failed to load more users"));
  }
}

  Future<void> _onNavigateToAddUser(
      NavigateToAddUser event, Emitter<HomeState> emit) async {
    emit(NavigateAddUserState());
  }
}

class FetchUsersResult {
  final List<UserModel> users;
  final bool hasMore;

  FetchUsersResult({required this.users, required this.hasMore});
}


