import cv2
import numpy as np
from numpy.core.fromnumeric import shape
from numpy.lib.histograms import histogram
from numpy.lib.index_tricks import index_exp

# 计算2D直方图
def obtain_2D_histogram(img,width,height):
    histogram = np.zeros(shape=(256,256),dtype=np.int32)

    for i in range(0,width,2):
        for j in range(height):
            index1 = img[i,j]
            index2 = img[i+1,j]
            histogram[index1,index2] += 1

    return histogram

# 计算一维直方图
def obtain_1D_histogram(img,width,height):
    histogram = np.zeros(shape=256,dtype=np.int32)

    for w in range(width):
        for h in range(height):
            index = img[w,h]
            histogram[index] += 1

    return histogram