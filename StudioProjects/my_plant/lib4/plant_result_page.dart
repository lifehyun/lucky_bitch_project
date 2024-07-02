import 'package:flutter/material.dart';
import 'dart:io'; // 추가

class PlantResultPage extends StatelessWidget {
  final String imagePath;
  final String result;

  PlantResultPage({required this.imagePath, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('인식 결과'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.file(File(imagePath)),
            SizedBox(height: 16),
            Text(
              result,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('돌아가기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // 수정
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
