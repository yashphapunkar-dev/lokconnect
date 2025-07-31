import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
part 'user_addition_event.dart';
part 'user_addition_state.dart';

class UserAdditionBloc extends Bloc<UserAdditionEvent, UserAdditionState> {
  final FirebaseStorage storage;
  final FirebaseFirestore firestore;

  UserAdditionBloc({required this.storage, required this.firestore})
      : super(UserAdditionState()) {
    on<UploadDocument>(_onUploadDocument);
    on<RemoveDocument>(_onRemoveDocument);
    on<SubmitUserForm>(_onSubmitUserForm);
  }

  Future<void> _onUploadDocument(
      UploadDocument event, Emitter<UserAdditionState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      String fileName = event.file.name;
      Uint8List? fileBytes = event.file.bytes;

      if (fileBytes == null) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      Reference ref = storage.ref().child("documents/$fileName");
      await ref.putData(
        fileBytes,
      );

      emit(state.copyWith(
        uploadedDocuments: {
          ...state.uploadedDocuments,
          event.field: event.file,
        },
        isLoading: false,
      ));
    } catch (e) {
      print("Error uploading file: $e");
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onRemoveDocument(
      RemoveDocument event, Emitter<UserAdditionState> emit) {
    final newDocs = Map<String, PlatformFile>.from(state.uploadedDocuments);
    newDocs.remove(event.field);
    emit(state.copyWith(uploadedDocuments: newDocs));
  }



  Future<void> _onSubmitUserForm(
      SubmitUserForm event, Emitter<UserAdditionState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final String fullPhoneNumber = "+91${event.phoneNumber}";
      Map<String, String> documentUrls = {};
      String? profilePictureUrl;

      // 1. Upload Documents and Profile Picture
      for (var entry in event.documents.entries) {
        final String fieldName = entry.key;
        final dynamic file = entry.value;

        if (file is PlatformFile && file.bytes != null) {
          final Uint8List fileBytes = file.bytes!;
          final String fileExtension = file.extension ?? 'bin'; // Default to bin if no extension
          String contentType;

          // Determine content type based on fieldName or file extension
          if (fieldName == "Profile Picture") {
            // Infer image type from extension
            if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
              contentType = 'image/jpeg';
            } else if (fileExtension == 'png') {
              contentType = 'image/png';
            } else if (fileExtension == 'gif') {
              contentType = 'image/gif';
            } else {
              // Fallback for unknown image types or if field is "Profile Picture" but file type is not standard image
              contentType = 'application/octet-stream'; // Generic binary
              print("Warning: Profile Picture has unexpected extension: $fileExtension. Uploading as octet-stream.");
            }
          } else if (fileExtension == 'pdf') {
            contentType = 'application/pdf';
          } else {
            // Fallback for other document types or if type is not recognized
            contentType = 'application/octet-stream';
            print("Warning: Document '$fieldName' has unexpected extension: $fileExtension. Uploading as octet-stream.");
          }


          final Reference ref = storage.ref().child("documents/${fullPhoneNumber}_${fieldName}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension");

          final UploadTask uploadTask = ref.putData(
            fileBytes,
            SettableMetadata(
              contentType: contentType,
              contentDisposition: fieldName == "Profile Picture" ? 'inline' : 'attachment', // Profile picture inline, docs attachment
            ),
          );

          final TaskSnapshot snapshot = await uploadTask;
          final String downloadUrl = await snapshot.ref.getDownloadURL();

          if (fieldName == "Profile Picture") {
            profilePictureUrl = downloadUrl;
          } else {
            documentUrls[fieldName] = downloadUrl;
          }
        } else {
          print("Warning: File for $fieldName is not a valid PlatformFile or has no bytes.");
        }
      }

      // 2. Check for Existing User
      CollectionReference usersRef = firestore.collection("users");
      QuerySnapshot querySnapshot = await usersRef
          .where("phoneNumber", isEqualTo: fullPhoneNumber)
          .get();

      // 3. Update or Add User Data
      final Map<String, dynamic> userData = {
        "firstName": event.firstName,
        "lastName": event.lastName,
        "email": event.email,
        "profilePicture": profilePictureUrl ?? '', // Ensure it's not null
        "plotNumber": event.plotNumber,
        "membershipNumber": event.membershipNumber,
        "documents": documentUrls, // Other documents
      };

      if (querySnapshot.docs.isNotEmpty) {
        DocumentReference existingUserDoc = querySnapshot.docs.first.reference;
        await existingUserDoc.update({
          ...userData, // Spread existing data
          "verified": false, 
          "aprooved": false, // Keep aprooved false on update, if intent is to re-approve
          "updatedAt": FieldValue.serverTimestamp(),
        });
      } else {
        // Add new user
        await usersRef.add({
          ...userData, // Spread existing data
          "phoneNumber": fullPhoneNumber, // Add phone number only for new users
          "verified": false, // New users are initially not verified
          "aprooved": false, // New users are initially not approved
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      emit(UserAdditionState()); // Indicate success
    } catch (e) {
      print("Error submitting form: $e");
      emit(state.copyWith(isLoading: false)); // Add error message to state
    }
  }
}

  // Future<void> _onSubmitUserForm(
  //     SubmitUserForm event, Emitter<UserAdditionState> emit) async {
  //   emit(state.copyWith(isLoading: true));

  //   try {
  //     Map<String, String> documentUrls = {};

  //     CollectionReference usersRef = firestore.collection("users");
  //     QuerySnapshot querySnapshot = await usersRef
  //         .where("phoneNumber", isEqualTo: "+91${event.phoneNumber}")
  //         .get();

  //     for (var entry in event.documents.entries) {
  //       final String fieldName = entry.key;
  //       final dynamic file = entry.value;

  //       if (file is PlatformFile && file.bytes != null) {
  //         final String fileName = file.name;
  //         final Uint8List fileBytes = file.bytes!;

  //         final Reference ref = storage.ref().child("documents/$fileName");
  //         await ref.putData(
  //           fileBytes,
  //           SettableMetadata(
  //             contentType: 'application/pdf',
  //             contentDisposition: 'inline',
  //           ),
  //         );

  //         final String downloadUrl = await ref.getDownloadURL();
  //         documentUrls[fieldName] = downloadUrl;
  //       }
  //     }

  //     String? profilePictureUrl;
  //     if (documentUrls.containsKey("Profile Picture")) {
  //       profilePictureUrl = documentUrls["Profile Picture"];
  //       documentUrls.remove("Profile Picture");
  //     }

  //     if (querySnapshot.docs.isNotEmpty) {
  //       DocumentReference existingUserDoc = querySnapshot.docs.first.reference;
  //       await existingUserDoc.update({
  //         "firstName": event.firstName,
  //         "profilePicture": profilePictureUrl ?? '',
  //         "lastName": event.lastName,
  //         "email": event.email,
  //         "plotNumber": event.plotNumber,
  //         "membershipNumber": event.membershipNumber,
  //         "documents": documentUrls,
  //         "verified": false,
  //         "aprooved": false,
  //         "updatedAt": FieldValue.serverTimestamp(),
  //       });
  //     } else {
  //       await usersRef.add({
  //         "firstName": event.firstName,
  //         "lastName": event.lastName,
  //         "email": event.email,
  //         "profilePicture": profilePictureUrl ?? '',
  //         "phoneNumber": event.phoneNumber,
  //         "plotNumber": event.plotNumber,
  //         "membershipNumber": event.membershipNumber,
  //         "documents": documentUrls,
  //         "aprooved": false,
  //         "createdAt": FieldValue.serverTimestamp(),
  //       });
  //     }

  //     emit(UserAdditionState());
  //   } catch (e) {
  //     print("Error submitting form: $e");
  //     emit(state.copyWith(isLoading: false));
  //   }
  // }



// }
