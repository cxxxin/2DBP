import cv2
import numpy as np
import os

# 转为rgb图像
def load_file(path):
    img = cv2.imread(path,1)
    img = cv2.cvtColor(img,cv2.COLOR_BGR2RGB)
    return img