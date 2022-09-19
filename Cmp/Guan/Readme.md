# 使用方法

1. 修改Guan.py中main函数的路径

   ```
   fileDir = r'your_path'
   pathList = [] # fileDir下的image_name
       for i in range(1,11):
           pathList.append('MCM'+str(i)+'.bmp')
           
   output_path = r'your_save_path'
   S = iteration_times
   ```

   

2. 运行Guan.py