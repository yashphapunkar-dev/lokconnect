// lib/services/profile_picture_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // For web detection
import 'package:path/path.dart' as p; // For path operations

class ProfilePictureService {
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  ProfilePictureService({
    required FirebaseStorage storage,
    required FirebaseFirestore firestore,
  })  : _storage = storage,
        _firestore = firestore;

  // --- Upload Profile Picture ---
   Future<String> uploadProfilePicture({
    File? imageFile, // For mobile: Pass the dart:io.File
    Uint8List? imageBytes, // For web: Pass the raw bytes
    String? fileName, // Required for web uploads to get original extension
    required String userId,
  }) async {
    try {
      // Input validation based on platform
      if (kIsWeb) {
        if (imageBytes == null || fileName == null) {
          throw ArgumentError("For web, imageBytes and fileName must be provided.");
        }
      } else {
        if (imageFile == null) {
          throw ArgumentError("For non-web platforms, imageFile must be provided.");
        }
      }

      final String originalFileName = kIsWeb ? fileName! : p.basename(imageFile!.path);
      final String fileExtension = p.extension(originalFileName).toLowerCase();

      // Generate a unique file name using user ID and timestamp
      // It's safer to include the original file extension as well
      final String uniqueFileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      // Store directly under user's UID to easily retrieve/manage their single profile picture
      final String storagePath = "profile_pictures/$userId/$uniqueFileName";

      final Reference storageRef = _storage.ref().child(storagePath);

      // Determine content type
      String contentType = 'application/octet-stream';
      if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == '.png') {
        contentType = 'image/png';
      } else if (fileExtension == '.gif') {
        contentType = 'image/gif';
      } else if (fileExtension == '.webp') {
        contentType = 'image/webp';
      }

      UploadTask uploadTask;
      if (kIsWeb) {
        // For web, upload raw bytes
        uploadTask = storageRef.putData(
          imageBytes!, // Use the provided bytes
          SettableMetadata(contentType: contentType),
        );
      } else {
        // For mobile/desktop, upload the file directly
        uploadTask = storageRef.putFile(
          imageFile!, // Use the provided File object
          SettableMetadata(contentType: contentType),
        );
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore document with the new download URL
      await _firestore.collection('users').doc(userId).set(
        { 'profilePicture': downloadUrl },
        SetOptions(merge: true), // Merge to only update the profilePicture field
      );

      return downloadUrl; // Return the new URL
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow; // Re-throw the error for the UI to handle
    }
  }

  // --- Delete Profile Picture ---
  Future<void> deleteProfilePicture({
    required String userId,
    required String? imageUrl, // Pass the current URL for deletion
  }) async {
    try {
      // 1. Delete from Firebase Storage (if a picture exists)
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Use refFromURL to get the correct storage reference
          Reference storageRef = _storage.refFromURL(imageUrl);
          await storageRef.delete();
        } on FirebaseException catch (e) {
          // If file doesn't exist in storage (e.g., already deleted manually,
          // or never uploaded properly), we can still proceed to clear Firestore.
          // 'object-not-found' (Firebase Storage specific code for missing file)
          if (e.code == 'object-not-found') {
            print("Profile picture not found in Storage, proceeding to clear Firestore: ${e.message}");
          } else {
            rethrow; // Re-throw other storage errors
          }
        }
      }

      // 2. Set profilePicture field to null (or delete it) in Firestore
      // Using FieldValue.delete() is cleaner as it removes the field entirely.
      await _firestore.collection('users').doc(userId).set(
        { 'profilePicture': FieldValue.delete() },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error deleting profile picture: $e');
      rethrow; // Re-throw the error for the UI to handle
    }
  }

}