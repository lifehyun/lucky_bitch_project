import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as img;
import 'dart:io'; // 추가된 부분

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
    _interpreter = await Interpreter.fromAsset('clover_model.h5');
    _labels = await _loadLabels('assets/clover_labels.txt');
  }

  Future<List<String>> _loadLabels(String path) async {
    final rawLabels = await File(path).readAsLines();
    return rawLabels.map((label) => label.split(' ').last).toList();
  }

  void _runModelOnFrame(CameraImage image) async {
    // Convert CameraImage to TensorImage
    final img.Image convertedImage = img.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: img.Format.rgb,
    );

    final tensorImage = TensorImage.fromImage(convertedImage);

    // Preprocess the image
    final inputProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(224, 224))
        .add(NormalizeOp(0, 255))
        .build()
        .process(tensorImage);

    final inputBuffer = inputProcessor.buffer;
    final outputBuffer = TensorBuffer.createFixedSize(
        <int>[1, _labels.length], TfLiteType.float32);

    _interpreter.run(inputBuffer, outputBuffer.buffer);

    final result = outputBuffer.getDoubleList();
    setState(() {
      _result =
          '${_labels[result.indexWhere((e) => e == result.reduce((a, b) => a > b ? a : b))]}';
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
