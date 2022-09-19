import numpy as np

'''
x--要转换的数
num--输出的位数
'''
# 这里的x是个整数，num是需要转成多少位的二进制数
def de2bi(x,num):
    x = bin(x)[2:] # 去掉前缀0b
    while len(x)<num :
        x = '0'+x

    return x

# 这里的location_map是个队列，message是个整数，num是需要转成多少位的二进制数
def record(location_map,message,num):
    message = de2bi(message,num)
    for i in range(num):
        location_map.put(message[i])
    
    return location_map

# 这里的x是个矩阵
def bi2de(x):
    result = 0
    j = 0
    for i in range(len(x)-1,-1,-1):
        result += x[i] * pow(2,j)
        j += 1

    return int(result)