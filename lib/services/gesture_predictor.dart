// lib/services/gesture_predictor.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class GesturePredictor {
  Interpreter? _interpreter;
  List<String> _labels = [];
  int _predictionCount = 0;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/hand_gesture_model.tflite',
      );

      final labelsData = await rootBundle.loadString('assets/labels.json');
      _labels = List<String>.from(json.decode(labelsData));

      print('✓ Model loaded successfully');
      print('  - Gestures: ${_labels.length}');
      print('  - Labels: $_labels');
      print('  - Input shape: ${_interpreter!.getInputTensors()[0].shape}');
      print('  - Input type: ${_interpreter!.getInputTensors()[0].type}');
      print('  - Output shape: ${_interpreter!.getOutputTensors()[0].shape}');
    } catch (e) {
      print('❌ Error loading model: $e');
      rethrow;
    }
  }

  Map<String, dynamic> predict(List<double> landmarks) {
    if (_interpreter == null) {
      print('❌ Interpreter not initialized');
      return {'label': '', 'confidence': 0.0};
    }

    if (landmarks.length != 42) {
      print('❌ Invalid input: expected 42 features, got ${landmarks.length}');
      return {'label': '', 'confidence': 0.0};
    }

    try {
      _predictionCount++;

      // Prepare input [1, 42]
      var input = [landmarks];

      // Prepare output [1, num_classes]
      var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      // Run inference
      _interpreter!.run(input, output);

      // Get probabilities
      List<double> probabilities = output[0];

      // Find max
      int maxIndex = 0;
      double maxProbValue = probabilities[0];

      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProbValue) {
          maxProbValue = probabilities[i];
          maxIndex = i;
        }
      }

      // Log every 50 predictions
      if (_predictionCount % 50 == 0) {
        print('\n📊 PREDICTION #$_predictionCount:');
        print(
          'Input (first 8): [${landmarks.sublist(0, 8).map((v) => v.toStringAsFixed(3)).join(", ")}]',
        );

        // Check for suspicious values
        double sumAbs = landmarks.map((v) => v.abs()).reduce((a, b) => a + b);
        double avgAbs = sumAbs / landmarks.length;
        print('Average absolute value: ${avgAbs.toStringAsFixed(4)}');

        if (avgAbs > 100) {
          print(
            '⚠️ WARNING: Input values are very large! Normalization might be wrong.',
          );
        } else if (avgAbs < 0.01) {
          print(
            '⚠️ WARNING: Input values are very small! Hand might be too small or normalization issue.',
          );
        }

        print('\nAll predictions:');
        for (int i = 0; i < probabilities.length; i++) {
          String bar = '█' * (probabilities[i] * 50).round();
          print(
            '  ${_labels[i].padRight(15)}: ${(probabilities[i] * 100).toStringAsFixed(1).padLeft(5)}% $bar',
          );
        }
        print(
          '\n→ Best: ${_labels[maxIndex]} (${(maxProbValue * 100).toStringAsFixed(1)}%)\n',
        );

        // Check if all probabilities are similar (indicates problem)
        double minProb = probabilities.reduce((a, b) => a < b ? a : b);
        double maxProb = probabilities.reduce((a, b) => a > b ? a : b);
        if (maxProb - minProb < 0.1) {
          print(
            '⚠️ WARNING: All predictions are very similar! Model might not be working correctly.',
          );
        }
      }

      return {'label': _labels[maxIndex], 'confidence': maxProbValue};
    } catch (e) {
      print('❌ Prediction error: $e');
      return {'label': '', 'confidence': 0.0};
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
