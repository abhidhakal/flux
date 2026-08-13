import 'package:shared_preferences/shared_preferences.dart';

/// Stores lightweight per-user onboarding progress locally.
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  String _key(String userId) => 'onboarding_completed_$userId';

  Future<bool> isComplete(String userId) async {
    return (await _prefs).getBool(_key(userId)) ?? false;
  }

  Future<void> markComplete(String userId) async {
    await (await _prefs).setBool(_key(userId), true);
  }

  Future<void> reset(String userId) async {
    await (await _prefs).remove(_key(userId));
  }
}
