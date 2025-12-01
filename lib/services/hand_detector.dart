// lib/services/hand_detector.dart

import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:camera/camera.dart';
import 'dart:math';

class HandDetectorService {
  late HandLandmarkerPlugin _handLandmarker;
  int _debugCount = 0;

  void initialize() {
    _handLandmarker = HandLandmarkerPlugin.create(numHands: 1);
    print('✓ Hand detector initialized');
  }

  /// Detect and return 42 normalized features
  List<double>? detectFromCameraFrame(
    CameraImage image,
    int sensorOrientation,
  ) {
    try {
      final hands = _handLandmarker.detect(image, sensorOrientation);
      if (hands.isEmpty) return null;

      final hand = hands.first.landmarks; // 21 points
      _debugCount++;

      // Collect raw XY values (42 items)
      List<double> raw = [];
      for (int i = 0; i < 21; i++) {
        raw.add(hand[i].x);
        raw.add(hand[i].y);
      }

      // Debug every 50 detections
      if (_debugCount % 50 == 0) {
        print('\n🔍 DEBUG #$_debugCount:');
        print('Raw landmarks (first 4):');
        print(
          '  Wrist: (${raw[0].toStringAsFixed(4)}, ${raw[1].toStringAsFixed(4)})',
        );
        print(
          '  Thumb: (${raw[8].toStringAsFixed(4)}, ${raw[9].toStringAsFixed(4)})',
        );
        print(
          '  Index: (${raw[16].toStringAsFixed(4)}, ${raw[17].toStringAsFixed(4)})',
        );
        print(
          '  Middle: (${raw[24].toStringAsFixed(4)}, ${raw[25].toStringAsFixed(4)})',
        );

        // Check if coordinates are in expected range
        List<double> xCoords = [];
        List<double> yCoords = [];
        for (int i = 0; i < raw.length; i++) {
          if (i % 2 == 0) {
            xCoords.add(raw[i]);
          } else {
            yCoords.add(raw[i]);
          }
        }
        double minX = xCoords.reduce((a, b) => a < b ? a : b);
        double maxX = xCoords.reduce((a, b) => a > b ? a : b);
        double minY = yCoords.reduce((a, b) => a < b ? a : b);
        double maxY = yCoords.reduce((a, b) => a > b ? a : b);

        print('  X range: [$minX, $maxX]');
        print('  Y range: [$minY, $maxY]');

        if (maxX > 10 || maxY > 10) {
          print(
            '  ⚠️ WARNING: Coordinates seem to be in pixel space, not normalized!',
          );
          print('  ⚠️ hand_landmarker might need different handling');
        }
      }

      // Normalize EXACT same as Python
      final normalized = _normalize42(raw);

      if (_debugCount % 50 == 0) {
        print('\nNormalized (first 4):');
        print(
          '  Wrist: (${normalized[0].toStringAsFixed(4)}, ${normalized[1].toStringAsFixed(4)})',
        );
        print(
          '  Thumb: (${normalized[8].toStringAsFixed(4)}, ${normalized[9].toStringAsFixed(4)})',
        );
        print(
          '  Index: (${normalized[16].toStringAsFixed(4)}, ${normalized[17].toStringAsFixed(4)})',
        );
        print(
          '  Middle: (${normalized[24].toStringAsFixed(4)}, ${normalized[25].toStringAsFixed(4)})',
        );
      }

      return normalized;
    } catch (e) {
      print("❌ Hand detection error: $e");
      return null;
    }
  }

  /// Normalize using wrist & middle fingertip distance
  List<double> _normalize42(List<double> land) {
    // Wrist values
    double wristX = land[0];
    double wristY = land[1];

    // Step 1: Subtract wrist (Translate)
    final List<double> normalized = List.from(land);
    for (int i = 0; i < 42; i += 2) {
      normalized[i] -= wristX;
      normalized[i + 1] -= wristY;
    }

    // Step 2: Middle fingertip distance (landmark 12 => index 24,25)
    double tipX = land[24];
    double tipY = land[25];

    double dx = tipX - wristX;
    double dy = tipY - wristY;
    double handSize = sqrt(dx * dx + dy * dy);

    if (_debugCount % 50 == 0) {
      print('  Hand size: ${handSize.toStringAsFixed(4)}');
      if (handSize < 0.01) {
        print('  ⚠️ WARNING: Hand size is very small!');
      }
    }

    // Step 3: Scale only if > tiny threshold
    if (handSize > 0.0001) {
      for (int i = 0; i < 42; i++) {
        normalized[i] /= handSize;
      }
    }

    return normalized;
  }

  void dispose() {
    _handLandmarker.dispose();
  }
}
