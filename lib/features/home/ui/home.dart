import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/admin_user_service.dart';
import 'package:lokconnect/features/home/bloc/home_bloc.dart';
import 'package:lokconnect/features/login/ui/login.dart';
import 'package:lokconnect/features/user_addition/ui/user_addition.dart';
import 'package:lokconnect/widgets/user_tile.dart';
import 'package:provider/provider.dart';
import '../../../widgets/custom_input.dart';
import '../../../widgets/shimmer_loader.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late HomeBloc homeBloc;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final role = Provider.of<AdminUserService>(context, listen: false).role?.trim() ?? '';
    homeBloc = HomeBloc(role: role);
    homeBloc.add(HomeInitialEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    homeBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore) {
      isLoadingMore = true;
      homeBloc.add(HomeLoadMoreUsersEvent());
    }
  }

  void _approveUser(users, index) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(users[index].userId!)
        .update({
      "aprooved": !users[index].aprooved,
    }).then((value) {
      setState(() {
        users[index].aprooved = !users[index].aprooved;
      });
    });
  }

  void _onSearchChanged(String value) {
    homeBloc.add(SearchUsersEvent(query: value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: homeBloc,
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (previous, current) => current is HomeActionState,
        buildWhen: (previous, current) => current is! HomeActionState,
        listener: (context, state) {
          if (state is NavigateAddUserState) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => UserAdditionScreen(),
            ));
          }

          if (state is HomeMoreUsersLoadedState || state is HomeSuccessState) {
            isLoadingMore = false;
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: CustomColors.oceanBlue,
            appBar: AppBar(
              actions: [
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
          );
        }
      },
    ),
  ],
              leading: const SizedBox.shrink(),
              centerTitle: true,
              title: const Text(
                "Home",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: CustomColors.oceanBlue,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => UserAdditionScreen())),
              backgroundColor: Colors.grey.shade900,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    color: CustomColors.primaryColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomInput(
                      textController: _searchController,
                      hintText: 'Enter first name or plot number to search',
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: CustomColors.primaryColor,
                    child: Builder(
                      builder: (context) {
                        if (state is HomeLoadingState) {
                          return const ShimmerLoader();
                        } else if (state is HomeSuccessState ||
                            state is HomeMoreUsersLoadedState) {
                          final users = state is HomeSuccessState
                              ? state.users
                              : (state as HomeMoreUsersLoadedState).users;
                          final hasMore = state is HomeSuccessState
                              ? state.hasMore
                              : (state as HomeMoreUsersLoadedState).hasMore;
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount:
                                hasMore ? users.length + 1 : users.length,
                            itemBuilder: (context, index) {
                              if (index < users.length) {
                                return UserTile(
                                  user: users[index],
                                  onPressUserAproove: () async {
                                    _approveUser(users, index);
                                  },
                                );
                              } else {
                                return const Center(
                                    child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(),
                                ));
                              }
                            },
                          );
                        } else if (state is HomeErrorState) {
                          return Center(child: Text(state.message));
                        } else {
                          return const Center(
                            child: Text("No users found"),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
