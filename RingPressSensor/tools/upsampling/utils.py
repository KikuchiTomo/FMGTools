import os
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import pprint
from collections import deque
from scipy import signal

def arv(data, length = 512):
    l = length
    m = makeTriangleFir(l)
    j = np.abs(data)
    o = idealPeakHoldNaive(j, l)
    b = signal.lfilter(m, 1, o)
    b0 = (b - b.mean()) / b.std()
    n = np.roll(b, -length)
    return n

def ls(url):
    paths = []
    pwd = os.path.abspath(url)    
    fnames = os.listdir(url)
    for fname in fnames:
       paths.append(pwd + "/" + fname)       
    return paths

def get_info_from_fpath(path):
    fname = path.split('/')[-1].split('.')[0]
    raw = fname.split('_')
    infos = {}
    infos['fpath']    = path
    infos['dataset']  = int(raw[0])
    infos['index']    = int(raw[1])
    infos['person']   = raw[2]
    infos['finger']   = raw[3].split('-')[0]
    infos['movement'] = raw[3].split('-')[-1]
    infos['time']     = datetime.strptime(raw[4], "%Y-%m-%d-%H-%M-%S")
    infos['fname']    = fname
    # print(f"started time: {raw[4]}")
    return infos

def reformat_fmg(mat, chs=range(14)):
    count = len(chs)
    rows = []
    minlen = mat[mat[1] == 0].drop(columns=1).to_numpy().T.shape[1]
    
    for i in chs:
        row = mat[mat[1] == i].drop(columns=1).to_numpy().T
        if minlen > row.shape[1]:
            minlen = row.shape[1]
        rows.append(row)
        
    datas = np.zeros((count + 1, minlen))
    
    for i in range(count+1):
        if i==0:
            datas[i] = rows[i][0][:minlen] - rows[i][0][0]
        else:
            datas[i] = rows[i-1][1][:minlen]
    datas2 = np.zeros((count + 1, minlen))
    
    datas2[:8] = datas[:8]
    for i in range(7):
        index = 6 - i
        datas2[index+7+1] = datas[7+i+1]
    return datas2
        
def load_fmg(url):
    paths = ls(url)
    datas = []
    for path in paths:
        info = get_info_from_fpath(path)
        df = pd.read_csv(path, header=None)
        data = reformat_fmg(df)    
        info['data'] = data
        datas.append(info)
    return datas

def load_fmg_numpy(path):
    df = pd.read_csv(path, header=None)
    data = reformat_fmg(df)       
    return data

def load_emg(path, offset = 0.0):
    index = 0
    time_raw = None
    with open(path, "r") as f:
        for line in f:
            if index == 1:
                time_raw = line
                break
            index += 1
    time_str = time_raw.split(',')[-1].split("\n")[0]
    
    time = datetime.strptime(time_str, " %Y/%m/%d %H:%M:%S") - timedelta(seconds=offset)
    print(f"Time(String) {time_str} Time(Object) {time}")
    ary = pd.read_csv(path, header=None, skiprows=7).to_numpy().T
    needs = np.zeros((5, ary.shape[1]))
    needs[0] = ary[0]
    needs[1] = ary[1]
    needs[2] = ary[3]
    needs[3] = ary[5]
    needs[4] = ary[7]

    info = {}
    info['time'] = time
    info['data'] = needs
    info['fname'] = path
    return info

def get_info_from_fpaths(fnames):
    infos = []
    for fname in fnames:
        infos.append(get_info_from_fpath(fname))
    return infos
    
def load_emg_and_fmg(epath, fpath):
    epaths = ls(epath)
    fpaths = ls(fpath)

    einfos = get_info_from_fpaths(epaths)
    finfos = get_info_from_fpaths(fpaths)    

    infos = []

    for einfo in einfos:
        tmp = {}
        tmp['emg'] = einfo
        
        for finfo in finfos:
            ed = einfo['dataset']
            ei = einfo['index']
            ep = einfo['person']
            fd = finfo['dataset']
            fi = finfo['index']
            fp = finfo['person']
            if ed == fd and ei == fi and ep == fp:                
                tmp['fmg'] = finfo
                infos.append(tmp)
                break

    datas = []
    for info in infos:
        emg = info['emg']
        fmg = info['fmg']

        emg_data = pd.read_csv(emg['fpath'], header=None).to_numpy().T
        fmg_data = load_fmg_numpy(fmg['fpath'])

        #emg_data[0] -= emg_data[0][0]
        
        info['emg']['data'] = emg_data
        info['fmg']['data'] = fmg_data

        datas.append(info)

    return datas

def biquad(z, a, b):       
    return (((b[0] / a[0]) + ((b[1] / a[0]) * z[1]) + ((b[2] / a[0]) * z[2])) / (1.0 + ((a[1] / a[0]) * z[1]) + ((a[2] / a[0]) * z[2])))

def lowpass(datas, fc, fs = 2148.1481 ):
    z = np.zeros(3)
    b = np.zeros(3)
    a = np.zeros(3)
    
    w = 2 * np.pi * ( fc / fs )
    Q = 0.5
    alpha = np.sin(w) / (2.0 * Q)
    
    b[0] = (1 - np.cos(w)) / 2.0
    b[1] =  1 - np.cos(w)
    b[2] = (1 - np.cos(w)) / 2.0
    a[0] = 1 + alpha
    a[1] = - 2.0 * np.cos(w)
    a[2] = 1 - alpha
    nn = np.zeros(datas.shape)
    for i in range(len(datas)):
         z[2] = z[1]
         z[1] = z[0]
         z[0] = datas[i]
         nn[i] = biquad(z, a, b)
    return nn
        
    
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal


def butter_lowpass(lowcut, fs, order=4):
    nyq = 0.5 * fs
    low = lowcut / nyq
    b, a = signal.butter(order, low, btype='low')
    return b, a

def butter_lowpass_filter(x, lowcut, fs, order=4):
    b, a = butter_lowpass(lowcut, fs, order=order)
    y = signal.filtfilt(b, a, x)
    return y

def idealPeakHoldNaive(sig, holdtime: int):
    out = np.empty(len(sig))
    buffer = deque([0 for _ in range(holdtime)])
    counter = 0
    for i in range(len(sig)):
        buffer.append(abs(sig[i]))
        buffer.popleft()
        out[i] = max(buffer)
    return out

def peakHoldForward(sig, holdtime, reset=0):
    """
    holdtime の単位はサンプル数。
    最後に最大値が更新されてから holdtime サンプル後に hold の値をリセットする。
    """
    out = np.empty(len(sig))
    hold = reset
    counter = 0
    for i in range(len(sig)):
        if counter > 0:  # 注意: 比較に >= を使うとホールド時間が 1 サンプル延びる。
            counter -= 1
        else:
            hold = reset
        if hold <= sig[i]:  # 注意: カウンタをリセットしたいので <= で比較。
            hold = sig[i]
            counter = holdtime
        out[i] = hold
    return out

def makeTriangleFiridealPeakHoldNaive(sig, holdtime: int):
    out = np.empty(len(sig))
    buffer = deque([0 for _ in range(holdtime)])
    counter = 0
    for i in range(len(sig)):
        buffer.append(abs(sig[i]))
        buffer.popleft()
        out[i] = max(buffer)
    return out

def peakHoldForward(sig, holdtime, reset=0):
    """
    holdtime の単位はサンプル数。
    最後に最大値が更新されてから holdtime サンプル後に hold の値をリセットする。
    """
    out = np.empty(len(sig))
    hold = reset
    counter = 0
    for i in range(len(sig)):
        if counter > 0:  # 注意: 比較に >= を使うとホールド時間が 1 サンプル延びる。
            counter -= 1
        else:
            hold = reset
        if hold <= sig[i]:  # 注意: カウンタをリセットしたいので <= で比較。
            hold = sig[i]
            counter = holdtime
        out[i] = hold
    return out

def makeTriangleFir(delay):
    """delay は 2 より大きい整数。"""
    fir = np.interp(
        np.linspace(0, 1, delay + 1),
        [0, 0.5, 1],
        [0, 1, 0],
    )
    return fir / np.sum(fir)
