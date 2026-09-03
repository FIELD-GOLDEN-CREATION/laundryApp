import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../router/app_router.dart';

/// GitHub repo whose Releases this app checks against for newer APK builds.
const _kRepoSlug = 'FIELD-GOLDEN-CREATION/laundryApp';
const _kReleasesUrl = 'https://api.github.com/repos/$_kRepoSlug/releases/latest';

/// Checks GitHub Releases for a newer build than the one currently running
/// and, if found, prompts the user to download it. There's no true silent
/// OTA for a compiled Flutter binary (see Shorebird for that) — this covers
/// the "tell the user a new APK is out and hand them the link" half.
///
/// Always fails silently: a broken network check should never surface an
/// error to the user or block app startup.
class UpdateChecker {
  UpdateChecker._();

  static Future<void> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(_kReleasesUrl), headers: const {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final release = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = ((release['tag_name'] as String?) ?? '').replaceFirst(RegExp(r'^v'), '');
      if (latestVersion.isEmpty) return;

      final currentVersion = (await PackageInfo.fromPlatform()).version;
      if (!_isNewer(latestVersion, currentVersion)) return;

      final assets = ((release['assets'] as List?) ?? const []).cast<Map<String, dynamic>>();
      Map<String, dynamic>? apkAsset;
      for (final asset in assets) {
        if ((asset['name'] as String? ?? '').toLowerCase().endsWith('.apk')) {
          apkAsset = asset;
          break;
        }
      }
      final downloadUrl = (apkAsset?['browser_download_url'] as String?) ?? (release['html_url'] as String?);
      if (downloadUrl == null) return;

      _showUpdateDialog(version: latestVersion, notes: (release['body'] as String? ?? '').trim(), downloadUrl: downloadUrl);
    } catch (_) {
      return;
    }
  }

  /// Compares dotted numeric versions ("1.10.0" > "1.9.3"), padding the
  /// shorter side with zeros so "1.2" vs "1.2.1" compares correctly.
  static bool _isNewer(String remote, String current) {
    final r = _versionParts(remote);
    final c = _versionParts(current);
    for (var i = 0; i < r.length || i < c.length; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv != cv) return rv > cv;
    }
    return false;
  }

  /// Strips any "+build" metadata before splitting on ".", so a tag like
  /// "1.2.3+4" still compares as [1, 2, 3] instead of zeroing out the
  /// "3+4" segment (int.tryParse fails on it).
  static List<int> _versionParts(String version) {
    return version.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  static void _showUpdateDialog({required String version, required String notes, required String downloadUrl}) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update available (v$version)'),
        content: notes.isEmpty ? null : SingleChildScrollView(child: Text(notes)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Later')),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
