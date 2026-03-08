import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/home/models/user_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// Define common text styles for consistency
class CustomTextStyle {
  static const TextStyle headingTextStyle =
      TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20);
  static const TextStyle subHeadingTextStyle =
      TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 16);
  static const TextStyle documentTextStyle =
      TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 14);
}

class UserMemberHomePage extends StatefulWidget {
  final String phoneNumber;

  const UserMemberHomePage({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<UserMemberHomePage> createState() => _UserMemberHomePageState();
}

class _UserMemberHomePageState extends State<UserMemberHomePage> {
  late Future<UserModel?> _userDataFuture;
  var lables = ["Membership Number", "Plot Number", "Email", "Phone Number"];

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<UserModel?> _fetchUserData() async {
    try {
      print("USER");
      print(widget.phoneNumber);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: widget.phoneNumber)
          .limit(1)
          .get();

      print(querySnapshot.docs);

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;

        UserModel user = UserModel.fromSnapshot(userDoc);

        if (!user.aprooved) {
          return null;
        }
        return user;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  void _viewDocumentInApp(BuildContext context, String docName, String docUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(
          pdfUrl: docUrl,
          title: docName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3e5f89), // Sets the background for the entire Scaffold
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF3e5f89),
        centerTitle: true,
        title:  Text("Lokconnect", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        // Use a Column to properly arrange top part and the expandable content
        children: [
          Expanded(
            // Make the content area expand to fill remaining space
            child: Container(
              decoration: const BoxDecoration(
                color: CustomColors
                    .primaryColor, // This is your "other color skin"
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: FutureBuilder<UserModel?>(
                future: _userDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    // Adjusted for null safety: if snapshot.data is null, it's not approved.
                    final bool isApproved = snapshot.data?.aprooved ?? false;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off,
                              size: 80, color: CustomColors.forestBrown),
                          const SizedBox(height: 20),
                          Text(
                            !isApproved
                                ? "Your account is not approved yet. Please contact admin."
                                : "You are not an authorized user. Please contact admin.",
                            textAlign: TextAlign.center,
                            style: CustomTextStyle.subHeadingTextStyle
                                .copyWith(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CustomColors.oceanBlue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text("Logout",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          )
                        ],
                      ),
                    );
                  } else {
                    UserModel user = snapshot.data!;
                    // The SingleChildScrollView is correctly placed here
                    // to make the content scrollable within the Expanded Container.
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                user.profilePicture == null
                                    ? Container(
                                        height: 85,
                                        width: 85,
                                        decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            border: Border.all(
                                                width: 1, color: Colors.grey),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(50))),
                                        child: Icon(
                                          Icons.person_2_outlined,
                                          size: 30,
                                          color: Colors.grey[600],
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                width: 2, color: Colors.white),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(50))),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundImage: user.profilePicture !=
                                                  null
                                              ? NetworkImage(user.profilePicture!)
                                              : null,
                                        ),
                                      ),
                                SizedBox(
                                  height: 15,
                                ),

              

                                
                                
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(width: 0.1),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20))),
                                  child: Text(
                                    "${user.firstName} ${user.lastName}",
                                    style: CustomTextStyle.subHeadingTextStyle
                                        .copyWith(fontSize: 18),
                                  ),
                                ),
                               
                               SizedBox(
                                  height: 15,
                                ),
                              
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("Welcome to Lokconnect!", textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15) ),
                                  Text("Your secure digital gateway to important property documents for the residents of Lokmanya Nagar.", textAlign: TextAlign.center),
                                ],
                              ),
                              

                            
                              ],
                            ),
                          ),

                          SizedBox(
                            height: 20,
                          ),

                          Material(
                            borderRadius: 
                                      BorderRadius.all(Radius.circular(20)),
                            elevation: 2,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              decoration: BoxDecoration(
                                
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  color: Colors.white),
                              child:
                               Column(
                                children: [
                                  _buildDetailRow("Membership Number", user.membershipNumber ?? 'N/A'),
                                  Container(width: double.maxFinite, color: Colors.grey.shade400, height: 1,),
                                  _buildDetailRow("Plot Number", user.plotNumber ?? 'N/A'),
                                     Container(width: double.maxFinite, color: Colors.grey.shade400, height: 1,),
                                  _buildDetailRow("Email", user.email ?? 'N/A'),
                                     Container(width: double.maxFinite, color: Colors.grey.shade400, height: 1,),
                            
                                  _buildDetailRow(
                                      "Phone Number", user.phoneNumber ?? 'N/A'),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          _buildSectionTitle("Documents"),
                          // Check for null documents map and if it's empty
                          user.documents == null || user.documents!.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      "No documents available.",
                                      style: CustomTextStyle.documentTextStyle
                                          .copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey.shade600),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(30)),
                                      ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: user.documents!.length,
                                    itemBuilder: (context, index) {
                                      String docName =
                                          user.documents!.keys.elementAt(index);
                                      String docUrl = user.documents!.values
                                          .elementAt(index);

                                      if (docName != "Profile Picture")
                                        return _buildDocumentTile(
                                            docName, docUrl);

                                      return SizedBox.shrink();
                                    },
                                  ),
                                ),
                                
                                SizedBox(height: 20,),
                                Text("IMPORTANT NOTICE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),),
                                Text("The information available on LokConnect is highly confidential and sensitive. It includes personal property documents such as lease agreements and official records. Please do not share, forward, or disclose any information from this application with unauthorized individuals."),
                                      SizedBox(height: 10,),
                                 Text("Appledore Consulting Group©", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center,),
                                       SizedBox(height: 10,),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: CustomTextStyle.subHeadingTextStyle.copyWith(
            color: CustomColors.darkPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    var iconColor = Color(0xFF3e5f89);
    return Container(
      width: double.maxFinite,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 10),
        child: Row(
          children: [
            label == 'Membership Number'
                ? Icon(Icons.person_2, color: iconColor)
                : SizedBox.shrink(),
            label == 'Plot Number'
                ? Icon(Icons.location_city, color: iconColor)
                : SizedBox.shrink(),
            label == 'Email'
                ? Icon(Icons.email, color: iconColor)
                : SizedBox.shrink(),
            label == 'Phone Number'
                ? Icon(Icons.phone, color: iconColor)
                : SizedBox.shrink(),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label',
                  style: CustomTextStyle.documentTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      fontSize: 16),
                ),

                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: CustomTextStyle.documentTextStyle
                      .copyWith(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w400),
                  overflow: TextOverflow.visible,
                ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(String docName, String docUrl) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _viewDocumentInApp(context, docName, docUrl),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf,
                  color: Color(0xFF3e5f89), size: 28),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docName,
                      style: CustomTextStyle.subHeadingTextStyle
                          .copyWith(color: CustomColors.darkPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view document',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({Key? key, required this.pdfUrl, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: CustomTextStyle.headingTextStyle),
        backgroundColor: Color(0xff3e5f89),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
