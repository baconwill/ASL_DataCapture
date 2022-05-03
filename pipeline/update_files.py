import cv2
import numpy as np
import mediapipe as mp
from matplotlib import pyplot as plt
import os
import configparser




def removeFolder(folder_dir):
	content = os.listdir(folder_dir)
	# destroy content of folder recursively
	for item in content:
		item_dir = os.path.join(folder_dir,item)
		if os.path.isdir(item_dir):
			# if it's a folder recurse through
			removeFolder(item_dir)
		else:
			# otherwise destroy and keep on chuggin'
			os.remove(item_dir)
	# destroy current folder and return
	os.rmdir(folder_dir)
	return


# todo:
# - get file path for start and end directories
def getDataConfig():
	parser = configparser.ConfigParser()
	parser.read('config.settings')
	start = parser.get('file_move', 'start_directory')
	end = parser.get('file_move', 'end_directory')
	mc = parser.getboolean('file_move','move_check')
	return start, end ,mc


# - for each letter-folder in starting directory:
def move_files(start_dir, end_dir):
	start_gestures = [i for i in os.listdir(start_dir) if  i != '.DS_Store']
	end_gestures = [i for i in os.listdir(end_dir) if  i != '.DS_Store']
	for sg in start_gestures:
		# simple move: files and file-folders don't need to be renamed
		# if sg not in end_gestures:
		# 	# create new end-gesture folder
		# 	# sg_path = os.path.join(start_dir,sg)
		# 	# eg_path = os.path.join(end_dir,sg)
		# 	os.mkdir(eg_path)
		# 	file_folders =  [i for i in os.listdir(sg_path) if  i != '.DS_Store']
		# 	for file_folder in file_folders:
		# 		end_ff_path = os.path.join(eg_path, file_folder)
		# 		start_ff_path = os.path.join(sg_path, file_folder)
		# 		os.mkdir(end_ff_path)
		# 		data_files = [i for i in os.listdir(start_ff_path) if  i != '.DS_Store']
		# 		for file in data_files:
		# 			print(file)
		# 			end_file_path = os.path.join(end_ff_path, file)
		# 			start_file_path = os.path.join(start_ff_path, file)
		# 			os.rename(start_file_path, end_file_path)
		# 	removeFolder(sg_path)
		# else:
		sg_path = os.path.join(start_dir,sg)
		eg_path = os.path.join(end_dir,sg)
		
		if sg not in end_gestures:
			os.mkdir(eg_path)
		file_folders =  [i for i in os.listdir(sg_path) if  i != '.DS_Store']
		end_folders =  [i for i in os.listdir(eg_path) if  i != '.DS_Store']
		count_val = len(end_folders)
		for file_folder in file_folders:
			new_ff = sg + str(count_val)
			end_ff_path = os.path.join(eg_path, new_ff)
			start_ff_path = os.path.join(sg_path, file_folder)
			os.mkdir(end_ff_path)
			data_files = [i for i in os.listdir(start_ff_path) if  i != '.DS_Store']
			for file in data_files:
				print(file)
				new_file = new_ff + "_" + file.split("_")[1]
				end_file_path = os.path.join(end_ff_path, new_file)
				start_file_path = os.path.join(start_ff_path, file)
				os.rename(start_file_path, end_file_path)
			count_val+=1
		removeFolder(sg_path)





# 	- if end directory doesnt have equivalent folder: make one
#   - for each file-folder in letter-folder:
# 		- if end directory doesnt have equivalent folder: make one
# 		- else: make folder with updated name 
# 		- for each file in file-folder:
# 			- name and move based on file-folder name





start_dir, end_dir, move_check = getDataConfig()
if not move_check:
	move_files(start_dir,end_dir)