import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lokconnect/features/user_addition/bloc/user_addition_bloc.dart';
import 'dart:io' show File; // For non-web platforms
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserAdditionForm extends StatelessWidget {
  final List<String> documentFields = [
    "Lease Deed",
    "Nomination Form",
    "Member Application Form",
    "Sale Purchase Documents",
    "Legal Documents",
    "Aadhar, Pan etc",
    "Other & Communication Documents",
  ];

  final List<String> mandatoryFields = [
    "Lease Deed",
    "Nomination Form",
    "Member Application Form",
    "Other & Communication Documents"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Documents")),
      body: BlocConsumer<UserAdditionBloc, UserAdditionState>(
        listener: (context, state) {
          // Optional: Handle Snackbars or messages here
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: documentFields.map((field) {
              return _buildDocumentField(
                context, 
                field, 
                state.uploadedDocuments[field],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDocumentField(BuildContext context, String field, dynamic file) {
    bool isMandatory = mandatoryFields.contains(field);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          field,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: isMandatory ? Colors.red : Colors.black,
          ),
        ),
        subtitle: file != null 
            ? Text("Uploaded: ${kIsWeb ? file['name'] : (file as File).path.split('/').last}")
            : null,
        trailing: file != null
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => context.read<UserAdditionBloc>().add(
                  RemoveDocument(field: field),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.upload_file, color: Colors.blue),
                onPressed: () => _pickAndUploadFile(context, field),
              ),
      ),
    );
  }

void _pickAndUploadFile(BuildContext context, String field) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom, 
    allowedExtensions: ['pdf', 'jpg', 'png'],
    withData: kIsWeb, // Needed for Web
  );

  if (result != null) {
    if (kIsWeb) {
      // Web: Use `bytes` instead of `path`
      Uint8List? fileBytes = result.files.single.bytes;
      String fileName = result.files.single.name;

      if (fileBytes != null) {
        context.read<UserAdditionBloc>().add(
          UploadDocument(field: field, file: File({ 'name': fileName, 'bytes': fileBytes }.toString()) ),
        );
      }
    } else {
      // Mobile: Use `File(path!)`
      File file = File(result.files.single.path!);
      context.read<UserAdditionBloc>().add(UploadDocument(field: field, file: file));
    }
  }
}

}
