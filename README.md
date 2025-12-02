# Sign Language Gesture Recognition App

This Flutter-based application detects hand gestures using a custom-trained TensorFlow Lite model and converts recognized gestures into speech. The model is based on the Mediapipe framework, specifically trained to detect 41 distinct hand gestures, making it a powerful tool for sign language recognition. When a gesture is detected, the app predicts and converts it into text and voice, providing an interactive and accessible experience for users.

## Features

- **Hand Gesture Detection**: Uses a custom-trained TensorFlow Lite model integrated with the Mediapipe framework to identify 41 hand gestures.
- **Speech Synthesis**: Converts recognized hand gestures into text and speech using Flutter's speech synthesis capabilities.
- **Real-time Detection**: Provides real-time gesture recognition and feedback.
- **Cross-platform**: Built using Flutter, this app runs on both Android and iOS devices.

## Requirements

- Flutter (version 2.0 or higher)
- Dart SDK
- A physical device or an emulator to run the app
- Custom `.tflite` model for hand gesture recognition
- `mediapipe`-based hand gesture data with 41 points

## Getting Started

### Prerequisites

1. Ensure that you have Flutter installed. If not, follow the [Flutter installation guide](https://flutter.dev/docs/get-started/install).
2. You’ll need a physical Android or iOS device, or an emulator, to test the app.
3. Place your custom-trained `.tflite` model and model-related files (e.g., label files) in the appropriate folder in the project directory.

### Clone the Repository

```bash
git clone https://github.com/vaisakh488/Sign-Language-to-Voice.git

