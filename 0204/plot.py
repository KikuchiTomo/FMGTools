import matplotlib.pyplot as plt 
import numpy as np 
import pandas as pd 
import utils as ut
import pickle as pk

# 入力ディレクトリ: s1_0204_press
# スプリットに使うインデックス: 0

PATH = 's1_0204_press'
INDEX = 0

fmg = ut.load_fmg(PATH)[INDEX]['data']

time = int(fmg[0][-1])

duration = time - 5 # 正味の時間 (冒頭5秒がごみ)

Sn = len(fmg[0])
Nd = duration // 4
Ns = Nd // 5

Fs = Sn / fmg[0][-1]
Nf = int(Fs * 4)

x = np.zeros((Nd, len(fmg), Nf//8))
y = np.zeros(Nd)

for i in range(Nd):
    e = fmg[:, int(Nf*i):int(Nf*(i+1))]  

    sf = (Nf//16*7)
    ef = (Nf//16*9+1)
    t = e[:, sf:ef]       

    x[i,:,:] = t
    y[i] = i % 5
    #for j in range(14):
    #    plt.plot(t[0], t[j+1], label=f"{j}")
    #plt.title(f"{y[i]}")
    #print(i, i%5, y[i])
    #plt.legend()
    #plt.show()

hash = {
    'x': x,
    'y': y
}

with open("splits.bin", "wb") as f:
    pk.dump(hash, f)