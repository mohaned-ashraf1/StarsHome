import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final String releaseName;
  final String releaseNotes;
  final DateTime? publishedAt;
  final String? downloadUrl;
  final String? assetName;
  final int assetSize;
  final String? expectedSha256;
  final bool hasUpdate;

  UpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseName,
    required this.releaseNotes,
    this.publishedAt,
    this.downloadUrl,
    this.assetName,
    this.assetSize = 0,
    this.expectedSha256,
    required this.hasUpdate,
  });

  String get currentDisplay => '$currentVersion+$currentBuildNumber';
  String get latestDisplay => '$latestVersion+$latestBuildNumber';
}

class UpdateService {
  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  static const String repoOwner = 'mohaned-ashraf1';
  static const String repoName = 'StarsHome';

  /// GitHub releases API URL
  static const String latestReleaseUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  /// Compare two versions (e.g. 1.0.13+14 vs 1.0.12+13)
  static bool isNewerVersion({
    required String currentVer,
    required int currentBuild,
    required String latestVer,
    required int latestBuild,
  }) {
    final curParts = currentVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latParts = latestVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (curParts.length < 3) {
      curParts.add(0);
    }
    while (latParts.length < 3) {
      latParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (latParts[i] > curParts[i]) return true;
      if (latParts[i] < curParts[i]) return false;
    }

    // Major, minor, patch are equal — compare build numbers
    return latestBuild > currentBuild;
  }

  /// Checks GitHub Releases for the latest version
  Future<UpdateInfo> checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVer = packageInfo.version;
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(Uri.parse(latestReleaseUrl));
      request.headers.set('User-Agent', 'STARS-HOMES-ERP');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('GitHub API returned status ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(body);

      final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '').trim();
      final releaseName = data['name'] as String? ?? 'STARS HOMES ERP Update';
      final releaseNotes = data['body'] as String? ?? 'تحسينات عامة واستقرار للنظام.';
      final publishedAtStr = data['published_at'] as String?;
      final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

      // Parse version and build number from tag (e.g. "1.0.13+14" or "1.0.13")
      String latestVer = tagName;
      int latestBuild = 0;
      if (tagName.contains('+')) {
        final parts = tagName.split('+');
        latestVer = parts[0];
        latestBuild = int.tryParse(parts[1]) ?? 0;
      }

      // Check assets
      final assets = (data['assets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      String? downloadUrl;
      String? assetName;
      int assetSize = 0;
      String? expectedSha256;

      // Extract checksums if SHA256SUMS.txt exists in release
      final checksumAsset = assets.firstWhere(
        (a) => (a['name'] as String? ?? '').toLowerCase().contains('sha256'),
        orElse: () => {},
      );

      Map<String, String> sha256Map = {};
      if (checksumAsset.isNotEmpty && checksumAsset['browser_download_url'] != null) {
        try {
          final cReq = await client.getUrl(Uri.parse(checksumAsset['browser_download_url']));
          final cRes = await cReq.close();
          if (cRes.statusCode == 200) {
            final cBody = await cRes.transform(utf8.decoder).join();
            for (final line in cBody.split('\n')) {
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                sha256Map[parts[1].trim()] = parts[0].trim().toLowerCase();
              }
            }
          }
        } catch (_) {}
      }

      // Select asset based on OS platform
      if (!kIsWeb && Platform.isAndroid) {
        final apkAsset = assets.firstWhere(
          (a) => (a['name'] as String? ?? '').endsWith('.apk'),
          orElse: () => {},
        );
        if (apkAsset.isNotEmpty) {
          downloadUrl = apkAsset['browser_download_url'];
          assetName = apkAsset['name'];
          assetSize = apkAsset['size'] ?? 0;
          expectedSha256 = sha256Map[assetName];
        }
      } else if (!kIsWeb && Platform.isWindows) {
        final exeAsset = assets.firstWhere(
          (a) => (a['name'] as String? ?? '').endsWith('Setup.exe'),
          orElse: () => assets.firstWhere(
            (a) => (a['name'] as String? ?? '').endsWith('.exe'),
            orElse: () => {},
          ),
        );
        if (exeAsset.isNotEmpty) {
          downloadUrl = exeAsset['browser_download_url'];
          assetName = exeAsset['name'];
          assetSize = exeAsset['size'] ?? 0;
          expectedSha256 = sha256Map[assetName];
        }
      }

      final hasUpdate = isNewerVersion(
        currentVer: currentVer,
        currentBuild: currentBuild,
        latestVer: latestVer,
        latestBuild: latestBuild,
      );

      return UpdateInfo(
        currentVersion: currentVer,
        currentBuildNumber: currentBuild,
        latestVersion: latestVer,
        latestBuildNumber: latestBuild,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        publishedAt: publishedAt,
        downloadUrl: downloadUrl,
        assetName: assetName,
        assetSize: assetSize,
        expectedSha256: expectedSha256,
        hasUpdate: hasUpdate,
      );
    } finally {
      client.close();
    }
  }

  /// Downloads the release asset with live progress
  Future<File> downloadUpdate(
    UpdateInfo info, {
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    if (info.downloadUrl == null) {
      throw Exception('لا يتوفر رابط تحميل لهذا الجهاز.');
    }

    final tempDir = await getTemporaryDirectory();
    final safeName = info.assetName ?? (Platform.isAndroid ? 'update.apk' : 'update_setup.exe');
    final targetFile = File('${tempDir.path}/$safeName');

    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(minutes: 5);

    try {
      final request = await client.getUrl(Uri.parse(info.downloadUrl!));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException('فشل التحميل من السيرفر (كود: ${response.statusCode})');
      }

      final totalBytes = response.contentLength > 0 ? response.contentLength : info.assetSize;
      int receivedBytes = 0;

      final sink = targetFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = receivedBytes / totalBytes;
          onProgress(progress.clamp(0.0, 1.0), receivedBytes, totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      // Verify SHA-256 if available
      if (info.expectedSha256 != null && info.expectedSha256!.isNotEmpty) {
        final bytes = await targetFile.readAsBytes();
        final actualHash = sha256.convert(bytes).toString().toLowerCase();
        if (actualHash != info.expectedSha256!.toLowerCase()) {
          await targetFile.delete();
          throw Exception(
              'فشل التحقق من أمان الملف (بصمة التشفير SHA-256 غير متطابقة). تم إلغاء التثبيت حمايةً لبياناتك.');
        }
      }

      return targetFile;
    } finally {
      client.close();
    }
  }

  /// Installs the downloaded update package safely
  Future<void> installUpdate(File file) async {
    if (!await file.exists()) {
      throw Exception('ملف التحديث غير موجود.');
    }

    if (Platform.isAndroid) {
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        throw Exception('تعذر فتح مثبت التطبيقات: ${result.message}');
      }
    } else if (Platform.isWindows) {
      // Launch installer detached and close current Flutter process so files can be upgraded
      await Process.start(
        file.path,
        [],
        mode: ProcessStartMode.detached,
      );
      // Wait a moment then exit gracefully
      await Future.delayed(const Duration(milliseconds: 500));
      exit(0);
    } else {
      throw UnsupportedError('المنصة الحالية لا تدعم التثبيت المباشر.');
    }
  }
}
