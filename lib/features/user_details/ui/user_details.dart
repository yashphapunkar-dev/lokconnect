import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/user_details/bloc/user_details_bloc.dart';
import 'package:lokconnect/features/user_details/ui/pdf_viewer_screen.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;

  const UserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Details", style: CustomTextStyle.headingTextStyle), backgroundColor: CustomColors.dustyRose,),
      body: BlocBuilder<UserDetailsBloc, UserDetailsState>(
        builder: (context, state) {
          if (state is UserDetailsLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is UserDetailsLoaded) {
            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                Text("Name: ${state.user.firstName} ${state.user.lastName}"),
                Text("Email: ${state.user.email}"),
                Text("Phone: ${state.user.phoneNumber}"),
                Text("Plot: ${state.user.plotNumber}"),
                SizedBox(height: 24),
                Text("Documents",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...state.documents.entries.map((entry) => ListTile(
                      title: Text(entry.key),
                      trailing: Icon(Icons.picture_as_pdf),
                      onTap: () async {
                        // final Uri url = Uri.parse(pdfUrl);
                        // if (await canLaunchUrl(url)) {
                        //   await launchUrl(url,
                        //       mode: LaunchMode.externalApplication);
                        // } else {
                        //   throw 'Could not launch $url';
                        // }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PDFViewerScreen(url: entry.value),
                          ),
                        );
                      },
                    )),
              ],
            );
          } else if (state is UserDetailsError) {
            return Center(child: Text(state.message));
          } else {
            return SizedBox();
          }
        },
      ),
    );
  }
}
