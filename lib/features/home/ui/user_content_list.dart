import 'package:flutter/material.dart';
import 'package:lokconnect/features/home/bloc/home_bloc.dart';
import 'package:lokconnect/widgets/shimmer_loader.dart';
import 'package:lokconnect/widgets/user_tile.dart';

class UserListContent extends StatelessWidget {
  final HomeState state;
  final ScrollController scrollController;
  final Function(List<dynamic>, int) approveUser;
   final Function(String) onDeleteUser;

  const UserListContent({
    required this.state,
    required this.scrollController,
    required this.approveUser,
    required this.onDeleteUser,
  });

  @override
  Widget build(BuildContext context) {


    if (state is HomeLoadingState) {
      return const ShimmerLoader();
    } else if (state is HomeSuccessState || state is HomeMoreUsersLoadedState) {
      final List<dynamic> users;
      final bool hasMore;

      if (state is HomeSuccessState) {
        users = (state as HomeSuccessState).users;
        hasMore = (state as HomeSuccessState).hasMore;
      } else {
        users = (state as HomeMoreUsersLoadedState).users;
        hasMore = (state as HomeMoreUsersLoadedState).hasMore;
      }

      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: hasMore ? users.length + 1 : users.length,
        itemBuilder: (context, index) {
          if (index < users.length) {
            return UserTile(
              onDeleteUser: onDeleteUser,
              user: users[index],
              onPressUserAproove: () async {
                approveUser(users, index);
              },
            );
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      );
    } else if (state is HomeErrorState) {
      return Center(
          child: Text("Some error occured!, Please try again later."));
    } else {
      return const Center(
        child: Text("No users found"),
      );
    }
  }
}
