import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/admin_user_service.dart';
import 'package:lokconnect/features/home/bloc/home_bloc.dart';
import 'package:lokconnect/features/home/ui/home_app_bar.dart';
import 'package:lokconnect/features/home/ui/user_content_list.dart';
import 'package:lokconnect/features/user_addition/ui/user_addition.dart';
import 'package:provider/provider.dart';
import '../ui/home_search_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late HomeBloc _homeBloc;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;


  @override
  void initState() {
    super.initState();
    final role =
        Provider.of<AdminUserService>(context, listen: false).role?.trim() ?? '';
    _homeBloc = HomeBloc(role: role);
    _homeBloc.add(HomeInitialEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll); // REM
    _scrollController.dispose();
    _searchController.dispose();
    _homeBloc.close();
    super.dispose();
  }

   void _onScroll() {
    final hasReachedMax = _homeBloc.hasReachedMax;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _homeBloc.state is! HomeLoadingState &&
        !hasReachedMax) {
      _homeBloc.add(HomeLoadMoreUsersEvent());
    }
  }

  void _approveUser(List<dynamic> users, int index) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(users[index].userId!)
        .update({
      "aprooved": !users[index].aprooved,
    }).then((_) {
      setState(() {
        users[index].aprooved = !users[index].aprooved;
      });
    });
  }

  void _onSearchChanged(String value) {
    _homeBloc.add(SearchUsersEvent(query: value.trim()));
  }

  @override
  Widget build(BuildContext context) {

     void deleteUser(String userId) {
        _homeBloc.add(HomeDeleteUserEvent(userId: userId));
     } 


    return BlocProvider.value(
      value: _homeBloc,
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
            _isLoadingMore = false;
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: CustomColors.oceanBlue,
            appBar: HomeAppBar(),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserAdditionScreen())),
              backgroundColor: Colors.grey.shade900,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: Column(
              children: [
                HomeSearchBar(
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                ),
                Expanded(
                  child: Container(
                    color: CustomColors.primaryColor,
                    child: UserListContent(
                      state: state,
                      onDeleteUser: deleteUser,
                      // deleteUserFunction: deleteUser,
                      scrollController: _scrollController,
                      approveUser: _approveUser,
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
