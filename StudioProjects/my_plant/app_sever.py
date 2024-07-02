import gevent.monkey
gevent.monkey.patch_all()

from flask import Flask, request, jsonify
from ultralytics import YOLO
from PIL import Image, UnidentifiedImageError
import io
import base64
import numpy as np
import cv2
from flask_socketio import SocketIO, emit
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# 각기 다른 모델 로드
model1 = YOLO('best_8.pt')  # 첫 번째 모델 파일 경로
model2 = YOLO('best_last.pt')  # 두 번째 모델 파일 경로

def preprocess_image(image_data):
    try:
        image = Image.open(io.BytesIO(image_data))
        return image
    except UnidentifiedImageError:
        raise ValueError("Invalid image data")

@app.route('/predict', methods=['POST'])
def predict():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image file'}), 400
        
        image_file = request.files['image']
        image_data = image_file.read()
        
        # 이미지를 전처리합니다.
        image = preprocess_image(image_data)
        
        # 첫 번째 모델을 실행합니다.
        results = model1(image, conf=0.1)  # 임계값을 0.1로 설정
        
        # 클래스 이름을 사용자 정의 이름으로 매핑합니다.
        class_name_mapping = {
            'Conophytum': '축전',
            'Euphorbia': '괴마옥',
            'Vicks': '장미허브',
            'LumiRose': '라울',
            'Crassula': '미니염자',
            'Letizia': '레티지아',
            'Sedum': '청옥',
            'Moniliformis': '모닐리포메'
            # 필요한 클래스명 매핑 추가
        }
        
        # 결과를 JSON 형식으로 변환합니다.
        class_results = {}
        for result in results:
            boxes = result.boxes
            for box in boxes:
                class_id = int(box.cls[0].item())
                original_class_name = result.names[class_id]
                class_name = class_name_mapping.get(original_class_name, original_class_name)
                confidence = box.conf[0].item()
                
                if class_name not in class_results:
                    class_results[class_name] = {
                        "min_confidence": confidence,
                        "max_confidence": confidence
                    }
                else:
                    if confidence < class_results[class_name]["min_confidence"]:
                        class_results[class_name]["min_confidence"] = confidence
                    if confidence > class_results[class_name]["max_confidence"]:
                        class_results[class_name]["max_confidence"] = confidence
        
        results_string = ""
        for class_name, confidences in class_results.items():
            result_string = f"{class_name} - 최대 정확도: {confidences['max_confidence']} ~ 최소 정확도: {confidences['min_confidence']}"
            if results_string:
                results_string += "\n"
            results_string += result_string
        
        return jsonify({'results': results_string})
    except ValueError as ve:
        return jsonify({'error': str(ve)}), 400
    except Exception as e:
        print(f'Error during prediction: {e}')
        return jsonify({'error': str(e)}), 500

@socketio.on('image')
def handle_image(data):
    try:
        image_data = base64.b64decode(data['image'])
        width = data['width']
        height = data['height']
        
        nparr = np.frombuffer(image_data, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # 두 번째 모델을 사용하여 이미지 분할
        results = model2(img, conf=0.1)  # 임계값을 0.1로 설정
        
        # 4leaf 여부 판단
        four_leaf_found = any('4leaf' in result.names[int(box.cls[0])] for result in results for box in result.boxes)
        
        response = {'four_leaf_found': four_leaf_found}
        print(f'Results: {response}')
        
        emit('response', response)
    except Exception as e:
        print(f'Error during detection: {e}')
        emit('error', {'error': str(e)})

@app.route('/detect', methods=['POST'])
def detect():
    try:
        data = request.get_json()
        image_data = base64.b64decode(data['image'])
        
        nparr = np.frombuffer(image_data, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # 두 번째 모델을 사용하여 이미지 분할
        results = model2(img, conf=0.1)  # 임계값을 0.1로 설정
        
        # 4leaf 여부 판단
        four_leaf_found = any('4leaf' in result.names[int(box.cls[0])] for result in results for box in result.boxes)
        
        response = {'four_leaf_found': four_leaf_found}
        print(f'Results: {response}')
        
        return jsonify(response)
    except Exception as e:
        print(f'Error during detection: {e}')
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    socketio.run(app, debug=True, host='192.168.100.20', port=7000)
