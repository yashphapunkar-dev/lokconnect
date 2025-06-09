import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/home/ui/home.dart';
import 'package:lokconnect/features/user_details/bloc/user_details_bloc.dart';
import 'package:lokconnect/features/user_details/ui/pdf_viewer_screen.dart';
import 'package:lokconnect/widgets/info_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {

  Map<String, TextEditingController> textFieldControllers = {
    "firstName": TextEditingController(),
    "lastName": TextEditingController(),
    "email": TextEditingController(),
    "phoneNumber": TextEditingController(),
    "plotNumber": TextEditingController(),
  };

  double widthHandler(double width) {
    if (width <= 768) {
      return 1;
    } else if (width >= 768 && width < 1280) {
      return 3;
    } else if (width >= 1280) {
      return 4;
    }
    return 0;
  }

  bool isLoading = false;

  Future<void> updateUserProfileAndDocuments({
    required Map<String, TextEditingController> textFieldControllers,
    required Map<String, dynamic>? updatedDocuments,
    required BuildContext context,
    required String userId,
    required VoidCallback onSuccessNavigate,
    required Function(bool) onLoading,
  }) async {
    onLoading(true);

    try {
      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        "firstName": textFieldControllers["firstName"]?.text.trim(),
        "lastName": textFieldControllers["lastName"]?.text.trim(),
        "email": textFieldControllers["email"]?.text.trim(),
        "phoneNumber": textFieldControllers["phoneNumber"]?.text.trim(),
        "plotNumber": textFieldControllers["plotNumber"]?.text.trim(),
        "documents": updatedDocuments,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User data & documents updated!")),
      );

      Future.delayed(
        Duration(milliseconds: 500),
        () => onSuccessNavigate(),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firebase error: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
    } finally {
      onLoading(false);
    }
  }


  Future<void> showAddDocumentDialog(
      BuildContext context, String userId) async {
    final TextEditingController nameController = TextEditingController();
    Uint8List? selectedFileBytes;
    String? selectedFileName;

    await showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return AlertDialog(
              title: Text("Add Document"),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      constraints.maxWidth < 500 ? constraints.maxWidth : 500,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: "Document Name"),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();

                        if (result != null &&
                            result.files.single.bytes != null) {
                          selectedFileBytes = result.files.single.bytes!;
                          selectedFileName = result.files.single.name;
                        }

                        // Rebuild dialog with new state
                        (context as Element).markNeedsBuild();
                      },
                      icon: Icon(Icons.upload_file),
                      label: Text("Pick File"),
                    ),
                    if (selectedFileName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Selected: $selectedFileName",
                          style: TextStyle(
                              fontSize: 14, fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text("Add"),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty ||
                        selectedFileBytes == null ||
                        selectedFileName == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text("Please enter a name and pick a file")),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      setState(() {
                        isLoading = true;
                      });
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('documents/$selectedFileName');
                      await ref.putData(selectedFileBytes!);
                      final downloadUrl = await ref.getDownloadURL();

                      final userDoc = FirebaseFirestore.instance
                          .collection("users")
                          .doc(userId);
                      final snapshot = await userDoc.get();
                      final existingDocuments =
                          (snapshot.data()?['documents'] ?? {})
                              as Map<String, dynamic>;

                      existingDocuments[name] = downloadUrl;

                      await userDoc.update({"documents": existingDocuments});

                       setState(() {
                        isLoading = false;
                      });
                      
                      userDetailsBloc.add(LoadUserDetailsEvent(widget.userId));

                    } catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Upload failed: $e")),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }


  UserDetailsBloc userDetailsBloc = UserDetailsBloc();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.black,
        foregroundColor: Colors.black,
        onPressed: () {
          showAddDocumentDialog(context, widget.userId);
        },
      ),
      backgroundColor: CustomColors.oceanBlue,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text("User Details", style: CustomTextStyle.headingTextStyle),
        backgroundColor: CustomColors.oceanBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () async {
              final state = context.read<UserDetailsBloc>().state;

              if (state is UserDetailsLoaded) {
                updateUserProfileAndDocuments(
                  textFieldControllers: textFieldControllers,
                  updatedDocuments: state.user.documents,
                  context: context,
                  userId: widget.userId,
                  onSuccessNavigate: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => Home()),
                    );
                  },
                  onLoading: (val) => setState(() => isLoading = val),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("User data is still loading. Please wait...")),
                );
              }
            },
          ),
        ],
      ),

      body: BlocBuilder<UserDetailsBloc, UserDetailsState>(
        builder: (context, state) {
          if (state is UserDetailsLoading) {
            return Center(
              child: CircularProgressIndicator(color: Colors.grey.shade200),
            );
          } else if (state is UserDetailsLoaded) {
            return Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: CustomColors.primaryColor,
                        borderRadius:
                            BorderRadius.only(topLeft: Radius.circular(40)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoTile(
                            filedName: "First Name",
                            textController: textFieldControllers['firstName'],
                            value: "${state.user.firstName}",
                          ),
                          InfoTile(
                            textController: textFieldControllers['lastName'],
                            filedName: "Last Name",
                            value: "${state.user.lastName}",
                          ),
                          InfoTile(
                            textController: textFieldControllers['email'],
                            value: state.user.email,
                            filedName: "Email",
                          ),
                          InfoTile(
                              textController:
                                  textFieldControllers['phoneNumber'],
                              value: "${state.user.phoneNumber}",
                              filedName: "Phone Number"),
                          InfoTile(
                              textController:
                                  textFieldControllers['plotNumber'],
                              value: "${state.user.plotNumber}",
                              filedName: "Plot Number"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: CustomColors.primaryColor,
                          borderRadius:
                              BorderRadius.only(topRight: Radius.circular(40)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ListView(
                            children: [
                              const Text(
                                "Documents",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GridView.builder(
                                itemCount: state.user.documents!.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: widthHandler(
                                          MediaQuery.sizeOf(context).width)
                                      .toInt(),
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  print("INDEX");
                                  final docEntries =
                                      state.user.documents!.entries.toList();
                                  print(docEntries);

                                  final docName = docEntries[index].key;
                                  final docUrl = docEntries[index].value;

                                  print(docName);
                                  print(docUrl);

                                  return Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white,
                                      ),
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.picture_as_pdf,
                                                size: 50,
                                                color: Color(0xFFEF4444)),
                                            onPressed: () {
                                              final url = docUrl;
                                              if (kIsWeb) {
                                                html.window.open(url, '_blank');
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        PDFViewerScreen(
                                                            url: url),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            docName,
                                            style: CustomTextStyle
                                                .subHeadingTextStyle,
                                          ),
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                state.user.documents!.remove(docName);
                                              });
                                            },
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            label: const Text("Delete",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: CustomColors.forestBrown))
                    : SizedBox.shrink(),
              ],
            );
          } else if (state is UserDetailsError) {
            return Center(child: Text(state.message));
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}
