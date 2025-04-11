import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
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

  HomeBloc() : super(HomeInitial()) {
    on<HomeInitialEvent>(_onInitial);
    on<HomeLoadMoreUsersEvent>(_onLoadMore);
    on<SearchUsersEvent>(_onSearch);
    on<NavigateToAddUser>(_onNavigateToAddUser);
  }

  Future<void> _onInitial(
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

  Future<FetchUsersResult?> _fetchUsers({required bool isLoadMore}) async {
    try {
      Query query =
          _firestore.collection('users').orderBy("firstName").limit(_limit);
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;

        final newUsers = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _users.addAll(newUsers);
      } else {
        _hasMore = false;
      }
      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }

      return FetchUsersResult(users: _users, hasMore: _hasMore);
    } catch (e) {
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
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('firstName', isGreaterThanOrEqualTo: event.query)
          .where('firstName', isLessThanOrEqualTo: '${event.query}\uf8ff')
          .get();

      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      emit(HomeSuccessState(users: users, hasMore: false));
    } catch (e) {
      emit(HomeErrorState(message: "Search failed"));
    }
  }

  Future<void> _onLoadMore(
      HomeLoadMoreUsersEvent event, Emitter<HomeState> emit) async {
    if (!_hasMore) return;

    final result = await _fetchUsers(isLoadMore: true);
    if (result != null) {
      emit(HomeMoreUsersLoadedState(
          users: result.users, hasMore: result.hasMore));
    } else {
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
