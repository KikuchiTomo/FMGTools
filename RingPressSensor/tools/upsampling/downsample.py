import pickle as pk 
import numpy as np 
import pandas as pd
import matplotlib.pyplot as plt
from scipy import interpolate

datas = None
with open("splited_data.pk", "rb") as f:
    datas = pk.load(f)

if datas == None:
    exit()

num = 256 * 45
xs_resample = np.zeros((len(datas), 15, num))
ys_resample = np.zeros((len(datas), 6, num))
xs_resample2 = np.zeros((len(datas), 14, num))
ys_resample2 = np.zeros((len(datas), 5, num))
main_i = 0


for data in datas:
    x = data['x']
    y = data['y']

    xl = x.shape[1]
    yl = y.shape[1]
    
    time_duration = x[0][-1] - x[0][0]
    print(y.shape[1]/time_duration)
    print(x.shape[1]/time_duration)
    #exit()
    x_resample = np.zeros((15, num))        
    for i in range(14):
        f = interpolate.interp1d(x[0], x[i+1], kind='cubic')
        x_resample[0] = np.linspace(x[0][0], x[0][-1], num)
        print(x[0][0], x[0][-1])
        x_resample[i+1] = f(x_resample[0])

    y_resample = np.zeros((6, num))    
    for i in range(5):
        f = interpolate.interp1d(y[0], y[i+1], kind='cubic')
        y_resample[0] = np.linspace(y[0][0], y[0][-1], num)
        print(y[0][0], y[0][-1])
        y_resample[i+1] = f(y_resample[0])

    #print(x.shape[1] / time_duration, y.shape[1] / time_duration, yl / xl)
    print(x_resample.shape, y_resample.shape)
    print(y_resample[1])

    ys_resample[main_i] = y_resample
    xs_resample[main_i] = x_resample

    ys_resample2[main_i] = y_resample[1:]
    xs_resample2[main_i] = x_resample[1:]

    main_i += 1
    

plot_i = 13

#for i in range(5):

# for plot_i in range(26):
#     plt.plot(ys_resample[plot_i][0], ys_resample[plot_i][2], color="red")
#     plt.plot(ys_resample[plot_i][0], ys_resample[plot_i][3], color="green")

#     for i in range(14):
#         plt.plot(xs_resample[plot_i][0], xs_resample[plot_i][i+1], color="blue")

#     plt.grid()
#     plt.xlabel("time [sec]")
#     plt.ylabel("amplitude")
#     plt.show()
    
hash = {}
hash['x'] = xs_resample
hash['y'] = ys_resample

hash2 = {}
hash2['x'] = xs_resample2
hash2['y'] = ys_resample2
with open("resampled_data.pk", "wb") as f:
    pk.dump(hash, f)

with open("resampled_data_without_time.pk", "wb") as f:
    pk.dump(hash2, f)