import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ThemeChanged extends ThemeEvent {
  final ThemeMode themeMode;

  const ThemeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class ThemeLoadRequested extends ThemeEvent {}

// States
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final ThemeMode themeMode;

  const ThemeLoaded(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

// BLoC
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'theme_mode';

  ThemeBloc() : super(ThemeInitial()) {
    on<ThemeLoadRequested>(_onThemeLoadRequested);
    on<ThemeChanged>(_onThemeChanged);
  }

  Future<void> _onThemeLoadRequested(
    ThemeLoadRequested event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedIndex = prefs.getInt(_themeKey);
      if (storedIndex == null) {
        // First run: default to Light and persist it
        await prefs.setInt(_themeKey, ThemeMode.light.index);
        emit(const ThemeLoaded(ThemeMode.light));
        return;
      }
      final themeMode = ThemeMode.values[storedIndex];
      emit(ThemeLoaded(themeMode));
    } catch (e) {
      // Default to light theme if loading fails
      emit(const ThemeLoaded(ThemeMode.light));
    }
  }

  Future<void> _onThemeChanged(
    ThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, event.themeMode.index);
      emit(ThemeLoaded(event.themeMode));
    } catch (e) {
      // Still emit the state even if saving fails
      emit(ThemeLoaded(event.themeMode));
    }
  }
}
