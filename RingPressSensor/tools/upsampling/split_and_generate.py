import numpy as np 
import pandas as pd 
import utils as u
import os
import datetime
import matplotlib.pyplot as plt
import pickle as pk

s_y_path = "s1_1206_press"
s_x_path = "s1_1206_ring_press"
d_y_path = "press"
d_x_path = "ring_press"

s_x_files = os.listdir(s_x_path)
s_y_files = os.listdir(s_y_path)

fmg_list = []
xmax = 0.0
xmin = 1000000000000000.0
for s_x_file in s_x_files:
    s_x_file_path = s_x_path + "/" + s_x_file

    data = u.load_fmg_numpy(s_x_file_path)
    info = u.get_info_from_fpath(s_x_file_path)

    xmax_tmp = np.max(data[1:])
    xmin_tmp = np.min(data[1:])

    if xmax < xmax_tmp:
        xmax = xmax_tmp
    
    if xmin > xmin_tmp:
        xmin = xmin_tmp    

xmax = 0.4
for s_x_file in s_x_files:
    s_x_file_path = s_x_path + "/" + s_x_file

    data = u.load_fmg_numpy(s_x_file_path)
    info = u.get_info_from_fpath(s_x_file_path)
    data[1:] = (data[1:] - xmin) / (xmax - xmin)
    for i in range(14):
        data[i+1][data[i+1] > 1.0] = 1.0
    
    print(xmax, xmin)
    hash = {}
    hash['path'] = s_x_file_path   
    hash['name'] = s_x_file
    hash['start_time'] = info['time'] + datetime.timedelta(seconds=data[0][0])
    hash['end_time'] = info['time'] + datetime.timedelta(seconds=data[0][-1])
    hash['data'] = data
    fmg_list.append(hash)

s_y_file_path = s_y_path + "/" + s_y_files[0]

y_datas = pd.read_csv(s_y_file_path, header=None).to_numpy().T
y_datas[0] = (y_datas[0] - y_datas[0][0]) / 1000.0
y_max = np.max(y_datas[1:])

# センサの不具合. よう修正
y_min = 0.045 #np.min(y_datas[1:])
y_datas[1:] = (y_datas[1:] - y_min) / np.abs(y_max - y_min)
y_datas[1][y_datas[1] < 0] = 0
y_datas[2][y_datas[2] < 0] = 0
y_datas[3][y_datas[3] < 0] = 0
y_datas[4][y_datas[4] < 0] = 0
y_datas[5][y_datas[5] < 0] = 0


y_time = datetime.datetime(2023, 12, 6, 2, 43, 25, 0)
y_datas[0] += y_time.timestamp()

indexes = []
for fmg in fmg_list:
    s = fmg['start_time'].timestamp()
    e = fmg['end_time'].timestamp()
    hash = {}
    print(s, e)
    for i in range(len(y_datas[0]) - 1):
        timestamp0 = y_datas[0][i]
        timestamp1 = y_datas[0][i+1]

        if timestamp0 <= s and timestamp1 >= s:
            hash['start_index'] = i

        if timestamp0 <= e and timestamp1 >= e:
            hash['end_index'] = i
            break
    indexes.append(hash)
    print(hash)

splited = []
for i in range(len(indexes)):
    index = indexes[i]
    fmg = fmg_list[i]

    hash = {}
    y_index_s = index['start_index']
    y_index_e = index['end_index']
  
    print(y_datas.shape, y_index_s,y_index_e)
    yy = y_datas.T[y_index_s:y_index_e].T
    yy[0] -= yy[0][0]
    hash['y'] = yy    
    hash['x'] = fmg['data']
    hash['start_time'] = fmg['start_time']
    hash['name'] = fmg['name'].split('.')[0]    
    splited.append(hash)

with open("splited_data.pk", "wb") as f:
    pk.dump(splited, f)