import tensorflow as tf
from tensorflow import keras

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

# 모델의 가중치를 불러옵니다.
model.load_weights('clover.h5')

# TensorFlow SavedModel 포맷으로 모델 저장
export_path = 'Microsoft.PowerShell.Core\FileSystem::\\DESKTOP-L5B7H3F\drow_face\lucky_bitch_project\plan_train\saved_model'
 
 

# SavedModel을 TensorFlow Lite 포맷으로 변환
converter = tf.lite.TFLiteConverter.from_saved_model(export_path)
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS,
                                       tf.lite.OpsSet.SELECT_TF_OPS]
tflite_model = converter.convert()

# 변환된 TensorFlow Lite 모델 저장
with open('Microsoft.PowerShell.Core\FileSystem::\\DESKTOP-L5B7H3F\drow_face\lucky_bitch_project\plan_train>\clover.tflite', 'wb') as f:
    f.write(tflite_model)
