import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart'; // 추가
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class CloverDetectionPage extends StatefulWidget {
  @override
  _CloverDetectionPageState createState() => _CloverDetectionPageState();
}

class _CloverDetectionPageState extends State<CloverDetectionPage> {
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isDetecting = false;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModelAndLabels();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.medium);
    await _controller.initialize();
    _controller.startImageStream((CameraImage image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _runModelOnFrame(image);
      }
    });
    setState(() {});
  }

  Future<void> _loadModelAndLabels() async {
    _interpreter = await Interpreter.fromAsset('assets/clover_model.tflite');
    _labels = await _loadLabels('assets/clover_labels.txt');
  }

  Future<List<String>> _loadLabels(String path) async {
    final rawLabels = await rootBundle.loadString(path); // 추가
    return rawLabels.split('\n').map((label) => label.trim()).toList();
  }

  void _runModelOnFrame(CameraImage image) async {
    final img.Image convertedImage = img.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: img.Format.rgb,
    );

    final resizedImage =
        img.copyResize(convertedImage, width: 224, height: 224);
    final normalizedImage =
        resizedImage.getBytes().map((byte) => byte / 255.0).toList();

    final input = List.generate(1, (index) => normalizedImage);
    final output =
        List.generate(1, (index) => List.filled(_labels.length, 0.0));

    _interpreter.run(input, output);

    final results = output[0];
    final maxScore = results.reduce((a, b) => a > b ? a : b);
    final labelIndex = results.indexOf(maxScore);

    setState(() {
      _result = _labels[labelIndex];
      _isDetecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('행운 찾기'),
      ),
      body: Column(
        children: <Widget>[
          _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: CameraPreview(_controller),
                )
              : Container(),
          SizedBox(height: 16),
          Text(_result),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
