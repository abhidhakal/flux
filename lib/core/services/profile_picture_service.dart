import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePictureService {
  static final ProfilePictureService _instance = ProfilePictureService._internal();
  factory ProfilePictureService() => _instance;
  ProfilePictureService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _profileImage;
  static const String _profileImagePathKey = 'profile_image_path';

  File? get profileImage => _profileImage;

  Future<void> setProfileImage(File? image, {required String userId}) async {
    _profileImage = image;
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImagePathKey, image.path);
      
      // Save to Firestore as Base64
      try {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        await _firestore.collection('users').doc(userId).update({
          'profileImageBase64': base64String,
        });
      } catch (e) {
        debugPrint('Error saving profile image to Firestore: $e');
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileImagePathKey);
      
      // Remove from Firestore
      try {
         await _firestore.collection('users').doc(userId).update({
          'profileImageBase64': FieldValue.delete(),
        });
      } catch (e) {
        debugPrint('Error removing profile image from Firestore: $e');
      }
    }
  }

  Future<void> loadProfileImage({required String userId}) async {
    // 1. Try loading from Firestore (Source of Truth)
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('profileImageBase64')) {
        final base64String = doc.data()!['profileImageBase64'] as String;
        if (base64String.isNotEmpty) {
           final bytes = base64Decode(base64String);
           final tempDir = await getTemporaryDirectory();
           final file = File('${tempDir.path}/profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
           await file.writeAsBytes(bytes);
           _profileImage = file;
           
           // Update local cache
           final prefs = await SharedPreferences.getInstance();
           await prefs.setString(_profileImagePathKey, file.path);
           return;
        }
      }
    } catch (e) {
      debugPrint('Error loading profile image from Firestore: $e');
    }

    // 2. Fallback to local cache if Firestore failed or empty
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(_profileImagePathKey);
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
    } else {
      _profileImage = null;
    }
  }

  Future<void> removeProfileImage({required String userId}) async {
    await setProfileImage(null, userId: userId);
  }

  Widget buildProfileAvatar({
    required String? displayName,
    required ColorScheme colorScheme,
    double radius = 25,
  }) {
    if (_profileImage != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primary,
        backgroundImage: FileImage(_profileImage!),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primary,
        child: Text(
          (displayName?.isNotEmpty == true) ? displayName![0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
      );
    }
  }
}
