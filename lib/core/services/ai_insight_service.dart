import 'package:cloud_functions/cloud_functions.dart';

import '../models/ai_financial_context.dart';

class AiInsightResult {
  final String title;
  final String summary;
  final List<AiInsightAction> actions;
  final String caution;

  const AiInsightResult({
    required this.title,
    required this.summary,
    required this.actions,
    required this.caution,
  });

  factory AiInsightResult.fromJson(Map<String, dynamic> json) {
    if (json['title'] is! String ||
        json['summary'] is! String ||
        json['actions'] is! List ||
        json['caution'] is! String) {
      throw const FormatException('Invalid AI insight response');
    }

    final actions = (json['actions'] as List<dynamic>)
        .whereType<Map>()
        .take(2)
        .map((action) => AiInsightAction.fromJson(
              Map<String, dynamic>.from(action),
            ))
        .toList();

    final title = json['title'] as String;
    final summary = json['summary'] as String;
    final caution = json['caution'] as String;
    if (title.length > 120 || summary.length > 1000 || caution.length > 500) {
      throw const FormatException('AI insight response is too long');
    }

    return AiInsightResult(
      title: title,
      summary: summary,
      actions: actions,
      caution: caution,
    );
  }
}

class AiInsightAction {
  final String label;
  final String reason;

  const AiInsightAction({required this.label, required this.reason});

  factory AiInsightAction.fromJson(Map<String, dynamic> json) {
    if (json['label'] is! String || json['reason'] is! String) {
      throw const FormatException('Invalid AI insight action');
    }
    return AiInsightAction(
      label: json['label'] as String,
      reason: json['reason'] as String,
    );
  }
}

/// Client boundary for the future remote AI feature.
///
/// The callable is intentionally not invoked by the UI until explicit user
/// consent and the server secret are configured. Local insights remain the
/// offline fallback.
class AiInsightService {
  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(
        region: 'us-central1',
      );

  Future<AiInsightResult> generate(AiFinancialContext context) async {
    final callable = _functions.httpsCallable(
      'generateFinancialInsight',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 35)),
    );
    final response = await callable.call({'context': context.toJson()});
    final data = Map<String, dynamic>.from(response.data as Map);
    return AiInsightResult.fromJson(data);
  }
}
