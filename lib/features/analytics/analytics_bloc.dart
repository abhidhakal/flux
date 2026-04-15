import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/ai_intelligence_service.dart';

// Events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeSpendingPatterns extends AnalyticsEvent {
  final List<Transaction> transactions;

  const AnalyzeSpendingPatterns(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class GenerateBudgetRecommendations extends AnalyticsEvent {
  final List<Transaction> transactions;
  final double monthlyIncome;

  const GenerateBudgetRecommendations({
    required this.transactions,
    required this.monthlyIncome,
  });

  @override
  List<Object?> get props => [transactions, monthlyIncome];
}

class PredictFutureSpending extends AnalyticsEvent {
  final List<Transaction> transactions;

  const PredictFutureSpending(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class CategorizeTransaction extends AnalyticsEvent {
  final String title;
  final String description;

  const CategorizeTransaction({
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [title, description];
}

// States
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class SpendingAnalysisLoaded extends AnalyticsState {
  final Map<String, dynamic> analysis;

  const SpendingAnalysisLoaded(this.analysis);

  @override
  List<Object?> get props => [analysis];
}

class BudgetRecommendationsLoaded extends AnalyticsState {
  final List<BudgetRecommendation> recommendations;

  const BudgetRecommendationsLoaded(this.recommendations);

  @override
  List<Object?> get props => [recommendations];
}

class FutureSpendingPredicted extends AnalyticsState {
  final Map<String, double> predictions;

  const FutureSpendingPredicted(this.predictions);

  @override
  List<Object?> get props => [predictions];
}

class TransactionCategorized extends AnalyticsState {
  final String category;

  const TransactionCategorized(this.category);

  @override
  List<Object?> get props => [category];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AIIntelligenceService _aiService;

  AnalyticsBloc({required AIIntelligenceService aiService})
      : _aiService = aiService,
        super(AnalyticsInitial()) {
    on<AnalyzeSpendingPatterns>(_onAnalyzeSpendingPatterns);
    on<GenerateBudgetRecommendations>(_onGenerateBudgetRecommendations);
    on<PredictFutureSpending>(_onPredictFutureSpending);
    on<CategorizeTransaction>(_onCategorizeTransaction);
  }

  Future<void> _onAnalyzeSpendingPatterns(
    AnalyzeSpendingPatterns event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    
    try {
      final analysis = _aiService.analyzeSpendingPatterns(event.transactions);
      emit(SpendingAnalysisLoaded(analysis));
    } catch (e) {
      emit(AnalyticsError('Failed to analyze spending patterns: $e'));
    }
  }

  Future<void> _onGenerateBudgetRecommendations(
    GenerateBudgetRecommendations event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    
    try {
      final recommendations = _aiService.generateBudgetRecommendations(
        event.transactions,
        event.monthlyIncome,
      );
      emit(BudgetRecommendationsLoaded(recommendations));
    } catch (e) {
      emit(AnalyticsError('Failed to generate budget recommendations: $e'));
    }
  }

  Future<void> _onPredictFutureSpending(
    PredictFutureSpending event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    
    try {
      final predictions = _aiService.predictFutureSpending(event.transactions);
      emit(FutureSpendingPredicted(predictions));
    } catch (e) {
      emit(AnalyticsError('Failed to predict future spending: $e'));
    }
  }

  Future<void> _onCategorizeTransaction(
    CategorizeTransaction event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    
    try {
      final category = _aiService.categorizeTransaction(
        event.title,
        event.description,
      );
      emit(TransactionCategorized(category));
    } catch (e) {
      emit(AnalyticsError('Failed to categorize transaction: $e'));
    }
  }
}
