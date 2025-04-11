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

  final List<String> requiredDocs = [
    "Lease Deed*",
    "Nomination Form*",
    "Member Application Form*",
    "Other & Communication Documents*"
  ];

  final List<String> optionalDocs = [
    "Sale Purchase Documents",
    "Legal Documents",
    "Aadhar, Pan etc"
  ];

  final Map<String, PlatformFile> selectedDocuments = {};

  void _pickDocument(String field) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);

    if (result != null) {
      PlatformFile file = result.files.single;
      setState(() {
        selectedDocuments[field] = file;
      });
    }
  }

  void _removeDocument(String field) {
    setState(() {
      selectedDocuments.remove(field);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() &&
        requiredDocs.every((doc) => selectedDocuments.containsKey(doc))) {
      BlocProvider.of<UserAdditionBloc>(context).add(
        SubmitUserForm(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          plotNumber: plotNumber,
          documents: selectedDocuments,
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
      backgroundColor: CustomColors.primaryColor,
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: () => Navigator.of(context).pop(),),
        title: Text(
          "User Addition",
          style: CustomTextStyle.headingTextStyle,
        ),
        backgroundColor: CustomColors.dustyRose,
      ),
      body: BlocConsumer<UserAdditionBloc, UserAdditionState>(
        listener: (context, state) {
          if (!state.isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("User added successfully!")));
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => Home()));    
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomFormField(
                        title: "First Name",
                        onChanged: (val) => firstName = val,
                      ),

                      CustomFormField(
                        title: "Last Name",
                        onChanged: (val) => lastName = val,
                      ),

                      CustomFormField(
                        title: "Email",
                        onChanged: (val) => email = val,
                      ),

                      CustomFormField(
                        title: "Phone Number",
                        onChanged: (val) => phoneNumber = val,
                      ),

                      CustomFormField(
                        title: "Plot Number",
                        onChanged: (val) => plotNumber = val,
                      ),
                      SizedBox(height: 20),
                      ...[
                        ...requiredDocs,
                        ...optionalDocs
                      ].map((doc) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            margin: EdgeInsets.only(top: 15),
                            decoration: BoxDecoration(color: CustomColors.rosePink.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(doc, style: CustomTextStyle.documentTextStyle,),
                                selectedDocuments.containsKey(doc)
                                    ? Row(
                                        children: [
                                          Text(selectedDocuments[doc]!.name, style: CustomTextStyle.documentTextStyle,),
                                          IconButton(
                                              icon: Icon(Icons.close),
                                              onPressed: () =>
                                                  _removeDocument(doc)),
                                        ],
                                      )
                                    : IconButton(
                                        icon: Icon(Icons.upload_file),
                                        onPressed: () => _pickDocument(doc)),
                              ],
                            ),
                          )),
                      SizedBox(height: 20),
                      CustomButton(
                        onPress: _submitForm,
                        buttonText: "Submit",
                      )
                    ],
                  ),
                ),
              ),
              if (state.isLoading) Center(child: CircularProgressIndicator())
            ],
          );
        },
      ),
    );
  }
}
