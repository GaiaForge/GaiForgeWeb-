import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _apiKeyPrefix = 'guardian_api_key_';

  // Singleton pattern
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  /// Save an API key with a specific ID
  Future<void> saveApiKey(String keyId, String apiKey) async {
    await _storage.write(key: '$_apiKeyPrefix$keyId', value: apiKey);
  }

  /// Retrieve an API key by ID
  Future<String?> getApiKey(String keyId) async {
    return await _storage.read(key: '$_apiKeyPrefix$keyId');
  }

  /// Delete an API key by ID
  Future<void> deleteApiKey(String keyId) async {
    await _storage.delete(key: '$_apiKeyPrefix$keyId');
  }

  /// Delete all keys (useful for reset)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
