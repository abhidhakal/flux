import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/services/subscription_service.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object> get props => [];
}

class SubscriptionCheckRequested extends SubscriptionEvent {}

class SubscriptionPurchaseRequested extends SubscriptionEvent {
  final ProductDetails productDetails;

  const SubscriptionPurchaseRequested(this.productDetails);

  @override
  List<Object> get props => [productDetails];
}

class SubscriptionRestoreRequested extends SubscriptionEvent {}

class SubscriptionUpdated extends SubscriptionEvent {
  final bool isPremium;

  const SubscriptionUpdated(this.isPremium);

  @override
  List<Object> get props => [isPremium];
}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionPremium extends SubscriptionState {}

class SubscriptionFree extends SubscriptionState {
  final List<ProductDetails> products;

  const SubscriptionFree(this.products);

  @override
  List<Object> get props => [products];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionService _subscriptionService;
  late StreamSubscription<bool> _purchaseSubscription;

  SubscriptionBloc({required SubscriptionService subscriptionService})
      : _subscriptionService = subscriptionService,
        super(SubscriptionInitial()) {
    on<SubscriptionCheckRequested>(_onCheckRequested);
    on<SubscriptionPurchaseRequested>(_onPurchaseRequested);
    on<SubscriptionRestoreRequested>(_onRestoreRequested);
    on<SubscriptionUpdated>(_onSubscriptionUpdated);

    _purchaseSubscription = _subscriptionService.purchaseStream.listen((isPremium) {
      add(SubscriptionUpdated(isPremium));
    });
  }

  Future<void> _onCheckRequested(
    SubscriptionCheckRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      await _subscriptionService.initialize();
      if (_subscriptionService.isPremium) {
        emit(SubscriptionPremium());
      } else {
        emit(SubscriptionFree(_subscriptionService.products));
      }
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onPurchaseRequested(
    SubscriptionPurchaseRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await _subscriptionService.buyProduct(event.productDetails);
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onRestoreRequested(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      await _subscriptionService.restorePurchases();
      // The stream listener will handle the update if restore is successful
      // But if it fails or returns nothing, we might need to re-emit the current state
      // For now, let's assume the stream will fire if something changes.
      // If not, we might want to check status again.
      await Future.delayed(const Duration(seconds: 2)); // Give it some time
      if (_subscriptionService.isPremium) {
        emit(SubscriptionPremium());
      } else {
        emit(SubscriptionFree(_subscriptionService.products));
      }
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  void _onSubscriptionUpdated(
    SubscriptionUpdated event,
    Emitter<SubscriptionState> emit,
  ) {
    if (event.isPremium) {
      emit(SubscriptionPremium());
    } else {
      emit(SubscriptionFree(_subscriptionService.products));
    }
  }

  @override
  Future<void> close() {
    _purchaseSubscription.cancel();
    return super.close();
  }
}
