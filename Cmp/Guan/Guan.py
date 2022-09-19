from fileinput import filename
import random
from matplotlib.pyplot import hist
import numpy as np
import os
import queue

from tqdm import *
from load_file import load_file
from obtain_2DHIS import obtain_1D_histogram
from obtain_brightness import obtain_brightness
from pre_process_for_Guan import pre_process_for_Guan
from utils import bi2de, de2bi

def recover_Guan(img,S):
    width,height = img.shape
    
    # extract the 16 LSBs
    LSBs = np.zeros(shape=(16),dtype=int)
    for w in range(16):
        LSBs[w] = img[w,0]%2
        img[w,0] -= LSBs[w]

    left = bi2de(LSBs[:8])
    right = bi2de(LSBs[8:16])

    # histogram shifting
    payload = np.array([],dtype=int)
    for w in range(width):
        for h in range(height):
            if w < 16 and w >= 0 and h == 0:
                continue
            if img[w,h] < left-1:
                img[w,h] += 1
            elif img[w,h] == left or img[w,h] == left-1:
                payload=np.append(payload,left-img[w,h])
                img[w,h] = left
            elif img[w,h] == right or img[w,h] == right+1:
                payload=np.append(payload,img[w,h]-right)
                img[w,h] = right
            elif img[w,h] > right+1:
                img[w,h] -= 1

    left = bi2de(np.copy(payload[:8]))
    right = bi2de(np.copy(payload[8:16]))
    LSBs =np.copy(payload[16:32])

    # restore LSBs
    for w in range(16):
        img[w,0] += LSBs[w]
                
    # iteration
    for iteraion in range(S-1):

        # histogram shifting
        payload = np.array([],dtype=int)
        for w in range(width):
            for h in range(height):
                if img[w,h] < left-1:
                    img[w,h] += 1
                elif img[w,h] == left or img[w,h] == left-1:
                    payload=np.append(payload,left-img[w,h])
                    img[w,h] = left
                elif img[w,h] == right or img[w,h] == right+1:
                    payload=np.append(payload,img[w,h]-right)
                    img[w,h] = right
                elif img[w,h] > right+1:
                    img[w,h] -= 1

        # construct payload
        left = bi2de(np.copy(payload[:8]))
        right = bi2de(np.copy(payload[8:16]))

    return img

if __name__ == "__main__":
    
    # load image
    fileDir = r'your_path'
    # fileDir = r'D:\researches\Image CE\color images\lowContrastBP'
    # pathList = ['lena.bmp','house.bmp','airplane.bmp','peppers.bmp','goldhill.bmp','Splash.bmp','Sailboat on lake.bmp','baboon.bmp']
    # pathList = ['lena.bmp','peppers.bmp','Sailboat on lake.bmp']
    pathList = []
    for i in range(1,11):
        pathList.append('MCM'+str(i)+'.bmp')
    # for i in range(10,25):
    #     pathList.append('kodim'+str(i)+'.png')

    pbar = tqdm(desc="Image Enhancing" ,total=len(pathList)) # 进度条
    for path in pathList:
        embedding_bits = 0

        fn = os.path.join(fileDir,path)
        origin_img = load_file(fn)
        width,height,channel = origin_img.shape
        origin_img = np.asarray(origin_img,dtype=np.int32)

        max = np.zeros(shape=(width,height),dtype=np.int32)
        min = np.zeros(shape=(width,height),dtype=np.int32)
        median = np.zeros(shape=(width,height),dtype=np.int32)

        for i in range(width):
            for j in range(height):
                rgb = origin_img[i,j,:]
                order_index = np.argsort(rgb) # 得到排序后的索引
                min[i,j] = rgb[order_index[0]]
                median[i,j] = rgb[order_index[1]]
                max[i,j] = rgb[order_index[2]]

        # parameters setting
        S = 2
        left_brightness_original, right_brightness_original = obtain_brightness(max,width,height)

        # preprocessing
        max,median,min,max_origin,location_map_of_pre = pre_process_for_Guan(S,origin_img,width,height)

        # construct payload
        payload = queue.Queue()

        # hitogram modification
        for iteration in range(S-1):
            # print("--------------------iteration"+str(iteration+1)+"--------------------")
            
            left_brightness,right_brightness = obtain_brightness(max,width,height)
            diff_brightness1 = left_brightness-left_brightness_original
            diff_brightness2 = right_brightness-right_brightness_original 

            # obtain 1D histogram
            histogram = obtain_1D_histogram(max,width,height)

            # find the highest two bins
            highest_2 = np.argsort(histogram)[-2:]
            current_max = np.sort(histogram)[-2:]
            if current_max[0]+current_max[1] < 16:
                print("capacity is not enough!")
                break

            left = np.min(highest_2)
            right = np.max(highest_2)

            # histogram shifting and embedding    
            for w in range(width):
                for h in range(height):
                    if max[w,h] < left:
                        max[w,h] -= 1
                    elif max[w,h] == left: # embedding
                        if payload.empty():
                            if not location_map_of_pre.empty():
                                max[w,h] -= int(location_map_of_pre.get())
                            else:
                                max[w,h] -= random.randint(0,1) # random
                                embedding_bits += 1
                        else:
                            max[w,h] -= int(payload.get())
                    elif max[w,h] == right: # embedding
                        if payload.empty():
                            if not location_map_of_pre.empty():
                                max[w,h] += int(location_map_of_pre.get())
                            else:
                                max[w,h] += random.randint(0,1) # random
                                embedding_bits += 1
                        else:
                            max[w,h] += int(payload.get())
                    elif max[w,h] > right:
                        max[w,h] += 1

            # construct payload
            payload = queue.Queue()
            temp = de2bi(left,8)
            for i in range(8):
                payload.put(int(temp[i]))
            temp = de2bi(right,8)
            for i in range(8):
                payload.put(int(temp[i]))

        # print("--------------------end iteration--------------------")
        # obtain 1D histogram
        histogram = obtain_1D_histogram(max,width,height)
        for w in range(16):
            histogram[max[w,0]] -= 1

        # find the highest two bins
        highest_2 = np.argsort(histogram)[-2:]
        current_max = np.sort(histogram)[-2:]
        if current_max[0]+current_max[1] < 32:
            print("capacity is not enough!")

        left = np.min(highest_2)
        right = np.max(highest_2)

        for w in range(16):
            payload.put(max[w,0]%2)

        # histogram shifting and embedding
        for w in range(width):
            for h in range(height):
                if w < 16 and h == 0:
                    continue
                if max[w,h] < left:
                    max[w,h] -= 1
                elif max[w,h] == left: # embedding
                    if payload.empty():
                        if not location_map_of_pre.empty():
                            max[w,h] -= int(location_map_of_pre.get())
                        else:
                            max[w,h] -= random.randint(0,1) # random
                            embedding_bits += 1
                    else:
                        max[w,h] -= int(payload.get())
                elif max[w,h] == right: # embedding
                    if payload.empty():
                        if not location_map_of_pre.empty():
                            max[w,h] += int(location_map_of_pre.get())
                        else:
                            max[w,h] += random.randint(0,1) # random
                            embedding_bits += 1
                    else:
                        max[w,h] += int(payload.get())
                elif max[w,h] > right:
                    max[w,h] += 1

        # construct payload
        if not location_map_of_pre.empty():
            print(path+"location map embedding failed!")
     
        else:
            # payload = queue.Queue()
            temp = de2bi(left,8)
            for i in range(8):
                payload.put(int(temp[i]))
            temp = de2bi(right,8)
            for i in range(8):
                payload.put(int(temp[i]))

            # the last iteration replacement
            for i in range(16):
                max[i,0] -= max[i,0]%2
                max[i,0] += int(payload.get())

            # recovery
            # rec_max = recover_Guan(max,S)
            # if (max_origin==rec_max).all():
                # print("recover successfully!")

            # modify median and min with max
            diff = max - max_origin
            median += diff
            min += diff

            # merge max median min
            CE_img = np.copy(origin_img)

            for w in range(width):
                for h in range(height):
                    rgb = np.copy(origin_img[w,h,:])
                    order_index = np.argsort(rgb) # 得到排序后的索引

                    rgb[order_index[0]] = min[w,h]
                    rgb[order_index[1]] = median[w,h]
                    rgb[order_index[2]] = max[w,h]

                    CE_img[w,h,:] = np.copy(rgb)

            # convert to BGR mode
            for w in range(width):
                for h in range(height):
                    temp = CE_img[w,h,0]
                    CE_img[w,h,0] = CE_img[w,h,2]
                    CE_img[w,h,2] = temp
            CE_img = np.uint8(CE_img)
            # cv2.imshow("CE_img",CE_img)
            # cv2.waitKey(0)
            # output_path = r'lowContrastVersion0507'
            output_path = r'your_save_path'
            # output_path = os.path.join(output_path,"Guan")
            # output_path = os.path.join("Guan",str(S)+"-"+path)
            # cv2.imwrite(output_path,CE_img)
            pbar.update(1)
    pbar.close()
