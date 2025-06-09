import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/home/ui/home.dart';
import 'package:lokconnect/features/user_addition/bloc/user_addition_bloc.dart';
import 'package:lokconnect/widgets/FormField.dart';
import 'package:lokconnect/widgets/custom_button.dart';

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

  void onPressAddDocument() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newDocName = '';

        return AlertDialog(
          title: Text("Enter Document Name"),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: "e.g. Driving License"),
            onChanged: (value) {
              newDocName = value;
            },
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text("Add"),
              onPressed: () {
                if (newDocName.trim().isNotEmpty) {
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

  Map<String, dynamic> customDocuments = {};

  final Map<String, PlatformFile> selectedDocuments = {};

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
        SnackBar(
            content: Text(
                "Please fill all required fields and upload required documents")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: CustomColors.primaryColor,
        padding: EdgeInsets.only(top: 10),
        child: CustomButton(buttonText: "Submit", onPress: _submitForm,),
      ),
      backgroundColor: CustomColors.oceanBlue,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "User Addition",
          style: CustomTextStyle.headingTextStyle,
        ),
        backgroundColor: CustomColors.oceanBlue,
      ),
      body: BlocConsumer<UserAdditionBloc, UserAdditionState>(
        listener: (context, state) {
          if (!state.isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("User added successfully!")));
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => Home()));
          }
        },
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
                color: CustomColors.primaryColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40))),
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height,
                  child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWideScreen =
                                    kIsWeb && constraints.maxWidth > 800;

                                if (isWideScreen) {
                                  return Expanded(
                                    child: Row(
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
                                                      firstName = val),
                                              CustomFormField(
                                                  title: "Last Name",
                                                  onChanged: (val) =>
                                                      lastName = val),
                                              CustomFormField(
                                                  title: "Membership Number",
                                                  onChanged: (val) =>
                                                      membershipNumber = val),
                                              CustomFormField(
                                                  title: "Email",
                                                  onChanged: (val) =>
                                                      email = val),
                                              CustomFormField(
                                                  title: "Phone Number",
                                                  onChanged: (val) =>
                                                      phoneNumber = val),
                                              CustomFormField(
                                                  title: "Plot Number",
                                                  onChanged: (val) =>
                                                      plotNumber = val),
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
                                                  // var value = entry.value;
                                                  return Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 10),
                                                    margin:
                                                        const EdgeInsets.only(
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
                                                        Row(
                                                          children: [
                                                            Text(key,
                                                                style: CustomTextStyle
                                                                    .documentTextStyle),
                                                          ],
                                                        ),
                                                        customDocuments[key] !=
                                                                null
                                                            // true
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
                                                                icon: const Icon(
                                                                    Icons
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
                                                  child: 
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 10),
                                                    margin:
                                                        const EdgeInsets.only(
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
                                                              .center,
                                                      children: [
                                                        Text("+ Add Document",
                                                            style: CustomTextStyle
                                                                .documentTextStyle),
                                                      ],
                                                    ),
                                                  ),
                                                ),     
                                              ]
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  // Mobile Layout: Everything in one Column
                                  return Column(
                                    children: [
                                      CustomFormField(
                                          title: "First Name",
                                          onChanged: (val) => firstName = val),
                                      CustomFormField(
                                          title: "Last Name",
                                          onChanged: (val) => lastName = val),
                                      CustomFormField(
                                          title: "Email",
                                          onChanged: (val) => email = val),
                                      CustomFormField(
                                          title: "Phone Number",
                                          onChanged: (val) =>
                                              phoneNumber = val),
                                      CustomFormField(
                                          title: "Plot Number",
                                          onChanged: (val) => plotNumber = val),
                                      const SizedBox(height: 20),
                                    ],
                                  );
                                }
                              },
                            ),
                            // const SizedBox(height: 20),
                            // CustomButton(
                            //   onPress: _submitForm,
                            //   buttonText: "Submit",
                            // ),
                          ],
                        ),
                      )),
                ),
                if (state.isLoading) Center(child: CircularProgressIndicator())
              ],
            ),
          );
        },
      ),
    );
  }
}
