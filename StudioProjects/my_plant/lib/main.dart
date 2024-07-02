import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'plant_detection_page.dart';
import 'clover_detection_page.dart';
import 'dart:io' show Platform;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  CameraDescription? camera;
  if (Platform.isAndroid || Platform.isIOS) {
    final cameras = await availableCameras();
    camera = cameras.first;
  }

  runApp(MyApp(camera: camera));
}

class MyApp extends StatelessWidget {
  final CameraDescription? camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Master',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor:
            const Color.fromRGBO(246, 238, 201, 1.0), // 여기서 배경 색상 변경
      ),
      home: HomePage(camera: camera),
    );
  }
}

class HomePage extends StatelessWidget {
  final CameraDescription? camera;

  const HomePage({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Master'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        // Container로 감싸서 배경 색상 변경
        color: const Color.fromRGBO(246, 238, 201, 1.0), // 여기서도 배경 색상 변경
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/logo.png', height: 200),
              const SizedBox(height: 24),
              Text(
                'PLANT MASTER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  shadows: const [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 5.0,
                      color: Color.fromARGB(128, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(context, '식물 이름 찾기', const PlantDetectionPage()),
                  _buildButton(
                    context,
                    '행운 찾기',
                    camera != null || Platform.isWindows
                        ? CloverDetectionPage(camera: camera)
                        : const PlaceholderPage(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Widget page) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, // 글자 색을 흰색으로 설정
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        textStyle: const TextStyle(fontSize: 20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Supported'),
      ),
      body: const Center(
        child: Text('This functionality is not supported on this platform.'),
      ),
    );
  }
}
