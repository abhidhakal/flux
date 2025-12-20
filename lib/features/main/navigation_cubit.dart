import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class TabChanged extends NavigationEvent {
  final int index;

  const TabChanged(this.index);

  @override
  List<Object?> get props => [index];
}

// States
class NavigationState extends Equatable {
  final int currentIndex;

  const NavigationState(this.currentIndex);

  @override
  List<Object?> get props => [currentIndex];
}

// Cubit
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState(0));

  void setTab(int index) => emit(NavigationState(index));
}
