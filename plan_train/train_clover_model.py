import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import os

# 데이터 디렉토리 설정
base_dir = 'data_clover/test'
train_dir = 'data_clover/train'
validation_dir = 'data_clover/valid'

# 이미지 데이터 제너레이터 설정
train_datagen = ImageDataGenerator(
    rescale=1.0/255.0,
    rotation_range=40,
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.2,
    zoom_range=0.2,
    horizontal_flip=True,
    fill_mode='nearest'
)

val_datagen = ImageDataGenerator(rescale=1.0/255.0)

# 데이터 제너레이터 생성
train_generator = train_datagen.flow_from_directory(
    train_dir,
    target_size=(150, 150),
    batch_size=20,
    class_mode='binary'
)

validation_generator = val_datagen.flow_from_directory(
    validation_dir,
    target_size=(150, 150),
    batch_size=20,
    class_mode='binary'
)

# 모델 정의
model = tf.keras.models.Sequential([
    tf.keras.layers.Conv2D(32, (3, 3), activation='relu', input_shape=(150, 150, 3)),
    tf.keras.layers.MaxPooling2D(2, 2),
    tf.keras.layers.Conv2D(64, (3, 3), activation='relu'),
    tf.keras.layers.MaxPooling2D(2, 2),
    tf.keras.layers.Conv2D(128, (3, 3), activation='relu'),
    tf.keras.layers.MaxPooling2D(2, 2),
    tf.keras.layers.Conv2D(128, (3, 3), activation='relu'),
    tf.keras.layers.MaxPooling2D(2, 2),
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dropout(0.5),
    tf.keras.layers.Dense(512, activation='relu'),
    tf.keras.layers.Dense(1, activation='sigmoid')
])

# 모델 컴파일
model.compile(
    loss='binary_crossentropy',
    optimizer=tf.keras.optimizers.RMSprop(learning_rate=1e-4),
    metrics=['accuracy']
)

# 모델 학습
history = model.fit(
    train_generator,
    steps_per_epoch=150,
    epochs=200,
    validation_data=validation_generator,
    validation_steps=100
)

# 모델 저장
model.save('clover.h5')

# 모델을 TensorFlow Lite 포맷으로 변환
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# TensorFlow Lite 모델 저장
with open('clover.tflite', 'wb') as f:
    f.write(tflite_model)

# 라벨 파일 저장
class_indices = train_generator.class_indices
with open('clover_labels.txt', 'w') as f:
    for label, index in class_indices.items():
        f.write(f"{index} {label}\n")