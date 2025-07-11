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
      await ref.putData(fileBytes, );

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
      Map<String, String> documentUrls = {};

      CollectionReference usersRef = firestore.collection("users");
      QuerySnapshot querySnapshot = await usersRef
          .where("phoneNumber", isEqualTo: "+91${event.phoneNumber}")
          .get();

      for (var entry in event.documents.entries) {
        final String fieldName = entry.key;
        final dynamic file = entry.value;

        if (file is PlatformFile && file.bytes != null) {
          final String fileName = file.name;
          final Uint8List fileBytes = file.bytes!;

          final Reference ref = storage.ref().child("documents/$fileName");
          await ref.putData(fileBytes,
           SettableMetadata(
            contentType: 'application/pdf',
            contentDisposition: 'inline', 
          ),
          );

          final String downloadUrl = await ref.getDownloadURL();
          documentUrls[fieldName] = downloadUrl;
        }
      }

      if (querySnapshot.docs.isNotEmpty) {
        DocumentReference existingUserDoc = querySnapshot.docs.first.reference;
        await existingUserDoc.update({
          "firstName": event.firstName,
          "lastName": event.lastName,
          "email": event.email,
          "plotNumber": event.plotNumber,
          "membershipNumber": event.membershipNumber,
          "documents": documentUrls,
          "verified": false,
          "aprooved": false,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      } else {
        await usersRef.add({
          "firstName": event.firstName,
          "lastName": event.lastName,
          "email": event.email,
          "phoneNumber": event.phoneNumber,
          "plotNumber": event.plotNumber,
          "membershipNumber": event.membershipNumber,
          "documents": documentUrls,
          "aprooved": false,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      emit(UserAdditionState());
    } catch (e) {
      print("Error submitting form: $e");
      emit(state.copyWith(isLoading: false));
    }
  }
}
