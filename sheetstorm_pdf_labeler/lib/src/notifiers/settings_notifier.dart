import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsState {
  final String? sourcePath;
  final String? targetPath;
  final String? pat;
  final bool rememberPat;
  final double confidence;
  final String? patSource;

  const SettingsState({
    this.sourcePath,
    this.targetPath,
    this.pat,
    this.rememberPat = false,
    this.confidence = 0.6,
    this.patSource,
  });

  SettingsState copyWith({
    String? sourcePath,
    String? targetPath,
    String? pat,
    bool? rememberPat,
    double? confidence,
    String? patSource,
  }) {
    return SettingsState(
      sourcePath: sourcePath ?? this.sourcePath,
      targetPath: targetPath ?? this.targetPath,
      pat: pat ?? this.pat,
      rememberPat: rememberPat ?? this.rememberPat,
      confidence: confidence ?? this.confidence,
      patSource: patSource ?? this.patSource,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _autoDiscoverPat();
  }

  static const _storage = FlutterSecureStorage();
  static const _patKey = 'sheetstorm_pat';

  Future<void> _autoDiscoverPat() async {
    // 0. Build-time dart-define (works on web, CI, sandboxed runs)
    const buildToken = String.fromEnvironment('GITHUB_TOKEN');
    if (buildToken.isNotEmpty) {
      state = state.copyWith(pat: buildToken, patSource: 'dart-define:GITHUB_TOKEN');
      return;
    }

    if (!kIsWeb) {
      // 1. Environment variable GITHUB_TOKEN (CI, shell export) — desktop only
      final envToken = Platform.environment['GITHUB_TOKEN'];
      if (envToken != null && envToken.isNotEmpty) {
        state = state.copyWith(pat: envToken, patSource: 'env:GITHUB_TOKEN');
        return;
      }

      // 2. gh CLI (`gh auth token`) — most common on dev workstations — desktop only
      final ghToken = await _tryReadGhCliToken();
      if (ghToken != null && ghToken.isNotEmpty) {
        state = state.copyWith(pat: ghToken, patSource: 'gh auth token');
        return;
      }
    }

    // 3. Secure storage (user-saved) — works on all platforms
    try {
      final stored = await _storage.read(key: _patKey);
      if (stored != null && stored.isNotEmpty) {
        state = state.copyWith(pat: stored, rememberPat: true, patSource: 'secure_storage');
      }
    } catch (_) {
      // Ignore storage errors — user can enter manually
    }
  }

  Future<String?> _tryReadGhCliToken() async {
    try {
      final result = await Process.run(
        'gh',
        ['auth', 'token'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final stdout = (result.stdout as String).trim();
        if (stdout.startsWith('gh') && stdout.length > 10) {
          return stdout;
        }
      }
    } catch (_) {
      // gh not installed / not on PATH — fine, fall through
    }
    return null;
  }

  void setSourcePath(String path) {
    state = state.copyWith(sourcePath: path);
  }

  void setTargetPath(String path) {
    state = state.copyWith(targetPath: path);
  }

  void setPat(String pat) {
    state = state.copyWith(pat: pat, patSource: 'manual');
  }

  void setRememberPat(bool remember) {
    state = state.copyWith(rememberPat: remember);
    if (remember && state.pat != null) {
      _storage.write(key: _patKey, value: state.pat);
    } else {
      _storage.delete(key: _patKey);
    }
  }

  void setConfidence(double confidence) {
    state = state.copyWith(confidence: confidence);
  }
}
