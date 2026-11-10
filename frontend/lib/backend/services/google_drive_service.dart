import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service managing secure Google Drive integration for STARS HOMES ERP backups.
/// Follows strict security rules:
/// - Minimum scope: https://www.googleapis.com/auth/drive.file
/// - Tokens stored securely via FlutterSecureStorage
/// - No hardcoded passwords or private credentials
class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._internal();
  GoogleDriveService._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'gdrive_access_token';
  static const _keyRefreshToken = 'gdrive_refresh_token';
  static const _keyAccountEmail = 'gdrive_account_email';
  static const _keyClientId = 'gdrive_client_id';

  /// Standard Google Drive Scope (only access files created by this app)
  static const String driveFileScope = 'https://www.googleapis.com/auth/drive.file';

  String? _cachedEmail;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get connectedEmail => _cachedEmail;

  /// Load connection state from secure storage
  Future<void> init() async {
    try {
      final token = await _storage.read(key: _keyAccessToken);
      final email = await _storage.read(key: _keyAccountEmail);
      if (token != null && token.isNotEmpty) {
        _isConnected = true;
        _cachedEmail = email ?? 'حساب المصنع المرتبط';
      } else {
        _isConnected = false;
        _cachedEmail = null;
      }
    } catch (e) {
      debugPrint('[GoogleDriveService] Init error: $e');
      _isConnected = false;
    }
  }

  /// Disconnect Google Drive account and wipe stored tokens
  Future<void> disconnect() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyAccountEmail);
    _isConnected = false;
    _cachedEmail = null;
  }

  /// Saves connected account tokens securely after OAuth completion
  Future<void> saveAuthTokens({
    required String accessToken,
    String? refreshToken,
    required String email,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
    await _storage.write(key: _keyAccountEmail, value: email);
    _isConnected = true;
    _cachedEmail = email;
  }

  /// Starts OAuth authorization flow in external browser
  Future<void> launchOAuthAuthorization({required String clientId, required String redirectUri}) async {
    await _storage.write(key: _keyClientId, value: clientId);
    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': driveFileScope,
      'access_type': 'offline',
      'prompt': 'consent',
    });

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('تعذر فتح متصفح الإنترنت لإتمام المصادقة.');
    }
  }

  /// Uploads a backup zip file to Google Drive under the designated folder
  Future<bool> uploadBackup(File backupFile, {required String subfolder}) async {
    final token = await _storage.read(key: _keyAccessToken);
    if (token == null || token.isEmpty) {
      debugPrint('[GoogleDriveService] Cannot upload — not connected');
      return false;
    }

    try {
      final fileName = backupFile.uri.pathSegments.last;
      final fileLength = await backupFile.length();

      // Simple upload via Google Drive v3 REST API
      final client = HttpClient();
      final uri = Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
      final request = await client.postUrl(uri);

      request.headers.set('Authorization', 'Bearer $token');
      final boundary = '-------STARS_HOMES_BOUNDARY_${DateTime.now().millisecondsSinceEpoch}';
      request.headers.set('Content-Type', 'multipart/related; boundary=$boundary');

      final metadata = {
        'name': fileName,
        'description': 'STARS HOMES ERP Factory Backup ($subfolder)',
        'mimeType': 'application/zip',
      };

      final metadataBytes = utf8.encode(
        '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${jsonEncode(metadata)}\r\n',
      );
      final mediaHeaderBytes = utf8.encode(
        '--$boundary\r\nContent-Type: application/zip\r\n\r\n',
      );
      final closingBytes = utf8.encode('\r\n--$boundary--');

      request.contentLength = metadataBytes.length +
          mediaHeaderBytes.length +
          fileLength +
          closingBytes.length;

      request.add(metadataBytes);
      request.add(mediaHeaderBytes);

      // Stream file bytes
      final fileStream = backupFile.openRead();
      await for (final chunk in fileStream) {
        request.add(chunk);
      }

      request.add(closingBytes);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[GoogleDriveService] ✓ Uploaded $fileName to Google Drive successfully');
        return true;
      } else {
        debugPrint('[GoogleDriveService] ✗ Upload failed (${response.statusCode}): $body');
        return false;
      }
    } catch (e) {
      debugPrint('[GoogleDriveService] Upload error: $e');
      return false;
    }
  }
}

