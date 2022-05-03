import coremltools as ct
import numpy as np
import os
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense


print(tf.__version__)


def getClasses(gesture_file):
	f = open('gesture.names', 'r')
	cn = f.read().split('\n')
	f.close()
	return cn

classNames = getClasses("gesture.names")


actions = np.array(classNames)
# print(classNames)



model = Sequential()
model.add(LSTM(64, return_sequences=True, activation='relu', input_shape=(10,126) ))
model.add(LSTM(128, return_sequences=True, activation='relu'))
model.add(LSTM(64, return_sequences=False, activation='relu'))
model.add(Dense(64, activation='relu'))
model.add(Dense(32, activation='relu'))
model.add(Dense(actions.shape[0], activation='softmax'))


model.load_weights('shitpost_model')

# model2 = tf.saved_model.load("/Users/williambacon/Desktop/ASL_app/unclassified_model")
# tf_model_name = "/Users/williambacon/Documents/ASL_iOS/mediapipe/mediapipe/examples/ASLHD/unclassified.tflite"
# tf_model_converter = tf.lite.TFLiteConverter.from_keras_model(model2)
# tf_lite_model = tf_model_converter.convert()
# open(tf_model_name,"wb").write(tf_lite_model)

classifier_config = ct.ClassifierConfig(classNames)
mlmodel = ct.convert(model,classifier_config=classifier_config)
# mlmodel = ct.convert(model)
# spec = mlmodel.get_spec()
print(mlmodel)
mlmodel.save('shitpost.mlmodel')


# print("no issues")