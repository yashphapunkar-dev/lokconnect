import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/admin_user_service.dart';
import 'package:lokconnect/features/home/models/user_model.dart';
import 'package:lokconnect/features/user_details/bloc/user_details_bloc.dart';
import 'package:lokconnect/features/user_details/ui/user_details.dart';
import 'package:provider/provider.dart';

class UserTile extends StatefulWidget {

  final UserModel user;
  final onPressUserAproove;
  const UserTile({super.key, required this.user, required this.onPressUserAproove});

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {

  @override
  Widget build(BuildContext context) {
      String? role = Provider.of<AdminUserService>(context, listen: false).role;

    return InkWell(
      
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
            border: Border.all(width: 0.2, color: CustomColors.oceanBlue),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(3, 3),
              ),
            ],
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            InkWell(

              onTap: () {
          print(AdminUserService().isAdmin);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) =>
                  UserDetailsBloc()..add(LoadUserDetailsEvent(widget.user.userId!)),
              child: UserDetailsScreen(userId: widget.user.userId!),
            ),
          ),
        );
      },
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        color: Colors.grey.shade300),
                    child: Icon(
                      Icons.person_2_rounded,
                      size: 30,
                      color: CustomColors.forestBrown,
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.user.firstName} ${widget.user.lastName}',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Plot no: ${widget.user.plotNumber}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700),
                      )
                    ],
                  ),
                  
                ],
              ),
            ),
            
            if(role!.trim() == "superadmin")
            InkWell(
              onTap: () {
                widget.onPressUserAproove();
              },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: widget.user.aprooved == true  ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(40)
                    ),
              
                    child: Text( widget.user.aprooved == true ? "Verified" : "Aproove", style: TextStyle(color: Colors.white, fontSize: 14),)
                    ),
                ) 
                else SizedBox.shrink(),
                
                // : SizedBox.shrink()
          ],
        ),
      ),
    );
  }
}
