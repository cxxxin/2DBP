import numpy as np

from obtain_2DHIS import obtain_2D_histogram
from utils import bi2de

# extract information from 2D histogram for the last iteration
def extract_last(max,width,height,direction,max_bin_value,min_bin_value):
    print("--------------------------extracting-----------------------------")
    # judge the direction
    if max_bin_value > min_bin_value: # LHS or DHS
        d = 1
    elif max_bin_value < min_bin_value: # RHS or UHS
        d = -1

    # extracting
    payload = np.array([],dtype=int)
    location_map_size = 0
    if direction == 0: # vertical
        for w in range(0,width,2):
            for h in range(height):
                if w < 17 and w >= 0 and h == 0:
                    continue # skip pixels with LSBs replaced
                adjacent_bin_value = max_bin_value - d
                if max[w,h] == max_bin_value:
                    payload = np.append(payload,0)
                elif max[w,h] == adjacent_bin_value:
                    payload = np.append(payload,1)
                elif max[w,h] == min_bin_value:
                    location_map_size += 1

    elif direction == 1: # horizontal
        for w in range(0,width,2):
            for h in range(height):
                if w+1 < 17 and w+1 >= 0 and h == 0:
                    continue # skip pixels with LSBs replaced
                adjacent_bin_value = max_bin_value - d
                if max[w+1,h] == max_bin_value:
                    payload = np.append(payload,0)
                elif max[w+1,h] == adjacent_bin_value:
                    payload = np.append(payload,1)
                elif max[w+1,h] == min_bin_value:
                    location_map_size += 1

    # split
    location_map = np.copy(payload[34:34+location_map_size])
    location_map_of_pre = np.copy(payload[34+location_map_size:])
    LSBs = np.copy(payload[0:17])
    direction_previous = int(payload[17])
    max_bin_value_previous = np.copy(payload[18:26])
    min_bin_value_previous = np.copy(payload[26:34])
    max_bin_value_previous = bi2de(max_bin_value_previous)
    min_bin_value_previous = bi2de(min_bin_value_previous)

    return LSBs,location_map,direction_previous,max_bin_value_previous,min_bin_value_previous,location_map_of_pre


# extracting for normal round
def extract(max,width,height,direction,max_bin_value,min_bin_value,location_map_of_pre):
    print("--------------------------extracting-----------------------------")
    histogram = obtain_2D_histogram(max,width,height)
    
    # judge the direction
    if max_bin_value > min_bin_value: # LHS or DHS
        d = 1
    elif max_bin_value < min_bin_value: # RHS or UHS
        d = -1

    # extracting
    payload = np.array([],dtype=int)
    location_map_size = 0
    if direction == 0: # vertical
        for w in range(0,width,2):
            for h in range(height):
                if max[w,h] == max_bin_value:
                    payload = np.append(payload,0)
                elif  max[w,h] == max_bin_value-d:
                    payload = np.append(payload,1)
                elif max[w,h] == min_bin_value:
                    location_map_size += 1

    elif direction == 1: # horizontal
        for w in range(0,width,2):
            for h in range(height):
                if max[w+1,h] == max_bin_value:
                    payload = np.append(payload,0)
                elif  max[w+1,h] == max_bin_value-d:
                    payload = np.append(payload,1)
                elif max[w+1,h] == min_bin_value:
                    location_map_size += 1

    # split
    location_map = np.copy(payload[17:17+location_map_size])
    temp = np.copy(payload[17+location_map_size:])
    location_map_of_pre = np.concatenate((temp,location_map_of_pre),axis=0)
    direction_previous = int(payload[0])
    max_bin_value_previous = np.copy(payload[1:9])
    min_bin_value_previous = np.copy(payload[9:17])
    max_bin_value_previous = bi2de(max_bin_value_previous)
    min_bin_value_previous = bi2de(min_bin_value_previous)

    return location_map,direction_previous,max_bin_value_previous,min_bin_value_previous,location_map_of_pre