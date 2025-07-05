import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/home/ui/home.dart';
import 'package:lokconnect/features/user_addition/bloc/user_addition_bloc.dart';
import 'package:lokconnect/widgets/FormField.dart';
import 'package:lokconnect/widgets/custom_button.dart';
import 'package:lokconnect/widgets/uploading_model.dart';

class CustomTextStyle {
   static const TextStyle headingTextStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20);
   static const TextStyle subHeadingTextStyle = TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 16);
   static const TextStyle documentTextStyle = TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 14);
}

// Assuming CustomColors is defined as:
// class CustomColors {
//   static const Color primaryColor = Color(0xFFF1EFE7);
//   static const Color oceanBlue = Color(0xFF0A1931);
//   static const Color forestBrown = Color(0xFF4B3832);
// }


class UserAdditionScreen extends StatefulWidget {
  @override
  _UserAdditionScreenState createState() => _UserAdditionScreenState();
}

class _UserAdditionScreenState extends State<UserAdditionScreen> {
  final _formKey = GlobalKey<FormState>();

  String firstName = '';
  String lastName = '';
  String email = '';
  String phoneNumber = '';
  String plotNumber = '';
  String membershipNumber = '';

  final List<String> initialDocumentNames = [
    "⁠Lease Deed",
    "Nomination Form",
    "⁠Member Application Form",
    "⁠Sale Purchase Documents",
    "⁠Legal Documents",
    "Aadhar",
    "Pan",
  ];

  Map<String, dynamic> customDocuments = {};

  @override
  void initState() {
    super.initState();
    for (var docName in initialDocumentNames) {
      customDocuments[docName] = null;
    }
  }

  void onPressAddDocument() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newDocName = '';

        return AlertDialog(
          title: const Text("Enter Document Name"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: "e.g. Driving License"),
            onChanged: (value) {
              newDocName = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () {
                if (newDocName.trim().isNotEmpty && !customDocuments.containsKey(newDocName.trim())) {
                  setState(() {
                    customDocuments[newDocName.trim()] = null;
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _pickDocument(String field) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);

    if (result != null) {
      PlatformFile file = result.files.single;
      setState(() {
        customDocuments[field] = file;
      });
    }
  }

  void _removeDocument(String field) {
    setState(() {
      customDocuments.remove(field);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      BlocProvider.of<UserAdditionBloc>(context).add(
        SubmitUserForm(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          plotNumber: plotNumber,
          membershipNumber: membershipNumber,
          documents: customDocuments,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Please fill all required fields.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: CustomColors.primaryColor,
        padding: const EdgeInsets.only(top: 10),
        child: CustomButton(
          buttonText: "Submit",
          onPress: _submitForm,
        ),
      ),
      backgroundColor: CustomColors.oceanBlue,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "User Addition",
          style: CustomTextStyle.headingTextStyle,
        ),
        backgroundColor: CustomColors.oceanBlue,
      ),
      body: BlocConsumer<UserAdditionBloc, UserAdditionState>(
        listener: (context, state) {
          if (!state.isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User added successfully!")));
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => Home()));
          }
        },
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
                color: CustomColors.primaryColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40))),
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height,
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWideScreen =
                                    kIsWeb && constraints.maxWidth > 800;

                                if (isWideScreen) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Left side: Input Fields
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            CustomFormField(
                                                title: "First Name",
                                                onChanged: (val) =>
                                                    firstName = val,
                                                validator: (val) => val!.isEmpty ? "First Name is required" : null,),
                                            CustomFormField(
                                                title: "Last Name",
                                                onChanged: (val) =>
                                                    lastName = val,
                                                validator: (val) => val!.isEmpty ? "Last Name is required" : null,),
                                            CustomFormField(
                                                title: "Membership Number",
                                                onChanged: (val) =>
                                                    membershipNumber = val,
                                                validator: (val) => val!.isEmpty ? "Membership Number is required" : null,),
                                            CustomFormField(
                                                title: "Email",
                                                onChanged: (val) =>
                                                    email = val,
                                                validator: (val) {
                                                  if (val == null || val.isEmpty) return "Email is required";
                                                  if (!val.contains('@')) return "Enter a valid email";
                                                  return null;
                                                }),
                                            CustomFormField(
                                                title: "Phone Number",
                                                onChanged: (val) =>
                                                    phoneNumber = val,
                                                validator: (val) {
                                                  if (val == null || val.isEmpty) return "Phone Number is required";
                                                  if (val.length < 10) return "Enter a 10-digit phone number";
                                                  return null;
                                                }),
                                            CustomFormField(
                                                title: "Plot Number",
                                                onChanged: (val) =>
                                                    plotNumber = val,
                                                validator: (val) => val!.isEmpty ? "Plot Number is required" : null,),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 40),

                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              ...customDocuments.entries
                                                  .map((entry) {
                                                String key = entry.key;
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  margin: const EdgeInsets.only(
                                                      top: 15),
                                                  decoration: BoxDecoration(
                                                    color: CustomColors
                                                        .forestBrown
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(key,
                                                          style: CustomTextStyle
                                                              .documentTextStyle),
                                                      customDocuments[key] !=
                                                              null
                                                          ? Row(
                                                              children: [
                                                                SizedBox(
                                                                  width: 100,
                                                                  child: Text(
                                                                    customDocuments[
                                                                            key]!
                                                                        .name,
                                                                    style: CustomTextStyle
                                                                        .documentTextStyle,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .close),
                                                                  onPressed: () =>
                                                                      _removeDocument(
                                                                          key),
                                                                ),
                                                              ],
                                                            )
                                                          : IconButton(
                                                              icon: const Icon(Icons
                                                                  .upload_file),
                                                              onPressed: () =>
                                                                  _pickDocument(
                                                                      key),
                                                            ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              InkWell(
                                                onTap: () {
                                                  onPressAddDocument();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  margin: const EdgeInsets.only(
                                                      top: 15),
                                                  decoration: BoxDecoration(
                                                    color: CustomColors
                                                        .forestBrown
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text("+ Add Document",
                                                          style: CustomTextStyle
                                                              .documentTextStyle),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ]),
                                      ),
                                    ],
                                  );
                                } else {
                                  // Mobile Layout: Everything in one Column
                                  return Column(
                                    children: [
                                      CustomFormField(
                                          title: "First Name",
                                          onChanged: (val) => firstName = val,
                                          validator: (val) => val!.isEmpty ? "First Name is required" : null,),
                                      CustomFormField(
                                          title: "Last Name",
                                          onChanged: (val) => lastName = val,
                                          validator: (val) => val!.isEmpty ? "Last Name is required" : null,),
                                      CustomFormField(
                                          title: "Email",
                                          onChanged: (val) => email = val,
                                          validator: (val) {
                                            if (val == null || val.isEmpty) return "Email is required";
                                            if (!val.contains('@')) return "Enter a valid email";
                                            return null;
                                          }),
                                      CustomFormField(
                                          title: "Phone Number",
                                          onChanged: (val) =>
                                              phoneNumber = val,
                                          validator: (val) {
                                            if (val == null || val.isEmpty) return "Phone Number is required";
                                            if (val.length < 10) return "Enter a 10-digit phone number";
                                            return null;
                                          }),
                                      CustomFormField(
                                          title: "Plot Number",
                                          onChanged: (val) => plotNumber = val,
                                          validator: (val) => val!.isEmpty ? "Plot Number is required" : null,),
                                      CustomFormField(
                                          title: "Membership Number",
                                          onChanged: (val) =>
                                              membershipNumber = val,
                                          validator: (val) => val!.isEmpty ? "Membership Number is required" : null,),
                                      const SizedBox(height: 20),

                                      // Corrected Mobile Document Layout:
                                      // Removed the problematic SizedBox with height wrapping ListView.
                                      // The Column below will now directly contain the document items
                                      // and will scroll along with the parent SingleChildScrollView.
                                      Column( // This Column now correctly wraps the document UI elements
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            ...customDocuments.entries
                                                .map((entry) {
                                                String key = entry.key;
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 10),
                                                  margin: const EdgeInsets.only(
                                                      top: 15),
                                                  decoration: BoxDecoration(
                                                    color: CustomColors
                                                        .forestBrown
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(key,
                                                          style: CustomTextStyle
                                                              .documentTextStyle),
                                                      customDocuments[key] != null
                                                          ? Row(
                                                              children: [
                                                                SizedBox(
                                                                  width: 100,
                                                                  child: Text(
                                                                    customDocuments[
                                                                            key]!
                                                                        .name,
                                                                    style: CustomTextStyle
                                                                        .documentTextStyle,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .close),
                                                                  onPressed: () =>
                                                                      _removeDocument(
                                                                          key),
                                                                ),
                                                              ],
                                                            )
                                                          : IconButton(
                                                              icon: const Icon(Icons
                                                                  .upload_file),
                                                              onPressed: () =>
                                                                  _pickDocument(
                                                                      key),
                                                            ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              InkWell(
                                                onTap: () {
                                                  onPressAddDocument();
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 10),
                                                  margin: const EdgeInsets.only(
                                                      top: 15),
                                                  decoration: BoxDecoration(
                                                    color: CustomColors
                                                        .forestBrown
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Text("+ Add Document",
                                                          style: CustomTextStyle
                                                              .documentTextStyle),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ], // End of children for Column
                                          ), // End of Column for mobile documents
                                    ], // End of children for mobile main Column
                                  ); // End of mobile main Column
                                }
                              },
                            ),
                          ],
                        ),
                      )),
                ),
                if (state.isLoading) const Center(child: UploadingModal())
              ],
            ),
          );
        },
      ),
    );
  }
}