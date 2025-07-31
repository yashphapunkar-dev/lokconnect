import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/home/models/user_model.dart';
import 'package:lokconnect/features/home/ui/home.dart';
import 'package:lokconnect/features/user_details/bloc/user_details_bloc.dart';
import 'package:lokconnect/features/user_details/ui/pdf_viewer_screen.dart';
import 'package:lokconnect/features/user_details/ui/ui_functions.dart';
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

  bool _isUploading = false;
  Uint8List? _pickedImageBytes; // Stores image bytes for display (web & mobile)
  String? _pickedImagePath; // Stores image path for mobile upload
String? _pickedImageName; 
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late final ProfilePictureService _profilePictureService;

  @override
  void initState() {
    super.initState();
    _profilePictureService = ProfilePictureService(storage: storage, firestore: firestore);
  }



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

                      await userDoc.update(
                          {"documents": existingDocuments, 'aprooved': false});

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

  Future<void> _uploadProfilePicture(
    BuildContext dialogContext,
    dynamic
        state, // Use your actual Bloc state type here (e.g., UserAdditionState)
  ) async {
    // 1. Check if an image is actually picked (either bytes or path)
    if (_pickedImageBytes == null && _pickedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image first.')));
      return;
    }

    // 2. Set Uploading State (UI feedback)
    // if (mounted) {
      // Ensure widget is still in the tree
      setState(() {
        _isUploading = true;
      });
    // }

    try {
      String downloadUrl;
      // 3. Call service based on platform
      if (kIsWeb) {
        // For Flutter Web, pass bytes to the service
        downloadUrl = await _profilePictureService.uploadProfilePicture(
          imageBytes: _pickedImageBytes!, 
          fileName: _pickedImageName!, // Pass bytes
          userId: widget.userId,
          // You might need to add contentType to your service method if it's not inferred
          // contentType: 'image/jpeg', // Example, infer this from XFile if possible
        );
      } else {
        // For mobile, pass the File object (or path, depending on service design)
        downloadUrl = await _profilePictureService.uploadProfilePicture(
          imageFile: File(_pickedImagePath!), // Pass File object
          userId: widget.userId,
        );
      }

      // 4. Update Local State (after successful upload)
      // if (mounted) {
        setState(() {
          // Assuming your state is immutable and you're using Bloc,
          // 'state' parameter here is a local copy. You need to dispatch an event
          // or use context.read<BlocType>().add() to update the actual Bloc state.
          // For now, I'll show how you'd update if 'state' was a mutable property
          // of the State class, but remember Bloc's pattern.

          // If 'state' is directly part of your StatefulWidget's State, this is fine:
          // state = state.copyWith(user: state.user.copyWith(profilePicture: downloadUrl));

          // If 'state' comes from a Bloc/Cubit (more likely for your project),
          // you should dispatch an event to your Bloc/Cubit to update the user's profile picture.
          // Example (assuming you have a Bloc/Cubit that manages User state):
          // context.read<UserBloc>().add(UpdateUserProfilePicture(downloadUrl));

          // For the local UI representation in the dialog:
          // _pickedImageBytes = null;
          // _pickedImagePath = null;
          // _pickedImageName = null; 
          _isUploading = false;
        });
      // }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile picture updated successfully!')));
      Navigator.of(dialogContext).pop(); // Close the dialog
    } catch (e) {
      // 5. Handle Errors
      print('Error uploading profile picture: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile picture: $e')));
    }
  }

  Future<void> _deleteProfilePicture(
      BuildContext dialogContext, dynamic state) async {
    if (mounted) {
      setState(() {
        _pickedImageBytes = null;
        _pickedImageName = null;
         state.user.profilePicture = null;
        _isUploading = true;
      });
    }
    try {
      await _profilePictureService.deleteProfilePicture(
        userId: widget.userId,
        imageUrl: state.user.profilePicture, 
      );

      if (mounted) {
        setState(() {
          _pickedImageBytes = null; 
          _pickedImagePath = null;
          _pickedImageName = null; 
          _isUploading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile picture removed successfully!')));
      Navigator.of(dialogContext).pop(); // Close the dialog
    } catch (e) {
      print('Error deleting profile picture: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove profile picture: $e')));
    }
  }

void _showImageOptionsAlert(state) {

  showDialog(
    context: context,
    barrierDismissible: !_isUploading,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateInDialog) {
          return AlertDialog(
            title: const Text("Profile Picture Options"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  _pickedImageBytes != null
    ? CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(_pickedImageBytes!),
      )
    // Check if state.user.profilePicture is NOT null AND NOT empty
    : (state.user.profilePicture != null && state.user.profilePicture.isNotEmpty
        ? CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(state.user.profilePicture),
          )
        : Container(
            // Fallback if no picked image AND no profile picture URL
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(width: 1, color: Colors.grey),
              borderRadius: const BorderRadius.all(Radius.circular(50)),
            ),
            child: Icon(
              Icons.person_2_outlined,
              size: 30,
              color: Colors.grey[600],
            ),
          )),
                  const SizedBox(height: 20),

                  if (_isUploading) 
                   LinearProgressIndicator(),

                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text("Upload New Photo"),
                    onTap: _isUploading
                        ? null // Disable if uploading
                        : () async {
                            final XFile? image = await _picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              // Read bytes from XFile for display
                              final bytes = await image.readAsBytes();
                              setStateInDialog(() {
                                _pickedImageBytes = bytes;
                                _pickedImageName = image.name; // Capture filename for web
                                if (!kIsWeb) {
                                  _pickedImagePath = image.path;
                                } else {
                                  _pickedImagePath = null;
                                }
                              });
                            }
                          },
                  ),
                  if (state.user.profilePicture != null ||
                      _pickedImageBytes != null) // Check bytes for "picked"
                    ListTile(
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text("Remove Photo",
                          style: TextStyle(color: Colors.red)),
                      onTap: _isUploading
                          ? null // Disable if uploading
                          : () {
                              _deleteProfilePicture(dialogContext, state);
                            },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isUploading
                    ? null // Disable if uploading
                    : () {
                        setStateInDialog(() {
                          // _pickedImageBytes = null; // Clear bytes
                          // _pickedImagePath = null; // Clear path
                          _pickedImageName = null; // Clear name
                        });
                        Navigator.of(dialogContext).pop(); // Close dialog
                      },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: (_pickedImageBytes == null ||
                        _isUploading) // Check bytes for "picked" AND if uploading
                    ? null
                    : () async {

                        setState(() {
                          _isUploading = true;
                        });
                        print(_isUploading);

                        await _uploadProfilePicture(dialogContext, state);
                        //  setState(() {
                        //    _isUploading = false;
                        //  });

                      },
                child: _isUploading
                    ? const SizedBox(
                        height: 45,
                        width: 45,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save"),
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
                    return SizedBox(
                      height: MediaQuery.sizeOf(context).height,
                      child: SingleChildScrollView(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Align content to the top
                          children: [
                            // User Details Section (takes flexible width)
                            Expanded(
                              // Use Expanded to give it available space
                              flex: 1, // Can adjust flex for desired proportion
                              child: SizedBox(
                                height: MediaQuery.sizeOf(context).height,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: CustomColors.primaryColor,
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(40)),
                                  ),
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [

                                      _isUploading ? CircularProgressIndicator() :  GestureDetector(
                                        onTap: _isUploading
                                            ? null
                                            : () => _showImageOptionsAlert(
                                                state), 
                                        child: _pickedImageBytes !=
                                                null // Now check for _pickedImageBytes
                                            ? Container(
                                                height: 65,
                                                width: 65,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  border: Border.all(
                                                    width: 1,
                                                    color: Colors
                                                        .blueAccent, 
                                                  ),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(50),
                                                  ),
                                                ),
                                                child: ClipOval(
                                                  // Ensure image is circular
                                                  child: Image.memory(
                                                    // THIS IS THE KEY CHANGE for local images
                                                    _pickedImageBytes!, // Use the bytes directly
                                                    fit: BoxFit.cover,
                                                    width: 65,
                                                    height: 65,
                                                  ),
                                                ),
                                              )
                                            : (state.user.profilePicture !=
                                                    null 
                                                ? CircleAvatar(
                                                    radius:
                                                        32.5, 
                                                    backgroundImage:
                                                        NetworkImage(state.user
                                                            .profilePicture!),
                                                  
                                                  )
                                                : Container(
                                                    height: 65,
                                                    width: 65,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      border: Border.all(
                                                        width: 1,
                                                        color: Colors.grey,
                                                      ),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                        Radius.circular(50),
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.person_2_outlined,
                                                      size: 30,
                                                      color: Colors.grey[600],
                                                    ),
                                                  )),
                                      ),

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
                                        textController:
                                            textFieldControllers['email'],
                                        value: state.user.email,
                                        filedName: "Email",
                                      ),
                                      InfoTile(
                                          textController: textFieldControllers[
                                              'phoneNumber'],
                                          value: "${state.user.phoneNumber}",
                                          filedName: "Phone Number"),
                                      InfoTile(
                                          textController: textFieldControllers[
                                              'plotNumber'],
                                          value: "${state.user.plotNumber}",
                                          filedName: "Plot Number"),
                                      InfoTile(
                                        textController: textFieldControllers[
                                            'membershipNumber'],
                                        value: state.user.membershipNumber,
                                        filedName: "Membership Number",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Documents Section (takes flexible width)
                            Expanded(
                              // Use Expanded to give it available space
                              flex:
                                  2, // Can adjust flex for desired proportion (e.g., documents take more space)
                              child: Container(
                                height: MediaQuery.sizeOf(context).height,
                                decoration: BoxDecoration(
                                  color: CustomColors.primaryColor,
                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(40)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        stream:
                                            getDocumentsStream(widget.userId),
                                        builder: (context, snapshot) {
                                          if (isLoading || !snapshot.hasData) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          final documents = snapshot.data!;
                                          final docEntries =
                                              documents.entries.toList();

                                          return Wrap(
                                            spacing: 10.0,
                                            runSpacing: 10.0,
                                            children: docEntries.map((entry) {
                                              final docName = entry.key;
                                              final docUrl = entry.value;

                                              return Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 3,
                                                child: Container(
                                                  width:
                                                      150, // Fixed width for each document card, adjust as needed
                                                  // Min-width constraint for responsiveness could be added here
                                                  // For example: constraints: BoxConstraints(minWidth: 120, maxWidth: 200),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    color: Colors.white,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.picture_as_pdf,
                                                          size: 50,
                                                          color:
                                                              Color(0xFFEF4444),
                                                        ),
                                                        onPressed: () {
                                                          if (kIsWeb) {
                                                            Navigator.of(context).push(
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        ((context) =>
                                                                            FirebasePdfViewer(
                                                                              downloadUrl: docUrl,
                                                                              key: const Key('a'),
                                                                            ))));
                                                          } else {
                                                            // Handle non-web PDF viewing
                                                          }
                                                        },
                                                      ),
                                                      const SizedBox(
                                                          height: 10),
                                                      Text(
                                                        docName,
                                                        style: CustomTextStyle
                                                            .subHeadingTextStyle,
                                                        textAlign: TextAlign
                                                            .center, // Center text
                                                        maxLines:
                                                            2, // Limit lines to prevent overflow
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      TextButton.icon(
                                                        onPressed: () {
                                                          onPressDeleteDoc(
                                                              docName);
                                                        },
                                                        icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red),
                                                        label: const Text(
                                                            "Delete",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
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
                      ),
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
                                                        Navigator.of(context).push(
                                                            MaterialPageRoute(
                                                                builder:
                                                                    ((context) =>
                                                                        FirebasePdfViewer(
                                                                          downloadUrl:
                                                                              docUrl,
                                                                          key: Key(
                                                                              'a'),
                                                                        ))));

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
                _isUploading ? Center(child: CircularProgressIndicator()) : SizedBox.shrink(),
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
