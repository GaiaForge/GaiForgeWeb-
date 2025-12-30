import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AnthropicService {
  static final AnthropicService _instance = AnthropicService._internal();
  factory AnthropicService() => _instance;
  AnthropicService._internal();

  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';
  static const String _apiVersion = '2023-06-01';

  Future<AnthropicResponse> sendMessage({
    required String apiKey,
    required String prompt,
    String? systemPrompt,
    int maxTokens = 1024,
  }) async {
    try {
      final messages = [
        {'role': 'user', 'content': prompt}
      ];

      final body = {
        'model': _model,
        'max_tokens': maxTokens,
        'messages': messages,
      };

      if (systemPrompt != null) {
        body['system'] = systemPrompt;
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': _apiVersion,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'] as List;
        final text = content
            .where((c) => c['type'] == 'text')
            .map((c) => c['text'])
            .join('\n');
        
        return AnthropicResponse(
          success: true,
          message: text,
          tokensUsed: data['usage']?['output_tokens'] ?? 0,
        );
      } else {
        final error = jsonDecode(response.body);
        return AnthropicResponse(
          success: false,
          message: error['error']?['message'] ?? 'Unknown error',
          error: 'API Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AnthropicResponse(
        success: false,
        message: 'Failed to connect to Anthropic API',
        error: e.toString(),
      );
    }
  }

  /// Test API key validity
  Future<bool> testConnection(String apiKey) async {
    final response = await sendMessage(
      apiKey: apiKey,
      prompt: 'Respond with only: OK',
      maxTokens: 10,
    );
    return response.success;
  }
}

class AnthropicResponse {
  final bool success;
  final String message;
  final String? error;
  final int tokensUsed;

  AnthropicResponse({
    required this.success,
    required this.message,
    this.error,
    this.tokensUsed = 0,
  });
}
