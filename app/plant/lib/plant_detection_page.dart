import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // 추가된 부분
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as img;

class PlantDetectionPage extends StatefulWidget {
  @override
  _PlantDetectionPageState createState() => _PlantDetectionPageState();
}

class _PlantDetectionPageState extends State<PlantDetectionPage> {
  File? _image;
  late Interpreter _interpreter;
  late List<String> _labels;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  Future<void> _loadModelAndLabels() async {
    _interpreter = await Interpreter.fromAsset('plant_model.h5');
    _labels = await _loadLabels('assets/plant_labels.txt');
  }

  Future<List<String>> _loadLabels(String path) async {
    final rawLabels = await File(path).readAsLines();
    return rawLabels.map((label) => label.split(' ').last).toList();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
    });

    _classifyImage();
  }

  Future<void> _classifyImage() async {
    if (_image == null) return;

    final imageInput = img.decodeImage(_image!.readAsBytesSync())!;
    final tensorImage = TensorImage.fromImage(imageInput);

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('식물 이름 찾기'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_image != null) Image.file(_image!),
            SizedBox(height: 16),
            Text(_result),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('사진 찍기'),
            ),
          ],
        ),
      ),
    );
  }
}
