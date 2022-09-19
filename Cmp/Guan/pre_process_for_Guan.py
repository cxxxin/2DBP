import numpy as np
import queue
from obtain_2DHIS import obtain_1D_histogram
from utils import record

def pre_process_for_Guan(iteration_max,img,width,height):
    # print("----------------------preprocessing---------------------------")
    
    # obtain max median min
    # 在每个像素点上将三个通道分为MAX MEDIAN MIN
    max = np.zeros(shape=(width,height),dtype=np.int32)
    min = np.zeros(shape=(width,height),dtype=np.int32)
    median = np.zeros(shape=(width,height),dtype=np.int32)

    for i in range(width):
        for j in range(height):
            rgb = np.copy(img[i,j,:])
            order_index = np.argsort(rgb) # 得到排序后的索引
            min[i,j] = rgb[order_index[0]]
            median[i,j] = rgb[order_index[1]]
            max[i,j] = rgb[order_index[2]]
    max_origin = np.copy(max) # copy

    if iteration_max == 0:
        return max,median,min,max_origin,queue.Queue()

    # 计算1D直方图
    histogram = obtain_1D_histogram(max,width,height)

    # 初始化location map
    location_map = queue.Queue()
    location_map_max = queue.Queue() # 暂存max通道上的操作
    location_map = record(location_map,iteration_max,7)

    # print("----------------------find empty bins and move them in max-----------------")
    current_bin = -1
    # 空出左边
    lm_l = []
    num_of_empty_l = 0
    empty_bins_map = queue.Queue() # 一开始哪里有empty bins
    destination_bin = 0 # 把对应的empty bins移到什么位置就停止
    for i in range(128):
        if histogram[i] == 0 and num_of_empty_l < iteration_max: # 左移到最左or左边已有0为止
            empty_bins_map.put(i)
            num_of_empty_l += 1

    # 改变max中所有符合条件的值
    while not empty_bins_map.empty():
        current_bin = empty_bins_map.get() # 找到的empty bin的值
        lm_l.append(current_bin)

        for w in range(width):
            for h in range(height):
                if max[w,h]<current_bin and max[w,h]>=destination_bin:
                        max[w,h] += 1
        
        destination_bin += 1
    histogram = obtain_1D_histogram(max,width,height) # update histogram of max

    # 空出右边
    lm_r = []
    num_of_empty_r = 0
    empty_bins_map = queue.Queue() # 一开始哪里有empty bins
    destination_bin = 255 # 把对应的empty bins移到什么位置就停止
    for i in range(255,current_bin,-1):
        if histogram[i] == 0 and num_of_empty_r < iteration_max: # 右移
            empty_bins_map.put(i)
            num_of_empty_r += 1

    # 改变max通道中所有该移动的值
    while not empty_bins_map.empty():
        current_bin = empty_bins_map.get()
        lm_r.append(current_bin)

        for w in range(width):
            for h in range(height):
                if max[w,h]>current_bin and max[w,h]<=destination_bin:
                    max[w,h] -= 1
        destination_bin -= 1
    
    histogram = obtain_1D_histogram(max,width,height) # update histogram

    # merge lowest bins
    lm = []
    num_l = num_of_empty_l # copy
    if num_of_empty_l < iteration_max:
        # print("----------------------merging lowest bins-------------------------")
        location_map_l = []
        lm_size_l = np.zeros(iteration_max-num_of_empty_l,dtype=int)
        for i in range(num_of_empty_l,iteration_max):
            # 找到2D直方图中最小的bin
            lowest = float("inf")
            lowest_bin = 0
            for x in range(i,256-num_of_empty_r):
                if histogram[x] < lowest:
                    lowest = histogram[x]
                    lowest_bin = x

            # 找lower adjacent bin 注：lower adjacent bin不准是0
            if lowest_bin == num_of_empty_l:
                adjacent_bin = lowest_bin+1
            elif lowest_bin == 255-num_of_empty_r:
                adjacent_bin = lowest_bin-1
            else:
                if histogram[lowest_bin-1] < histogram[lowest_bin+1]:
                    adjacent_bin = lowest_bin-1
                else:
                    adjacent_bin = lowest_bin+1
                    
            # 记录合并的位置和方向
            location_map_l.append(lowest_bin)
            if adjacent_bin-lowest_bin == -1:
                location_map_l.append(0)
            else:
                location_map_l.append(1)
                    
            # merging and record lm
            for w in range(width):
                for h in range(height):
                    if max[w,h] == lowest_bin:
                        max[w,h] = adjacent_bin
                        lm.append(0)
                        lm_size_l[i-num_l] += 1
                    elif max[w,h] == adjacent_bin:
                        lm.append(1)
                        lm_size_l[i-num_l] += 1
            
            # shifting
            destination_bin = num_of_empty_l
            
            # 更新max           
            for w in range(width):
                for h in range(height):
                    if max[w,h] < lowest_bin and max[w,h] >= destination_bin:
                        max[w,h] += 1
            
            # update num_of_empty_l
            num_of_empty_l += 1

            # update histogram
            histogram = obtain_1D_histogram(max,width,height)


    num_r = num_of_empty_r # copy
    if num_of_empty_r < iteration_max:
        # print("----------------------merging lowest bins-------------------------")
        location_map_r = []
        lm_size_r = np.zeros(iteration_max-num_of_empty_r,dtype=int)
        for i in range(num_of_empty_r,iteration_max):
            # 找到2D直方图中最小的bin
            lowest = float("inf")
            lowest_bin = 0
            for x in range(iteration_max,256-num_of_empty_r):
                if histogram[x] < lowest and histogram[x] != 0:
                    lowest = histogram[x]
                    lowest_bin = x

            # 找lower adjacent bin
            if lowest_bin == iteration_max:
                adjacent_bin = lowest_bin+1
            elif lowest_bin == 255-num_of_empty_r:
                adjacent_bin = lowest_bin-1
            else:
                if histogram[lowest_bin] < histogram[lowest_bin+1]:
                    adjacent_bin = lowest_bin-1
                else:
                    adjacent_bin = lowest_bin+1
                    
            # 记录合并的位置和方向
            location_map_r.append(lowest_bin)
            if adjacent_bin-lowest_bin==-1:
                location_map_r.append(0)
            else:
                location_map_r.append(1)
                    
            # merge and record lm
            for w in range(width):
                for h in range(height):
                    if max[w,h] == lowest_bin:
                        max[w,h] = adjacent_bin
                        lm.append(0)
                        lm_size_r[i-num_r] += 1
                    elif max[w,h] == adjacent_bin:
                        lm.append(1)
                        lm_size_r[i-num_r] += 1

            # shifting
            destination_bin = 255-num_of_empty_r

            # 更新max            
            for w in range(width):
                for h in range(height):
                    if max[w,h] > lowest_bin and max[w,h] <= destination_bin:
                        max[w,h] -= 1

            # update num_of_empty_r
            num_of_empty_r += 1

            # update histogram
            histogram = obtain_1D_histogram(max,width,height)

    # organize location map of pre-shifting
    for i in range(num_r):
        location_map_max = record(location_map_max,lm_r.pop(),8)

    for i in range(num_l):
        location_map_max = record(location_map_max,lm_l.pop(),8)

    # print("left:"+str(np.sum(histogram[:iteration_max])))
    # print("right:"+str(np.sum(histogram[256-iteration_max:256])))


    # print("-------------------------直方图向右移------------------------------")
    # move to right side
    for w in range(width):
        for h in range(height):
            max[w,h] += iteration_max

    # print("------------------------modify median and min--------------------------")
    diff = max - max_origin
    median += diff
    min += diff

    # print("--------------------------max median min合并收缩---------------------------")
    # 计算三个通道的直方图
    histogram_max = obtain_1D_histogram(max,width,height)
    histogram_median = obtain_1D_histogram(median,width,height)
    histogram_min = obtain_1D_histogram(min,width,height)

    histogram = histogram_max+histogram_median+histogram_min

    # 空出左边
    lm_l = []
    num_of_empty_l = 0
    destination_bin = 0 # 把对应的empty bins移到什么位置就停止
    empty_bins_map = queue.Queue() # 一开始哪里有empty bins
    destination_bin = 0
    for i in range(128):
        if histogram[i] == 0 and num_of_empty_l < iteration_max: # 左移到最左or左边已有0为止
            empty_bins_map.put(i)
            num_of_empty_l += 1

    # 根据empty_bins_map调整max median min
    while not empty_bins_map.empty():
        current_bin = empty_bins_map.get()
        # location_map = record(location_map,current_bin,8)
        lm_l.append(current_bin)
        # location_map.put(current_bin)

        for w in range(width):
            for h in range(height):
                if max[w,h]<current_bin and max[w,h]>=destination_bin:
                    max[w,h] += 1
                if median[w,h]<current_bin and median[w,h]>=destination_bin:
                    median[w,h] += 1
                if min[w,h]<current_bin and min[w,h]>=destination_bin:
                    min[w,h] += 1
        destination_bin += 1

    # update histogram
    histogram_max = obtain_1D_histogram(max,width,height)
    histogram_median = obtain_1D_histogram(median,width,height)
    histogram_min = obtain_1D_histogram(min,width,height)
    histogram = histogram_max+histogram_median+histogram_min

    # 空出右边
    lm_r = []
    num_of_empty_r = 0
    empty_bins_map = queue.Queue() # 一开始哪里有empty bins
    destination_bin = 255 # 把对应的empty bins移到什么位置就停止
    for i in range(255,127,-1):
        if histogram[i] == 0 and num_of_empty_r < iteration_max: # 右移到最右or右边已有0为止
            empty_bins_map.put(i)
            num_of_empty_r += 1

    # 根据empty_bins_map调整max median min
    while not empty_bins_map.empty():
        current_bin = empty_bins_map.get()
        # location_map = record(location_map,current_bin,8)
        lm_r.append(current_bin)
        # location_map.put(current_bin)

        for w in range(width):
            for h in range(height):
                if max[w,h]>current_bin and max[w,h]<=destination_bin:
                    max[w,h] -= 1
                if median[w,h]>current_bin and median[w,h]<=destination_bin:
                    median[w,h] -= 1
                if min[w,h]>current_bin and min[w,h]<=destination_bin:
                    min[w,h] -= 1
        
        destination_bin -= 1

    # update histogram
    histogram_max = obtain_1D_histogram(max,width,height)
    histogram_median = obtain_1D_histogram(median,width,height)
    histogram_min = obtain_1D_histogram(min,width,height)
    histogram = histogram_max+histogram_median+histogram_min

    # print("left:"+str(histogram[:num_of_empty_l]))
    # print("right:"+str(histogram[256-num_of_empty_r:]))

    # print("--------------------------merge lowest bins-------------------------")
    lm = []
    # 左移
    num_l = num_of_empty_l # copy
    if num_of_empty_l<iteration_max:
        location_map_l = []
        lm_size_l = np.zeros(iteration_max-num_of_empty_l,dtype=int)
        for i in range(num_of_empty_l,iteration_max):
            # obtain lowest bin
            lowest = float("inf")
            lowest_bin = 0

            for j in range(i,256-num_of_empty_r):
                if histogram[j] < lowest:
                    lowest = histogram[j]
                    lowest_bin = j
            
            # find a lower adjacent bin
            if lowest_bin == num_of_empty_l:
                adjacent_bin = lowest_bin+1
            elif lowest_bin == 255-num_of_empty_r:
                adjacent_bin = lowest_bin-1
            else:
                if histogram[lowest_bin-1] < histogram[lowest_bin+1]:
                    adjacent_bin = lowest_bin-1
                else:
                    adjacent_bin = lowest_bin+1

            location_map_l.append(lowest_bin)
            if adjacent_bin-lowest_bin == -1:
                location_map_l.append(0)
            else:
                location_map_l.append(1)

            # merging and record lm
            for w in range(width):
                for h in range(height):
                    if max[w,h] == lowest_bin:
                        max[w,h] = adjacent_bin
                        lm.append(0)
                        lm_size_l[i-num_l] += 1
                    elif max[w,h] == adjacent_bin:
                        lm.append(1)
                        lm_size_l[i-num_l] += 1

                    if median[w,h] == lowest_bin:
                        median[w,h] = adjacent_bin
                        lm.append(0)
                        lm_size_l[i-num_l] += 1
                    elif median[w,h] == adjacent_bin:
                        lm.append(1)
                        lm_size_l[i-num_l] += 1

                    if min[w,h] == lowest_bin:
                        min[w,h] = adjacent_bin
                        lm.append(0)
                        lm_size_l[i-num_l] += 1
                    elif min[w,h] == adjacent_bin:
                        lm.append(1)
                        lm_size_l[i-num_l] += 1

            # shifting
            destination_bin = num_of_empty_l

            # modify max median min
            for w in range(width):
                for h in range(height):
                    if max[w,h]<lowest_bin and max[w,h]>=destination_bin:
                        max[w,h] += 1
                    if median[w,h]<lowest_bin and median[w,h]>=destination_bin:
                        median[w,h] += 1
                    if min[w,h]<lowest_bin and min[w,h]>=destination_bin:
                        min[w,h] += 1
            
            # update num_of_empty_l
            num_of_empty_l += 1

            # update histogram
            histogram_max = obtain_1D_histogram(max,width,height)
            histogram_median = obtain_1D_histogram(median,width,height)
            histogram_min = obtain_1D_histogram(min,width,height)
            histogram = histogram_max+histogram_median+histogram_min

    # 右移
    num_r = num_of_empty_r # copy
    if num_of_empty_r<iteration_max:
        location_map_r = []
        lm_size_r = np.zeros(iteration_max-num_of_empty_r,dtype=int)
        for i in range(num_of_empty_r,iteration_max):
            # obtain the lowest bin
            lowest = float("inf")
            lowest_bin = 0
            for j in range(iteration_max,256-num_of_empty_r):
                if histogram[j] <= lowest:
                    lowest = histogram[j]
                    lowest_bin = j
            
            # find a lower adjacent bin
            if lowest_bin == iteration_max:
                adjacent_bin = lowest_bin + 1
            elif lowest_bin == 255-num_of_empty_r:
                adjacent_bin = lowest_bin - 1
            else:
                if histogram[lowest_bin-1] < histogram[lowest_bin+1]:
                    adjacent_bin = lowest_bin - 1
                else:
                    adjacent_bin = lowest_bin + 1

            # record the position of the lowest bin and moving direction
            location_map_r.append(lowest_bin)
            if adjacent_bin-lowest_bin == -1:
                location_map_r.append(0)
            else:
                location_map_r.append(1)

            # merge and record lm
            for w in range(width):
                for h in range(height):
                    if max[w,h] == lowest_bin:
                        max[w,h] = adjacent_bin
                        lm.append(0)
                        lm_size_r[i-num_r] += 1
                    elif max[w,h] == adjacent_bin:
                        lm.append(1)
                        lm_size_r[i-num_r] += 1

                    if median[w,h] == lowest_bin:
                        median[w,h] = adjacent_bin
                        lm.append(0)
                        lm_size_r[i-num_r] += 1
                    elif median[w,h] == adjacent_bin:
                        lm.append(1)
                        lm_size_r[i-num_r] += 1

                    if min[w,h] == lowest_bin:
                        min[w,h] = adjacent_bin
                        lm.append(0)
                        lm_size_r[i-num_r] += 1
                    elif min[w,h] == adjacent_bin:
                        lm.append(1)
                        lm_size_r[i-num_r] += 1

            # shifting
            destination_bin = 255-num_of_empty_r

            # modify on max median min
            for w in range(width):
                for h in range(height):
                    if  max[w,h]>lowest_bin and max[w,h]<=destination_bin:
                        max[w,h] -= 1
                        
                    if median[w,h]>lowest_bin and median[w,h]<=destination_bin:
                        median[w,h] -= 1

                    if min[w,h]>lowest_bin and min[w,h]<=destination_bin:
                        min[w,h] -= 1
            
            # update num_of_empty_r
            num_of_empty_r += 1

            # update histogram
            histogram_max = obtain_1D_histogram(max,width,height)
            histogram_median = obtain_1D_histogram(median,width,height)
            histogram_min = obtain_1D_histogram(min,width,height)
            histogram = histogram_max+histogram_median+histogram_min

    #-------------------------------organize location map of pre------------------------------------#
    location_map = record(location_map,num_r,7)
    for i in range(iteration_max - num_r -1,-1,-1):
        direction = location_map_r.pop()
        lowest_bin = location_map_r.pop()
        location_map = record(location_map,lowest_bin,8)
        location_map.put(direction)
        if lm_size_r[i] == 0:
            continue
        lm_current = lm[-lm_size_r[i]:]
        del lm[-lm_size_r[i]:]
        for j in lm_current:
            location_map.put(j)

    location_map = record(location_map,num_l,7)
    for i in range(iteration_max - num_l -1,-1,-1):
        direction = location_map_l.pop()
        lowest_bin = location_map_l.pop()
        location_map = record(location_map,lowest_bin,8)
        location_map.put(direction)
        if lm_size_l[i] == 0:
            continue
        lm_current = lm[-lm_size_l[i]:]
        del lm[-lm_size_l[i]:]
        for j in lm_current:
            location_map.put(j)

    # organize location map of pre-shifting
    for i in range(num_r):
        location_map = record(location_map,lm_r.pop(),8)

    for i in range(num_l):
        location_map = record(location_map,lm_l.pop(),8)

    while not location_map_max.empty():
        location_map.put(location_map_max.get())


    # return preprocessed image and location map
    max_origin = np.copy(max)
    # print(location_map.qsize())
    return max,median,min,max_origin,location_map