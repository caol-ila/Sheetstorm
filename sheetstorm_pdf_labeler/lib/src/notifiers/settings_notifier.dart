import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsState {
  final String? sourcePath;
  final String? targetPath;
  final String? pat;
  final bool rememberPat;
  final double confidence;

  const SettingsState({
    this.sourcePath,
    this.targetPath,
    this.pat,
    this.rememberPat = false,
    this.confidence = 0.6,
  });

  SettingsState copyWith({
    String? sourcePath,
    String? targetPath,
    String? pat,
    bool? rememberPat,
    double? confidence,
  }) {
    return SettingsState(
      sourcePath: sourcePath ?? this.sourcePath,
      targetPath: targetPath ?? this.targetPath,
      pat: pat ?? this.pat,
      rememberPat: rememberPat ?? this.rememberPat,
      confidence: confidence ?? this.confidence,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadPat();
  }

  static const _storage = FlutterSecureStorage();
  static const _patKey = 'sheetstorm_pat';

  Future<void> _loadPat() async {
    try {
      final pat = await _storage.read(key: _patKey);
      if (pat != null) {
        state = state.copyWith(pat: pat, rememberPat: true);
      }
    } catch (e) {
      // Ignore storage errors
    }
  }

  void setSourcePath(String path) {
    state = state.copyWith(sourcePath: path);
  }

  void setTargetPath(String path) {
    state = state.copyWith(targetPath: path);
  }

  void setPat(String pat) {
    state = state.copyWith(pat: pat);
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
