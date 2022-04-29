import os
import json
import random
import logging
import numpy as np

from flask import Flask, request

app = Flask(__name__)

def save_data_frame(label, df):

    arr = np.array(df)

    dir_path = os.path.dirname(os.path.realpath(__file__))
    letter_path = os.path.join(dir_path, "..", "data", label) 
    if not os.path.isdir(letter_path):
        os.makedirs(letter_path)

    file_count = len(os.listdir(letter_path))
    target_dir_path = os.path.join(letter_path, f"{label}{file_count}") 
    if not os.path.isdir(target_dir_path):
        os.makedirs(target_dir_path)

    for (idx, a) in enumerate(arr):
        file_path = os.path.join(target_dir_path, f"{label}{file_count}_f{idx}")
        np.save(file_path, a)



@app.route('/ping', methods=['GET'])
def pingHandler():
    print("ping pong")

    df = [
        [ random.uniform(0, 1) for _ in range(126) ]
        for _ in range(10)
    ]

    arr = np.array(df)

    dir_path = os.path.dirname(os.path.realpath(__file__))

    letter_path = os.path.join(dir_path, "..", "data", label) 
    if not os.path.isdir(letter_path):
        os.makedirs(letter_path)

    file_count = len(os.listdir(letter_path))
    target_dir_path = os.path.join(letter_path, f"{label}{file_count}") 
    if not os.path.isdir(target_dir_path):
        os.makedirs(target_dir_path)


    for (idx, a) in enumerate(arr):
        file_path = os.path.join(target_dir_path, f"{label}{file_count}_f{idx}")
        np.save(file_path, a)

    return {
        'key': 10
    }

@app.route('/save', methods=['POST'])
def saveHandler():

    try:
        for (label, dataframes) in request.json.items():
            for frame in dataframes:
                save_data_frame(label, frame)

        return {
            'status': 'success'
        }
    except Exception as e:
        logging.error(e, exc_info=True)
        return {
            'status': 'error'
        }



    # {
         # "A": [
         #    [
         #        10 x [
         #            21 x 3 
         #        ]
         #    ] # DF1 
         # ]


    #   frames: [
    #       {
    #           label: [],
    #           label2: []
    #       }
    #   ]
    # }


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')