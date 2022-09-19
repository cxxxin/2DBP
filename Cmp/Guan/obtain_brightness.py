import cv2
import numpy as np
import os

# 计算亮度值
def obtain_brightness(img,width,height):
    left_brightness = 0
    right_brightness = 0

    for i in range(0,width,2):
        for j in range(height):
            left_brightness += img[i,j]
            right_brightness += img[i+1,j]

    left_brightness  = float(left_brightness)*2/float(width*height)
    right_brightness = float(right_brightness)*2/float(width*height)

    return left_brightness,right_brightness