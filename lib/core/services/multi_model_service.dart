import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:student_buddy/core/secrets/app_secrets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration for each AI model
class ModelConfig {
  final String id;
  final String name;
  final String baseUrl;
  final String modelName;
  final Map<String, String> headers;
  final String role; // 'analyzer', 'expert', 'tutor'

  const ModelConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.modelName,
    required this.headers,
    required this.role,
  });
}

/// Result from a single model
class ModelResponse {
  final String modelId;
  final String modelName;
  final String content;
  final Duration responseTime;
  final bool isError;

  const ModelResponse({
    required this.modelId,
    required this.modelName,
    required this.content,
    required this.responseTime,
    this.isError = false,
  });
}

/// Combined result from multi-model orchestration
class MultiModelResult {
  final String finalAnswer;
  final List<ModelResponse> individualResponses;
  final String synthesisMethod;

  const MultiModelResult({
    required this.finalAnswer,
    required this.individualResponses,
    required this.synthesisMethod,
  });
}

/// Callback for real-time status updates
typedef StatusCallback = void Function(String modelName, String status);

/// Multi-Model AI Service
/// Orchestrates 3 models for higher-quality educational responses:
///   1. LM Studio — Llama 3.1 8B Instruct (local, fast tutor & synthesizer)
///   2. LM Studio — Mistral 7B Instruct (local, alternative reasoning)
///   3. DeepSeek  — Deep reasoning for complex academic questions (remote)
class MultiModelService {
  final String _systemInstruction;
  final StatusCallback? onStatusUpdate;

  // Cache for the LM Studio URL
  static String? _cachedLmStudioUrl;
  static DateTime? _lastFetchTime;
  static const String _defaultLmStudioUrl =
      'http://10.0.2.2:1234/v1/chat/completions';

  MultiModelService({
    String? systemInstruction,
    this.onStatusUpdate,
  }) : _systemInstruction = systemInstruction ??
            'You are an expert AI Mentor for StudentBuddy. '
                'Help students understand academic concepts clearly. '
                'Use simple language, real-world examples, and step-by-step reasoning. '
                'Keep responses concise and formatted for a mobile chat interface.';

  // ─── Model Configurations ───

  /// Model 1: Llama 3.1 8B — Primary tutor & synthesizer
  Future<ModelConfig> get _llamaConfig async {
    final url = await _getLmStudioUrl();
    return ModelConfig(
      id: 'llama',
      name: 'Llama 3.1',
      baseUrl: url,
      modelName: 'meta-llama-3.1-8b-instruct',
      headers: {'Content-Type': 'application/json'},
      role: 'tutor',
    );
  }

  /// Model 2: Mistral 7B — Alternative reasoning & cross-check
  Future<ModelConfig> get _mistralConfig async {
    final url = await _getLmStudioUrl();
    return ModelConfig(
      id: 'mistral',
      name: 'Mistral 7B',
      baseUrl: url,
      modelName: 'mistralai/mistral-7b-instruct-v0.3',
      headers: {'Content-Type': 'application/json'},
      role: 'expert',
    );
  }

  /// Model 3: DeepSeek — Remote deep reasoning expert
  ModelConfig get _deepSeekConfig => const ModelConfig(
        id: 'deepseek',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/chat/completions',
        modelName: 'deepseek-chat',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppSecrets.deepSeekApiKey}',
        },
        role: 'expert',
      );

  // ─── LM Studio URL Resolution (Smart 3-tier fallback) ───

  // Fallback URLs in priority order
  static const List<String> _fallbackUrls = [
    'http://10.253.130.19:1234/v1/chat/completions', // Local network (your PC IP)
    'http://10.0.2.2:1234/v1/chat/completions',      // Android Emulator
  ];

  Future<String> _getLmStudioUrl() async {
    // Return cached URL if still fresh (5 min)
    if (_cachedLmStudioUrl != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
      return _cachedLmStudioUrl!;
    }

    // Tier 1: Try ngrok URL from Supabase
    try {
      final response = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'ai_mentor_url')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        String url = response['value'].toString();
        if (!url.endsWith('/v1/chat/completions')) {
          url = url.endsWith('/')
              ? '${url}v1/chat/completions'
              : '$url/v1/chat/completions';
        }

        // Validate that the ngrok tunnel is actually alive
        final isAlive = await _pingUrl(url);
        if (isAlive) {
          debugPrint("MultiModel: Ngrok URL is alive: $url");
          _cachedLmStudioUrl = url;
          _lastFetchTime = DateTime.now();
          return _cachedLmStudioUrl!;
        } else {
          debugPrint("MultiModel: Ngrok URL is dead, trying fallbacks...");
        }
      }
    } catch (e) {
      debugPrint("MultiModel: Error fetching Supabase URL: $e");
    }

    // Tier 2 & 3: Try local network IP, then emulator
    for (final fallback in _fallbackUrls) {
      final isAlive = await _pingUrl(fallback);
      if (isAlive) {
        debugPrint("MultiModel: Fallback URL alive: $fallback");
        _cachedLmStudioUrl = fallback;
        _lastFetchTime = DateTime.now();
        return fallback;
      }
    }

    // Final fallback: return default and let the call fail gracefully
    debugPrint("MultiModel: No reachable LM Studio URL. Using default.");
    return _defaultLmStudioUrl;
  }

  /// Lightweight check to see if an LM Studio URL is actually reachable.
  /// Uses /v1/models endpoint (much lighter than a full chat call).
  Future<bool> _pingUrl(String chatUrl) async {
    try {
      // Convert chat completions URL to /v1/models for a cheaper ping
      final modelsUrl = chatUrl.replaceAll('/v1/chat/completions', '/v1/models');
      final response = await http.get(
        Uri.parse(modelsUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Single Model Call ───

  Future<ModelResponse> _callModel(
    ModelConfig config,
    String message,
    List<Map<String, dynamic>>? history, {
    String? customSystemPrompt,
    int maxTokens = 512,
    double temperature = 0.4,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onStatusUpdate?.call(config.name, '🤔 Thinking...');

      final messages = <Map<String, dynamic>>[];

      // System prompt
      messages.add({
        'role': 'system',
        'content': customSystemPrompt ?? _systemInstruction,
      });

      // History (last 6 messages for context)
      if (history != null && history.isNotEmpty) {
        final recent =
            history.length > 6 ? history.sublist(history.length - 6) : history;
        messages.addAll(recent);
      }

      // Current message
      messages.add({'role': 'user', 'content': message});

      final response = await http
          .post(
            Uri.parse(config.baseUrl),
            headers: config.headers,
            body: jsonEncode({
              'model': config.modelName,
              'messages': messages,
              'temperature': temperature,
              'max_tokens': maxTokens,
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 45));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['choices'][0]['message']['content'].toString().trim();

        onStatusUpdate?.call(config.name, '✅ Done');
        return ModelResponse(
          modelId: config.id,
          modelName: config.name,
          content: content,
          responseTime: stopwatch.elapsed,
        );
      } else {
        throw Exception('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint("MultiModel: ${config.name} error: $e");
      onStatusUpdate?.call(config.name, '❌ Failed');
      return ModelResponse(
        modelId: config.id,
        modelName: config.name,
        content: 'Error: $e',
        responseTime: stopwatch.elapsed,
        isError: true,
      );
    }
  }

  // ─── Multi-Model Orchestration ───

  /// Send a message to all 3 models in parallel, then synthesize the best answer.
  Future<MultiModelResult> sendMessage(
    String message, {
    List<Map<String, dynamic>>? history,
    String? ragContext,
  }) async {
    // Prepare the full message with RAG context
    final fullMessage = ragContext != null
        ? "Context from uploaded files:\n$ragContext\n\nUser Question: $message"
        : message;

    // Get model configs (both local LM Studio models)
    final llama = await _llamaConfig;
    final mistral = await _mistralConfig;

    onStatusUpdate?.call('System', '🚀 Querying 3 models...');

    // Fire all 3 models in parallel
    final results = await Future.wait([
      _callModel(
        llama,
        fullMessage,
        history,
        maxTokens: 384,
        temperature: 0.3,
      ),
      _callModel(
        mistral,
        fullMessage,
        history,
        maxTokens: 512,
        temperature: 0.4,
      ),
      _callModel(
        _deepSeekConfig,
        fullMessage,
        history,
        maxTokens: 512,
        temperature: 0.4,
      ),
    ]);

    // Separate successful and failed responses
    final successful = results.where((r) => !r.isError).toList();
    final failed = results.where((r) => r.isError).toList();

    if (failed.isNotEmpty) {
      debugPrint(
        "MultiModel: ${failed.length} model(s) failed: "
        "${failed.map((f) => f.modelName).join(', ')}",
      );
    }

    // Synthesize the final answer
    String finalAnswer;
    String method;

    if (successful.isEmpty) {
      // All models failed
      finalAnswer =
          "I'm having trouble connecting right now. Please check:\n"
          "• LM Studio is running on your computer\n"
          "• Your internet connection is active\n"
          "• The Ngrok tunnel (if using) is still alive";
      method = 'fallback_error';
    } else if (successful.length == 1) {
      // Only one model succeeded
      finalAnswer = successful.first.content;
      method = 'single_model_${successful.first.modelId}';
    } else {
      // Multiple models succeeded — synthesize!
      finalAnswer = await _synthesizeResponses(
        message,
        successful,
        llama, // Use Llama as the synthesizer (fastest local model)
        history,
      );
      method = 'multi_model_synthesis';
    }

    onStatusUpdate?.call('System', '✨ Response ready');

    return MultiModelResult(
      finalAnswer: finalAnswer,
      individualResponses: results,
      synthesisMethod: method,
    );
  }

  /// Use LM Studio (fastest local model) to synthesize multiple model responses
  /// into one clear, student-friendly answer.
  Future<String> _synthesizeResponses(
    String originalQuestion,
    List<ModelResponse> responses,
    ModelConfig synthesizer,
    List<Map<String, dynamic>>? history,
  ) async {
    onStatusUpdate?.call('System', '🧠 Synthesizing best answer...');

    final responseSummary = responses.map((r) {
      return "--- ${r.modelName} ---\n${r.content}";
    }).join('\n\n');

    final synthesisPrompt =
        "You received the following question from a student:\n"
        "\"$originalQuestion\"\n\n"
        "Here are responses from multiple AI experts:\n\n"
        "$responseSummary\n\n"
        "TASK: Combine the best parts of all responses into ONE clear, concise, "
        "student-friendly answer. Do NOT mention model names or that multiple "
        "AIs were consulted. Just give the best unified answer. "
        "Use bullet points and step-by-step format where helpful. "
        "Keep it mobile-friendly (concise paragraphs).";

    try {
      final result = await _callModel(
        synthesizer,
        synthesisPrompt,
        null, // No history needed for synthesis
        customSystemPrompt:
            'You are a master tutor. Your job is to combine multiple expert '
            'answers into one perfect, clear, beginner-friendly explanation. '
            'Never mention that you are combining answers. Just give the best answer.',
        maxTokens: 768,
        temperature: 0.3,
      );

      if (!result.isError) {
        return result.content;
      }
    } catch (e) {
      debugPrint("MultiModel: Synthesis failed: $e");
    }

    // If synthesis fails, return the longest successful response
    responses.sort((a, b) => b.content.length.compareTo(a.content.length));
    return responses.first.content;
  }

  /// Quick single-model call (for simple queries) - uses Llama only
  Future<String> sendQuickMessage(
    String message, {
    List<Map<String, dynamic>>? history,
  }) async {
    final config = await _llamaConfig;
    final result = await _callModel(config, message, history);
    if (result.isError) {
      throw Exception(result.content);
    }
    return result.content;
  }
}
