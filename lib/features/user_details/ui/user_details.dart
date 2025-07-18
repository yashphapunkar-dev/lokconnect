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
import 'package:lokconnect/widgets/uploading_model.dart';

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
    "membershipNumber": TextEditingController(),
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

  onPressDeleteDoc(String docName) {
    setState(() {
      docsLoading = true;
    });

    FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'documents.$docName': FieldValue.delete(),
      'aprooved': false,
    }).then((_) {
      setState(() {
        docsLoading = false;
      });
    }).catchError((e) {
      setState(() {
        docsLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete document: $e")),
      );
    });
  }

  Stream<Map<String, String>> getDocumentsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((docSnapshot) {
      final data = docSnapshot.data();
      if (data == null || data['documents'] == null) return {};
      return Map<String, String>.from(data['documents']);
    });
  }

  bool isLoading = false;
  bool docsLoading = false;

  Future<void> updateUserProfileAndDocuments({
    required Map<String, TextEditingController> textFieldControllers,
    // required Map<String, dynamic>? updatedDocuments,
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
        "membershipNumber":
            textFieldControllers["membershipNumber"]?.text.trim(),
        "aprooved": false,    
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
                        docsLoading = true;
                      });
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('documents/$selectedFileName');
                      await ref.putData(
                        selectedFileBytes!,
                        SettableMetadata(
                          contentType: 'application/pdf',
                          contentDisposition: 'inline',
                        ),
                      );
                      final downloadUrl = await ref.getDownloadURL();

                      final userDoc = FirebaseFirestore.instance
                          .collection("users")
                          .doc(userId);
                      final snapshot = await userDoc.get();
                      final existingDocuments =
                          (snapshot.data()?['documents'] ?? {})
                              as Map<String, dynamic>;

                      existingDocuments[name] = downloadUrl;

                      await userDoc.update({"documents": existingDocuments, 'aprooved': false});

                      setState(() {
                        docsLoading = false;
                      });
                    } catch (e) {
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
                  // updatedDocuments: state.user.documents,
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
                LayoutBuilder(builder: (context, constraints) {
                  final isWideScreen = kIsWeb && constraints.maxWidth > 800;
                  if (isWideScreen) {
                    return Row(
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
                                textController:
                                    textFieldControllers['firstName'],
                                value: "${state.user.firstName}",
                              ),
                              InfoTile(
                                textController:
                                    textFieldControllers['lastName'],
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
                              InfoTile(
                                textController:
                                    textFieldControllers['membershipNumber'],
                                value: state.user.membershipNumber,
                                filedName: "Membership Number",
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: CustomColors.primaryColor,
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(40)),
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
                                  StreamBuilder<Map<String, String>>(
                                    stream: getDocumentsStream(widget.userId),
                                    builder: (context, snapshot) {
                                      if (isLoading || !snapshot.hasData) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      final documents = snapshot.data!;
                                      final docEntries =
                                          documents.entries.toList();

                                      return GridView.builder(
                                        itemCount: docEntries.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: widthHandler(
                                                  MediaQuery.sizeOf(context)
                                                      .width)
                                              .toInt(),
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          final docName = docEntries[index].key;
                                          final docUrl =
                                              docEntries[index].value;

                                          return Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Colors.white,
                                              ),
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.picture_as_pdf,
                                                      size: 50,
                                                      color: Color(0xFFEF4444),
                                                    ),
                                                    onPressed: () {
                                                      if (kIsWeb) {
                                                        // Navigator.of(context).push(
                                                        //     MaterialPageRoute(
                                                        //         builder:
                                                        //             (
                                                        //               (context) =>
                                                        //                 FirebasePdfViewer(
                                                        //                   downloadUrl:
                                                        //                       docUrl,
                                                        //                   key: Key(
                                                        //                       'a'),
                                                        //                 )
                                                        //                 )));
                                                        // FirebasePdfViewer(downloadUrl: docUrl, key: Key('a'),);

                                                        // html.window.open(
                                                        //     docUrl, '_blank');
                                                      } else {}
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
                                                      onPressDeleteDoc(docName);
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    label: const Text("Delete",
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return SizedBox(
                      height: MediaQuery.sizeOf(context).height,
                      child: ListView(
                        children: [
                          Container(
                            padding: EdgeInsets.only(top: 30),
                            decoration: const BoxDecoration(
                              color: CustomColors.primaryColor,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(40)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                InfoTile(
                                  filedName: "First Name",
                                  textController:
                                      textFieldControllers['firstName'],
                                  value: "${state.user.firstName}",
                                ),
                                InfoTile(
                                  textController:
                                      textFieldControllers['lastName'],
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
                                InfoTile(
                                  textController:
                                      textFieldControllers['membershipNumber'],
                                  value: state.user.membershipNumber,
                                  filedName: "Membership Number",
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: CustomColors.primaryColor,
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
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
                                  StreamBuilder<Map<String, String>>(
                                    stream: getDocumentsStream(widget.userId),
                                    builder: (context, snapshot) {
                                      if (isLoading || !snapshot.hasData) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      final documents = snapshot.data!;
                                      final docEntries =
                                          documents.entries.toList();

                                      return GridView.builder(
                                        itemCount: docEntries.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: widthHandler(
                                                  MediaQuery.sizeOf(context)
                                                      .width)
                                              .toInt(),
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 2.5,
                                        ),
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          final docName = docEntries[index].key;
                                          final docUrl =
                                              docEntries[index].value;

                                          return Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                  top: 20, bottom: 20),
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Colors.white,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.picture_as_pdf,
                                                      size: 50,
                                                      color: Color(0xFFEF4444),
                                                    ),
                                                    onPressed: () {
                                                      if (kIsWeb) {
                                                        // Navigator.of(context).push(
                                                        //     MaterialPageRoute(
                                                        //         builder:
                                                        //             ((context) =>
                                                        //                 FirebasePdfViewer(
                                                        //                   downloadUrl:
                                                        //                       docUrl,
                                                        //                   key: Key(
                                                        //                       'a'),
                                                        //                 ))));

                                                        // html.window.open(
                                                        //     docUrl, '_blank');
                                                      } else {
                                                        // Navigator.push(
                                                        //   context,
                                                        //   MaterialPageRoute(
                                                        //     builder: (_) =>
                                                        //         PDFViewerScreen(
                                                        //             url:
                                                        //                 docUrl),
                                                        //   ),
                                                        // );
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
                                                      onPressDeleteDoc(docName);
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    label: const Text("Delete",
                                                        style: TextStyle(
                                                            color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }),
                docsLoading ? UploadingModal() : SizedBox.shrink(),
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
