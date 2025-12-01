// lib/screens/sign_language_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../services/hand_detector.dart';
import '../services/gesture_predictor.dart';
import '../services/tts_service.dart';
import '../main.dart';

class SignLanguageScreen extends StatefulWidget {
  @override
  _SignLanguageScreenState createState() => _SignLanguageScreenState();
}

class _SignLanguageScreenState extends State<SignLanguageScreen> {
  CameraController? _cameraController;
  HandDetectorService? _handDetector;
  GesturePredictor? _gesturePredictor;
  TTSService? _ttsService;

  String _currentGesture = '';
  double _confidence = 0.0;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';

  List<String> _predictionHistory = [];
  final int _stabilityFrames = 7;

  String _lastSpoken = '';
  DateTime _lastSpeakTime = DateTime.now();
  final Duration _repeatDelay = Duration(milliseconds: 2500);

  int _frameCount = 0;
  int _detectionCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _statusMessage = 'Initializing camera...';
      });

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      setState(() {
        _statusMessage = 'Initializing hand detector...';
      });

      _handDetector = HandDetectorService();
      _handDetector!.initialize();

      setState(() {
        _statusMessage = 'Loading gesture model...';
      });

      _gesturePredictor = GesturePredictor();
      await _gesturePredictor!.initialize();

      setState(() {
        _statusMessage = 'Initializing text-to-speech...';
      });

      _ttsService = TTSService();
      await _ttsService!.initialize();

      setState(() {
        _statusMessage = 'Starting camera stream...';
      });

      _cameraController!.startImageStream(_processImage);

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready';
      });

      print('✓ All services initialized successfully');
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      print('❌ Initialization error: $e');
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _frameCount++;

    try {
      // Detect directly using CameraImage & sensor orientation
      final landmarks = _handDetector!.detectFromCameraFrame(
        image,
        _cameraController!.description.sensorOrientation,
      );

      if (landmarks != null && landmarks.length == 42) {
        _detectionCount++;

        if (_frameCount % 50 == 0) {
          print('Hand detected! Sample: ${landmarks.sublist(0, 4)}');
        }

        /// Predict gesture
        final result = _gesturePredictor!.predict(landmarks);

        String label = result['label'];
        double confidence = result['confidence'];

        if (_frameCount % 50 == 0) {
          print(
            'Prediction: $label (${(confidence * 100).toStringAsFixed(1)}%)',
          );
        }

        /// Stability check
        if (confidence > 0.55) {
          _predictionHistory.add(label);
        } else {
          _predictionHistory.add('');
        }

        if (_predictionHistory.length > _stabilityFrames) {
          _predictionHistory.removeAt(0);
        }

        final stableGesture = _getMostCommonPrediction();

        setState(() {
          _currentGesture = stableGesture;
          _confidence = stableGesture.isNotEmpty ? confidence : 0.0;
        });

        if (stableGesture.isNotEmpty) _speakIfReady(stableGesture);
      } else {
        // No detection
        if (_frameCount % 50 == 0) {
          print('No hand detected in frame $_frameCount');
        }

        _predictionHistory.add('');
        if (_predictionHistory.length > _stabilityFrames) {
          _predictionHistory.removeAt(0);
        }

        setState(() {
          _currentGesture = '';
          _confidence = 0.0;
        });
      }
    } catch (e) {
      if (_frameCount % 50 == 0) print('Processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  String _getMostCommonPrediction() {
    Map<String, int> counts = {};
    for (var pred in _predictionHistory) {
      if (pred.isNotEmpty) {
        counts[pred] = (counts[pred] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return '';

    var maxEntry = counts.entries.reduce((a, b) => a.value > b.value ? a : b);

    if (maxEntry.value >= _stabilityFrames / 2) {
      return maxEntry.key;
    }

    return '';
  }

  void _speakIfReady(String gesture) {
    final now = DateTime.now();
    final timeSince = now.difference(_lastSpeakTime);

    if (gesture != _lastSpoken || timeSince > _repeatDelay) {
      _ttsService!.speak(gesture);
      _lastSpoken = gesture;
      _lastSpeakTime = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 20),
              Text(
                _statusMessage,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Language to Voice'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'FPS: ${(_detectionCount / (_frameCount / 30)).toStringAsFixed(1)}',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          SizedBox.expand(child: CameraPreview(_cameraController!)),

          // Gesture display overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _confidence > 0.7 ? Colors.green : Colors.blue,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _currentGesture.isEmpty
                        ? 'NO GESTURE'
                        : _currentGesture.toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color:
                          _currentGesture.isEmpty
                              ? Colors.grey
                              : Colors.greenAccent,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _confidence,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _confidence > 0.7 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Debug info
          Positioned(
            top: 160,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frames: $_frameCount',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Detections: $_detectionCount',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pan_tool, color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Show hand gesture clearly to camera',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _handDetector?.dispose();
    _gesturePredictor?.dispose();
    _ttsService?.stop();
    super.dispose();
  }
}
