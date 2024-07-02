import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform, File;
import 'package:http/http.dart' as http;

class CloverDetectionPage extends StatefulWidget {
  final CameraDescription? camera;

  const CloverDetectionPage({super.key, this.camera});

  @override
  _CloverDetectionPageState createState() => _CloverDetectionPageState();
}

class _CloverDetectionPageState extends State<CloverDetectionPage> {
  CameraController? _controller;
  late io.Socket socket;
  bool _cameraInitialized = false;
  bool _fourLeafFound = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  Uint8List? _selectedImage;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _requestCameraPermission().then((granted) {
        if (granted && widget.camera != null) {
          _initializeCamera();
        }
      });
    }
    _initializeSocket();
  }

  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  void _initializeSocket() {
    socket = io.io('http://192.168.100.20:7777', <String, dynamic>{
      'transports': ['websocket'],
    });
    socket.on('connect', (_) {
      debugPrint('Connected to server');
    });
    socket.on('response', (data) {
      debugPrint('Received response from server: $data');
      setState(() {
        _fourLeafFound = data['four_leaf_found'];
        _resultMessage = _fourLeafFound ? '네잎 클로버를 찾았습니다.' : '네잎 클로버가 없습니다.';
      });
      if (_fourLeafFound) {
        _playAudio();
      }
    });
    socket.on('error', (data) {
      debugPrint('Error: ${data['error']}');
    });
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(widget.camera!, ResolutionPreset.medium);
    try {
      await _controller!.initialize();
      setState(() {
        _cameraInitialized = true;
      });
      _startImageCaptureTimer();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      setState(() {
        _cameraInitialized = false;
      });
    }
  }

  void _startImageCaptureTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _captureAndSendImage();
    });
  }

  Future<void> _captureAndSendImage() async {
    if (_controller == null || !_controller!.value.isStreamingImages) {
      return;
    }

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      socket.emit('image', {
        'image': base64Image,
        'width': _controller!.value.previewSize?.width ?? 0,
        'height': _controller!.value.previewSize?.height ?? 0,
        'rotation': widget.camera!.sensorOrientation.toString()
      });
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> _selectAndSendImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      Uint8List? bytes;

      if (file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes != null) {
        setState(() {
          _selectedImage = bytes;
          _resultMessage = null;
        });

        final base64Image = base64Encode(bytes);

        try {
          final response = await http.post(
            Uri.parse('http://192.168.100.20:7777/detect'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'image': base64Image,
            }),
          );

          if (response.statusCode == 200) {
            final result = json.decode(response.body);
            final bool fourLeafFound = result['four_leaf_found'];
            setState(() {
              _fourLeafFound = fourLeafFound;
              _resultMessage =
                  fourLeafFound ? '네잎 클로버를 찾았습니다.' : '네잎 클로버가 없습니다.';
            });
            if (fourLeafFound) {
              _playAudio();
            }
          } else {
            debugPrint('Failed to get second model result');
          }
        } catch (e) {
          debugPrint('Error sending image: $e');
        }
      } else {
        debugPrint('No bytes found in the selected file');
      }
    } else {
      debugPrint('File selection canceled');
    }
  }

  void _playAudio() {
    _audioPlayer.play(AssetSource('1.m4a')).then((_) {
      debugPrint('Audio played successfully');
    }).catchError((error) {
      debugPrint('Error playing audio: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('행운 찾기'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              _cameraInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            if (kIsWeb || Platform.isWindows)
              _selectedImage != null
                  ? Image.memory(_selectedImage!, height: 300)
                  : Container(),
            if (_resultMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _resultMessage!,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _selectAndSendImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('이미지 선택'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('돌아가기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    socket.dispose();
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }
}

extension StreamToBytes on Stream<List<int>> {
  Future<Uint8List> toBytes() async {
    List<int> bytes = [];
    await for (var byteList in this) {
      bytes.addAll(byteList);
    }
    return Uint8List.fromList(bytes);
  }
}
