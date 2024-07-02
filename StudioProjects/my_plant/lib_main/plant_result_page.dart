import 'package:flutter/material.dart';
import 'clover_detection_page.dart'; // clover_detection_page import
import 'main.dart'; // main import

class PlantResultPage extends StatelessWidget {
  final String result;

  const PlantResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // 추출된 색상 값을 기반으로 Color 객체 생성
    Color dominantColor =
        const Color.fromRGBO(246, 238, 201, 1.0); // 예시 RGB 값, 실제 추출된 값으로 대체

    // 결과 값과 이미지 파일 이름을 매핑
    Map<String, String> plantImages = {
      '괴마옥': 'assets/괴마옥.JPG',
      '청옥': 'assets/청옥.JPG',
      '축전': 'assets/축전.JPG',
      '장미허브': 'assets/장미허브.JPG',
      '라울': 'assets/라울.JPG',
      '미니염자': 'assets/미니염자.JPG',
      '레티지아': 'assets/레티지아.JPG',
      '모닐리포메': 'assets/모닐리포메.JPG'
    };

    // 결과 값을 파싱
    Map<String, double> resultsMap = {};
    final regex = RegExp(r'(\S+) - 최대 정확도: (\d+\.\d+) ~ 최소 정확도: (\d+\.\d+)');
    final matches = regex.allMatches(result);

    for (final match in matches) {
      final name = match.group(1)!;
      final confidence = double.parse(match.group(2)!);
      resultsMap[name] = confidence;
    }

    // 정확도가 가장 높은 결과 찾기
    String? bestName;
    double highestConfidence = 0.0;

    resultsMap.forEach((name, confidence) {
      if (confidence > highestConfidence) {
        highestConfidence = confidence;
        bestName = name;
      }
    });

    // 결과 값에 해당하는 이미지 파일 이름 찾기
    String? imagePath;
    if (bestName != null && plantImages.containsKey(bestName)) {
      imagePath = plantImages[bestName];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('식물 결과'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        color: dominantColor,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: imagePath != null
                    ? Image.asset(imagePath,
                        fit: BoxFit.contain) // 이미지 크기 조정 및 화면 맞춤
                    : const Text(
                        '결과에 해당하는 이미지가 없습니다.',
                        style: TextStyle(fontSize: 20),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyApp(camera: null)),
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    child: const Text('돌아가기'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const CloverDetectionPage(camera: null)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    child: const Text('행운 찾기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
