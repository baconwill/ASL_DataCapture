import numpy as np
import os

dir_path = os.path.dirname(os.path.realpath(__file__))
current_data_dir = os.path.join(dir_path, "data")

def transform_dataframe(frame):
    data = frame[:63]
    padding = frame[63:]

    x = frame[:63:3]
    y = frame[1:63:3]
    z = frame[2:63:3]

    left = min(x)
    right = max(x)
    top = min(y)

    image_width = 1080.0

    perc_width = right - left
    width_in_image = image_width * (right - left)

    if width_in_image == 0:
        return False

    if perc_width < 0.1:
        return False

    scale_factor = 400.0 / width_in_image

    for (idx, val) in enumerate(x):
        x[idx] = round(scale_factor * (val - left), 2)

    for (idx, val) in enumerate(y):
        y[idx] = round(scale_factor * (val - top), 2)

    for (idx, _) in enumerate(y):
        z[idx] = 0

    return True



def create_new_datafile(orig_path, files):
    targ_path = orig_path.replace('/data/', '/migrate-data/')
    if not os.path.exists(targ_path):
        os.makedirs(targ_path)

    count = 0
    for file in files:
        orig_file_path = os.path.join(orig_path, file)
        targ_file_path = os.path.join(targ_path, file)
        frame = np.load(orig_file_path)
        should_export = transform_dataframe(frame)
        if should_export:
            count += 1
            np.save(targ_file_path, frame)

    return count, len(files)
        
count = 0
total = 0
for root, dirs, files in os.walk(current_data_dir, topdown=True):
    if len(dirs) != 0:
        continue

    if "/Heart/" in root:
        succ, target = create_new_datafile(root, files)
        count += succ
        total += target

print(f"included {count} out of {total}")
