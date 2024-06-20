import os

def create_label_file(data_dir, output_file):
    labels = sorted(os.listdir(data_dir))
    with open(output_file, 'w') as f:
        for i, label in enumerate(labels):
            f.write(f"{i} {label}\n")
    print(f"Labels saved to {output_file}")

# 데이터 디렉토리 설정
plant_disease_train_dir = 'data_plan/train'
clover_detection_train_dir = 'data_clover/train'

# 라벨 파일 생성
create_label_file(plant_disease_train_dir, 'plant_labels.txt')
create_label_file(clover_detection_train_dir, 'clover_labels.txt')
