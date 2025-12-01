//lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  
  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
  }
  
  Future<void> speak(String text) async {
    if (_isSpeaking || text.isEmpty) return;
    
    _isSpeaking = true;
    print('🔊 Speaking: $text');
    await _flutterTts.speak(text);
  }
  
  bool get isSpeaking => _isSpeaking;
  
  void stop() {
    _flutterTts.stop();
    _isSpeaking = false;
  }
}