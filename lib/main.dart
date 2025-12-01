import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/splash_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(SignLanguageApp());
}

class SignLanguageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Language to Voice',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(primary: Colors.blue),
      ),
      home: SplashScreen(), // 👈 Splash first
      debugShowCheckedModeBanner: false,
    );
  }
}
