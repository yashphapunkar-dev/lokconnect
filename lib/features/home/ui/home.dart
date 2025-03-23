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
  double height = 0, width = 0;
  Color mainColor = Color(0xfff1efe7);
  bool loading = true;

  @override
  void initState() {
    super.initState();
    homeBloc.add(HomeInitialEvent());
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.sizeOf(context).height;
    width = MediaQuery.sizeOf(context).width;
    return BlocConsumer<HomeBloc, HomeState>(
      bloc: homeBloc,
      listenWhen: (previous, current) => current is HomeActionState,
      buildWhen: (previous, current) => current is! HomeActionState,
      listener: (context, state) {
        if (state is NavigateAddUserState) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => UserAdditionForm()));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: CustomColors.rosePink,
          appBar: 
          AppBar(
            leading: SizedBox.shrink(),
            centerTitle: true,
            title: Text(
              "Home",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: CustomColors.rosePink,
          ),
          
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              homeBloc.add(NavigateToAddUser());
            },
            backgroundColor: Colors.grey.shade900,
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
          body: Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: 20, bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40)),
                  color: CustomColors.primaryColor,
                ),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: CustomInput(
                      textController: TextEditingController(),
                      hintText: 'Search users',
                    )),
              ),
              Expanded(
                child: Container(
                  color: CustomColors.primaryColor,
                  child: state is HomeLoadingState
                      ? ShimmerLoader()
                      : Container(
                          height: height,
                          child: ListView.builder(
                              padding: EdgeInsets.only(bottom: 50),
                              itemCount: 10,
                              itemBuilder: (context, index) {
                                return UserTile();
                              }),
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
