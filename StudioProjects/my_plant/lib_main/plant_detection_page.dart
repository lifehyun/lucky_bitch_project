import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'plant_result_page.dart'; // 새로운 페이지 import

class PlantDetectionPage extends StatefulWidget {
  const PlantDetectionPage({super.key});

  @override
  _PlantDetectionPageState createState() => _PlantDetectionPageState();
}

class _PlantDetectionPageState extends State<PlantDetectionPage> {
  File? _image;
  String _result = 'No result yet';

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _result = 'No result yet'; // Reset result when new image is picked
    });

    _uploadImage(_image!);
  }

  Future<void> _uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.100.20:7777/predict'), // 서버 주소를 실제 서버 주소로 변경
      );
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final result = json.decode(responseData.body);

      setState(() {
        _result = result['results'].toString();
      });
    } catch (e) {
      setState(() {
        _result = 'Error uploading image: $e';
      });
    }
  }

  void _onSearchPressed() {
    // 식물 돋보기 버튼이 눌렸을 때 plant_result_page로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantResultPage(result: _result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식물 이름 찾기'),
        backgroundColor: Colors.green, // AppBar의 배경색을 초록색으로 설정
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_image != null)
              Column(
                children: [
                  Image.file(_image!, width: 300, height: 300),
                  const SizedBox(height: 16),
                  Text(_result, style: const TextStyle(fontSize: 20)),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: const Text('식물 사진 불러오기'),
                ),
                const SizedBox(width: 16), // 버튼 사이의 간격
                if (_image != null)
                  ElevatedButton(
                    onPressed: _onSearchPressed,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    child: const Text('식물 돋보기'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
