import 'package:flutter/material.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/home/bloc/home_bloc.dart';
import 'package:lokconnect/features/user_addition/ui/user_addition.dart';
import 'package:lokconnect/widgets/user_tile.dart';
import '../../../widgets/custom_input.dart';
import '../../../widgets/shimmer_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final HomeBloc homeBloc = HomeBloc();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    homeBloc.add(HomeInitialEvent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore) {
        isLoadingMore = true;
        homeBloc.add(HomeLoadMoreUsersEvent());
      }
    }
  }

  void _onSearchChanged(String value) {
    homeBloc.add(SearchUsersEvent(query: value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      bloc: homeBloc,
      listenWhen: (previous, current) => current is HomeActionState,
      buildWhen: (previous, current) => current is! HomeActionState,
      listener: (context, state) {
        if (state is NavigateAddUserState) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => UserAdditionScreen(),
          ));
        }

        if (state is HomeMoreUsersLoadedState || state is HomeSuccessState) {
          // setState(() {
          isLoadingMore = false;
          // });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: CustomColors.rosePink,
          appBar: AppBar(
            leading: const SizedBox.shrink(),
            centerTitle: true,
            title: const Text(
              "Home",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: CustomColors.rosePink,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => homeBloc.add(NavigateToAddUser()),
            backgroundColor: Colors.grey.shade900,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  color: CustomColors.primaryColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CustomInput(
                    textController: _searchController,
                    hintText: 'Search users',
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
                        print("HAS MORE");
                        print(hasMore);
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: hasMore ? users.length + 1 : users.length,
                          itemBuilder: (context, index) {
                            if (index < users.length) {
                              return UserTile(user: users[index]);
                            } else {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
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
    );
  }
}
