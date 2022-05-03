import cv2
import numpy as np
# import mediapipe as mp
from tensorflow.keras.models import load_model
from matplotlib import pyplot as plt
import os
from tensorflow.keras.utils import to_categorical
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
from tensorflow.keras.callbacks import TensorBoard


# print("here")

def getClasses(gesture_file):
	f = open('gesture.names', 'r')
	cn = f.read().split('\n')
	f.close()
	return cn

classNames = getClasses('gesture.names')
label_map = {label:num for num, label in enumerate(classNames)}
dir_path = os.path.dirname(os.path.realpath(__file__))
res_dir = os.path.join(dir_path, "migrate-data")
# res_dir = "/Users/williambacon/Desktop/ASL_DataCapture/server/data"
print(res_dir)

sequence_length = 10
sequences, labels = [], []

for action in classNames:
	class_dir_r = os.path.join(res_dir, action)
	values_r = os.listdir(class_dir_r)
	for vr in values_r:
		if vr == '.DS_Store':
			continue
		window = []
		for frame_num in range(sequence_length):
			# print(os.path.join(res_dir, action, vr, "{}_f{}.npy".format(vr,frame_num)))
			targ_path = os.path.join(res_dir, action, vr, "{}_f{}.npy".format(vr,frame_num))
			if os.path.exists(targ_path):
				res = np.load(targ_path)
				window.append(res)
		if len(window) == sequence_length:
			sequences.append(window)
			labels.append(label_map[action])

		# for frame_num in range(sequence_length):
		# 	# print(os.path.join(res_dir, action, vr, "{}_f{}.npy".format(vr,frame_num)))
		# 	res = np.load(os.path.join(res_dir, action, vr, "{}_f{}.npy".format(vr,frame_num)))
		# 	# print(res)
		# 	window.append(res)
		# sequences.append(window)
		# labels.append(label_map[action])

# print(np.array(sequences).shape)

X = np.array(sequences)
y = to_categorical(labels).astype(int)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.05)
log_dir = os.path.join('Logs')
tb_callback = TensorBoard(log_dir=log_dir)
actions = np.array(classNames)

model = Sequential()
model.add(LSTM(64, return_sequences=True, activation='relu', input_shape=(10,126) ))
model.add(LSTM(128, return_sequences=True, activation='relu'))
model.add(LSTM(64, return_sequences=False, activation='relu'))
model.add(Dense(64, activation='relu'))
model.add(Dense(32, activation='relu'))
model.add(Dense(actions.shape[0], activation='softmax'))

res = [.7, 0.2, 0.1]

model.compile(optimizer='Adam', loss='categorical_crossentropy', metrics=['categorical_accuracy'])

model.fit(X_train, y_train, epochs = 8, callbacks=[tb_callback])
res = model.predict(X_test)
print(res)
model.save('shitpost_model')
print(actions[np.argmax(res[2])])
print(actions[np.argmax(y_test[2])])











