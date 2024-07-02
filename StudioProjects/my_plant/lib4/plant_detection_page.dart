import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 추가
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'plant_result_page.dart';

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
    _interpreter = await Interpreter.fromAsset('assets/plant_model.tflite');
    _labels = await _loadLabels('assets/plant_labels.txt');
  }

  Future<List<String>> _loadLabels(String path) async {
    final rawLabels = await rootBundle.loadString(path);
    return rawLabels.split('\n').map((label) => label.trim()).toList();
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
    final resizedImage = img.copyResize(imageInput, width: 224, height: 224);
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
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantResultPage(
          imagePath: _image!.path,
          result: _result,
        ),
      ),
    );
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
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('사진 찍기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
