import 'dart:async';

/// Abstraktes Interface für die Audio-Analyse (Frequenz-Erkennung via Mikrofon).
///
/// Die konkrete Implementierung (Platform Channel für CoreAudio/Oboe/WASAPI)
/// wird von Vision bereitgestellt. Für Tests wird [MockAudioAnalyzer] verwendet.
abstract class AudioAnalyzer {
  /// Stream von erkannten Frequenzen in Hz.
  Stream<double> get frequencyStream;

  /// Startet die Mikrofon-Aufnahme und Frequenz-Analyse.
  Future<void> startListening();

  /// Stoppt die Mikrofon-Aufnahme und gibt die Ressource frei.
  Future<void> stopListening();

  /// Gibt alle Ressourcen frei.
  void dispose();
}

/// Test-Implementierung von [AudioAnalyzer] mit manuell ausgelösten Frequenzen.
class MockAudioAnalyzer implements AudioAnalyzer {
  final StreamController<double> _controller =
      StreamController<double>.broadcast();
  bool _isListening = false;

  @override
  Stream<double> get frequencyStream => _controller.stream;

  @override
  Future<void> startListening() async {
    _isListening = true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  /// Emittiert eine Frequenz für Testzwecke.
  void emitFrequency(double hz) {
    if (!_controller.isClosed) {
      _controller.add(hz);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }

  bool get isListening => _isListening;
}
