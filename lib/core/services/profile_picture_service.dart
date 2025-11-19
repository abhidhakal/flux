import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePictureService {
  static final ProfilePictureService _instance = ProfilePictureService._internal();
  factory ProfilePictureService() => _instance;
  ProfilePictureService._internal();

  File? _profileImage;
  static const String _profileImagePathKey = 'profile_image_path';

  File? get profileImage => _profileImage;

  Future<void> setProfileImage(File? image) async {
    _profileImage = image;
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImagePathKey, image.path);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileImagePathKey);
    }
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(_profileImagePathKey);
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
    } else {
      _profileImage = null;
    }
  }

  Future<void> removeProfileImage() async {
    _profileImage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileImagePathKey);
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
