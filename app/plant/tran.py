import tensorflow as tf

# Load the models
clover_model = tf.keras.models.load_model('assets/clover_model.h5')
plant_model = tf.keras.models.load_model('assets/plant_model.h5')

# Convert the models to TFLite format
def convert_to_tflite(model, model_name):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    tflite_model_path = f"D:\AI\study\project\lucky_bitch_project\app\plant\assets{model_name}.tflite"
    
    # Save the converted model
    with open(tflite_model_path, 'wb') as f:
        f.write(tflite_model)
    return tflite_model_path

clover_tflite_model_path = convert_to_tflite(clover_model, "clover_model")
plant_tflite_model_path = convert_to_tflite(plant_model, "plant_model")

clover_tflite_model_path, plant_tflite_model_path
