import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CloverDetectionPage extends StatefulWidget {
  @override
  _CloverDetectionPageState createState() => _CloverDetectionPageState();
}

class _CloverDetectionPageState extends State<CloverDetectionPage> {
  static const platform = const MethodChannel('clover_camera');
  String _result = '카메라 준비 중...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final result = await platform.invokeMethod('startCamera');
      setState(() {
        _result = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _result = "Failed to start camera: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('행운 찾기'),
      ),
      body: Center(
        child: Text(_result),
      ),
    );
  }
}
