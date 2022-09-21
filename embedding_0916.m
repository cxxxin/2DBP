%二维直方图两个方向上分别控制图像亮度，每轮选择行或列中数量多的来做

function [rdh_image, payload_embedding, payload_total, iteration]=embedding_0916(image, payload, iteration_max)

%     iteration_max = 1000;


image_size=size(image);

Ps_list=zeros(2,iteration_max);
Pc_list=zeros(2,iteration_max);
i_j_list = zeros(1,iteration_max); % i,j都表示的是像素值，i表示某一个像素对中左边的像素值，j表示右边的

image_ref = zeros(image_size(1)*image_size(2),iteration_max); % 每次迭代中都会有一个reference image
image_ref(:,1) = reshape(image,image_size(1)*image_size(2),1); % 初始化，将image赋值给矩阵

image_vec=image_ref(:,1);
% original_brightness = mean(image_ref(:,1));

% calculate brightness of reference image
image = double(image);
original_brightness1 = 0;
original_brightness2 = 0;
for i = 1 : image_size(1)
    for j = 1 : image_size(2)
        if mod(j, 2) == 1 % pari中的左位
            original_brightness1 = original_brightness1 + image(i, j);
        else % pair中的右位
            original_brightness2 = original_brightness2 + image(i, j);
        end
    end
end
original_brightness1 = original_brightness1 * 2 / (image_size(1)*image_size(2));
original_brightness2 = original_brightness2 * 2 / (image_size(1)*image_size(2));

Ps_i = 1;
Ps_j = 1;
Pc_i = 1;
Pc_j = 1;
i_j = 0;
iteration=0;

payload_embedding=[];
payload_total=0;
temp_p = 1;

while true
    image_mat = reshape(image_vec, image_size(1), image_size(2));
    
    HistMatrix = zeros(256, 256); % 生成二维直方图
    for i = 1 : image_size(1)
        for j = 1 : 2 : image_size(2)
            HistMatrix(image_mat(i,j)+1 , image_mat(i,j+1)+1) = HistMatrix(image_mat(i,j)+1 , image_mat(i,j+1)+1) + 1;
        end
    end
    %Adaptive peak selection
    Ps_i_previous = Ps_i;
    Ps_j_previous = Ps_j;
    Pc_i_previous = Pc_i;
    Pc_j_previous = Pc_j;
    i_j_previous = i_j;
    [ Ps_i, Ps_j, Pc_i, Pc_j, H_Ps, LM_size, i_j ] = adaptive_peak_selection(original_brightness1, original_brightness2, image_mat, HistMatrix);
    
    %Direction of horizontal histogram shifting
    if Ps_j < Pc_j %RHS
        D_r = 1;
    else %LHS
        D_r = -1;
    end
    %Direction of vertical histogram shifting
    if Ps_i > Pc_i %UHS
        D_c = 1;
    else %DHS
        D_c = -1;
    end
    
    %Record location map
    LM = [];
    % if LM_size ~= 0
        if i_j == 0
            for i = 1 : image_size(1)
                for j = 1 : 2 : image_size(2)
                    if image_mat(i, j) == Pc_i-1 || image_mat(i, j) == Pc_i+D_c-1
                        if image_mat(i, j) == Pc_i-1
                            LM = [LM, 0];
                        else
                            LM = [LM, 1];
                        end
                    end
                end
            end
        else
            for i = 1 : image_size(1)
                for j = 1 : 2 : image_size(2)
                    if image_mat(i, j+1) == Pc_j-1 || image_mat(i, j+1) == Pc_j-D_r-1
                        if image_mat(i, j+1) == Pc_j-1
                            LM = [LM, 0];
                        else
                            LM = [LM, 1];
                        end
                    end
                end
            end
        end
    % end
    
    sum = 0;
    if i_j == 0
        for j = 1 : 2 : 17
            if image_mat(1, j) == Ps_i - 1
                sum = sum + 1;
            end
        end
    else
        for j = 1 : 2 : 17
            if image_mat(1, j+1) == Ps_j - 1
                sum = sum + 1;
            end
        end
    end
        
    if H_Ps - sum < length(LM)+34 || iteration == iteration_max %Stop condition reached
        % update peak
        Ps_i = Ps_i_previous; % 不够新的一轮嵌入了，就不做了，恢复成上一次的系数，直接结束！
        Ps_j = Ps_j_previous;
        Pc_i = Pc_i_previous;
        Pc_j = Pc_j_previous;
        i_j = i_j_previous;
        Ps_i_previous = Ps_list(1, iteration); % 上一轮的参数，要被嵌入
        Ps_j_previous = Ps_list(2, iteration);
        Pc_i_previous = Pc_list(1, iteration);
        Pc_j_previous = Pc_list(2, iteration);
        i_j_previous = i_j_list(1,iteration);
%         first_32_pixels = image_ref(1:32,iteration);
        
        image_mat = reshape(image_ref(:,iteration),image_size(1), image_size(2));
        
        for j = 1 : 17 % 随机覆盖17个像素值
            first_17_pixels(j, 1) = image_mat(1, j);
        end  
        original_17_lsb = mod(first_17_pixels,2);      
        
        
        if Ps_j < Pc_j %RHS
            D_r = 1;
        else %LHS
            D_r = -1;
        end
        if Ps_i > Pc_i %UHS
            D_c = 1;
        else %DHS
            D_c = -1;
        end
        
        HistMatrix = zeros(256, 256);
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if i == 1 && j <= 17 && j >= 1
                    continue;
                else
                    HistMatrix(image_mat(i,j)+1 , image_mat(i,j+1)+1) = HistMatrix(image_mat(i,j)+1 , image_mat(i,j+1)+1) + 1;
                end
            end
        end
        
        H_Ps = 0;
        if i_j == 1
            for x = 1 : 256
                H_Ps = H_Ps + HistMatrix(x, Ps_j);
            end
        else
            for y = 1 : 256
                H_Ps = H_Ps + HistMatrix(Ps_i, y);
            end
        end
        
        sum = 0;
        for j = 1 : 2 : 17
            if i_j == 0
                if image_mat(1, j) == Ps_i - 1
                    sum = sum + 1;
                end
            else
                if image_mat(1, j+1) == Ps_j - 1
                    sum = sum + 1;
                end
            end
        end
        payload_total = payload_total - sum;
        
        LM = [];
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if i == 1 && j <= 17 && j >= 1
                    continue;
                else
                    if i_j == 0
                        if image_mat(i, j) == Pc_i-1 || image_mat(i, j) == Pc_i+D_c-1
                            if image_mat(i, j) == Pc_i-1
                                LM = [LM, 0];
                            else
                                LM = [LM, 1];
                            end
                        end
                    else
                        if image_mat(i, j+1) == Pc_j-1 || image_mat(i, j+1) == Pc_j-D_r-1
                            if image_mat(i, j+1) == Pc_j-1
                                LM = [LM, 0];
                            else
                                LM = [LM, 1];
                            end
                        end
                    end
                end
            end
        end


        temp_p = temp_p - lack_length;
        payload_embedding(temp_p : end) = [];
        lack_length = H_Ps - length(LM) - 34;
        actual_payload = payload(temp_p : temp_p+lack_length-1);
        temp_p = temp_p + lack_length;
        payload_embedding = [payload_embedding; actual_payload];
        
        if i_j_previous == 0
            message=[LM , de2bi(Ps_i_previous-1,8), de2bi(Pc_i_previous-1,8), i_j_previous, original_17_lsb', actual_payload'];
        else 
            message=[LM , de2bi(Ps_j_previous-1,8), de2bi(Pc_j_previous-1,8), i_j_previous, original_17_lsb', actual_payload'];
        end
        image_mat = last_processing(image_mat, Ps_i, Ps_j, Pc_i, Pc_j, D_r, D_c, message, i_j);
        
        %replace 17 lsbs with (Ps_i, Pc_i and i_j)  or (Ps_j, Pc_j and i_j)
        iteration_max = iteration;
        if i_j == 0
            first_17_pixels = bitxor(bitxor(first_17_pixels, mod(first_17_pixels, 2)), [de2bi(Ps_i-1,8)'; de2bi(Pc_i-1,8)'; 0]);
        else 
            first_17_pixels = bitxor(bitxor(first_17_pixels, mod(first_17_pixels, 2)), [de2bi(Ps_j-1,8)'; de2bi(Pc_j-1,8)'; 1]);
        end
        
        for j = 1 : 17
            image_mat(1, j) = first_17_pixels(j, 1);
        end
        rdh_image = image_mat;
        image_ref(:,iteration_max+1:end) = [];
        break
        
    else
        payload_total = payload_total + H_Ps;
        lack_length = H_Ps - length(LM) - 17;
        actual_payload = payload(temp_p : temp_p+lack_length-1);
        temp_p = temp_p + lack_length;
        payload_embedding = [payload_embedding; actual_payload];
            
        if i_j_previous == 0
            message=[LM , de2bi(Ps_i_previous-1,8), de2bi(Pc_i_previous-1,8), i_j_previous, actual_payload'];
        else
            message=[LM , de2bi(Ps_j_previous-1,8), de2bi(Pc_j_previous-1,8), i_j_previous, actual_payload'];
        end
        iteration=iteration+1;
        disp(iteration)
        
        image_ref(:,iteration) = image_vec;
        Ps_list(1, iteration)=Ps_i_previous; % record current params
        Ps_list(2, iteration)=Ps_j_previous;
        Pc_list(1, iteration)=Pc_i_previous;
        Pc_list(2, iteration)=Pc_j_previous;
        i_j_list(1, iteration)=i_j_previous;
        image_mat = processing(image_mat, Ps_i, Ps_j, Pc_i, Pc_j, D_r, D_c, message, i_j);
        image_vec = reshape(image_mat,image_size(1)*image_size(2),1);
%         figure(1);imshow(uint8(image));
%         figure(2);imshow(uint8(image_mat));
    end
end
disp('Encoding time')

% figure(1);imshow(uint8(image));
% figure(2);imshow(uint8(rdh_image));
end

%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function [ Ps_i, Ps_j, Pc_i, Pc_j, H_Ps, LM_size, i_j ] = adaptive_peak_selection(original_brightness1, original_brightness2, image_mat, HistMatrix)
image_size = size(image_mat);
current_brightness1 = 0; % pixel pair中左边的像素值
current_brightness2 = 0; % pixel pair中右边的像素值
for i = 1 : image_size(1)
    for j = 1 : image_size(2)
        if mod(j, 2) == 1 % 奇数列，pair中的左位
            current_brightness1 = current_brightness1 + image_mat(i, j);
        else % 偶数列，pair中的右位
            current_brightness2 = current_brightness2 + image_mat(i, j);
        end
    end
end
current_brightness1 = current_brightness1 * 2 / (image_size(1)*image_size(2));
current_brightness2 = current_brightness2 * 2 / (image_size(1)*image_size(2));
%     mesh(HistMatrix);
S_x = zeros(1, 2); S_y = zeros(1, 2);
if original_brightness1 - current_brightness1 > 0 % 左边的像素亮度整体降低了，执行DHS把右边的亮度提高
    S_x(1) = 1; S_x(2) = 254;
    [ Ps_i, H_Ps1 ] = get_Psi(HistMatrix, S_x);
    [ Pc_i, LM_size1 ] = find_DHS(HistMatrix, Ps_i);
    
elseif original_brightness1 - current_brightness1 < 0 % 左边的像素亮度整体上升了，执行UHS把右边的亮度降低
    S_x(1) = 3; S_x(2) = 256;
    [ Ps_i, H_Ps1 ] = get_Psi(HistMatrix, S_x);
    [ Pc_i, LM_size1 ] = find_UHS(HistMatrix, Ps_i);
    
else
    S_x(1) = 1; S_x(2) = 256;
    [ Ps_i, H_Ps1 ] = get_Psi(HistMatrix, S_x);
    if Ps_i < 3 %%① DHS
        [ Pc_i, LM_size1 ] = find_DHS(HistMatrix, Ps_i);
    elseif Ps_i > 254%% ⑤ UHS
        [ Pc_i, LM_size1 ] = find_UHS(HistMatrix, Ps_i);          
    else %% ⑨ DHS/UHS
        [ Pc_i, LM_size1 ] = find_UDHS(HistMatrix, Ps_i);
    end   
end

if original_brightness2 - current_brightness2 > 0 % 右位亮度降下去了，RHS来提升左位亮度
    S_y(1) = 1; S_y(2) = 254;
    [ Ps_j, H_Ps2 ] = get_Psj(HistMatrix, S_y);
    [ Pc_j, LM_size2 ] = find_RHS(HistMatrix, Ps_j);
    
elseif original_brightness2 - current_brightness2 < 0 % LHS降低亮度
    S_y(1) = 3; S_y(2) = 256;
    [ Ps_j, H_Ps2 ] = get_Psj(HistMatrix, S_y);
    [ Pc_j, LM_size2 ] = find_LHS(HistMatrix, Ps_j);
    
else
    S_y(1) = 1; S_y(2) = 256;
    [ Ps_j, H_Ps2 ] = get_Psj(HistMatrix, S_y);
    if Ps_j < 3 %%① RHS
        [ Pc_j, LM_size2 ] = find_DHS(HistMatrix, Ps_j);
        
    elseif Ps_j > 254%% ⑤ LHS
        [ Pc_j, LM_size2 ] = find_UHS(HistMatrix, Ps_j);
        
    else %% ⑨ RHS/LHS
        [ Pc_j, LM_size2 ] = find_RLHS(HistMatrix, Ps_j);
    end
end

if H_Ps1 >= H_Ps2
    H_Ps = H_Ps1;
    LM_size = LM_size1;
    i_j = 0;  %用i_j来表示该轮是行嵌入还是列嵌入，用0表示行，1表示列
else
    H_Ps = H_Ps2;
    LM_size = LM_size2;
    i_j = 1;
end

end

function  [ Ps_i, maxValue ] = get_Psi(HistMatrix, S_x)
    maxValue = -99999999;
    for i = S_x(1) : 1 : S_x(2)
        sum = 0;
        for y = 1 : 256
            sum = sum + HistMatrix(i, y);
        end
        if sum > maxValue
            maxValue = sum;
            Ps_i = i;
        end
    end
end


% 
% function [Pc_i, Pc_j] = get_Pc(Ps_i, Ps_j, list_Pc)
%     minDistance = 999999;
%     for k = 1 : length(list_Pc(1, :))
%         squares = (list_Pc(1,k)-Ps_i)^2 + (list_Pc(2,k)-Ps_j)^2;
%         if squares <= minDistance
%             minDistance = squares;
%             Pc_i = list_Pc(1,k);
%             Pc_j = list_Pc(2,k);
%         end
%     end
% end

function [Pc_i, minValue] = find_DHS(HistMatrix, Ps_i)
    minValue = 99999999999;
    for i = Ps_i+2 : 1 : 256
        sum = 0;
        for y = 1 : 256
            sum = sum + HistMatrix(i, y);
            sum = sum + HistMatrix(i-1, y);
        end
        if sum < minValue
            minValue = sum;
            Pc_i = i;
        end
    end
end

function [Pc_i, minValue] = find_UHS(HistMatrix, Ps_i)
    minValue = 99999999999;
    for i = 1 : 1 : Ps_i-2
            sum = 0;
            for y = 1 : 256
                sum = sum + HistMatrix(i, y);
                sum = sum + HistMatrix(i+1, y);
            end
            if sum < minValue
                minValue = sum;
                Pc_i = i;
            end
    end
end

function  [ Pc_i, minValue ] = find_UDHS(HistMatrix, Ps_i)
    [Pc_i1, value1] = find_UHS(HistMatrix, Ps_i);
    [Pc_i2, value2] = find_DHS(HistMatrix, Ps_i);
    [Pc_i, minValue] = get_min(Pc_i1, value1, Pc_i2, value2);
end

function [ P, minValue ] = get_min( P1, value1, P2, value2)
    if value1 <= value2
        P = P1;
        minValue = value1;
    elseif value1 > value2
        P = P2;
        minValue = value2;      
    end
end

function  [ Ps_j, maxValue ] = get_Psj(HistMatrix, S_y)
    maxValue = -99999999;
    for j = S_y(1) : 1 : S_y(2)
        sum = 0;
        for x = 1 : 256
            sum = sum + HistMatrix(x, j);
        end
        if sum > maxValue
            maxValue = sum;
            Ps_j = j;
        end
    end
end

function [Pc_j, minValue] = find_RHS(HistMatrix, Ps_j)
    minValue = 99999999999;
    for j = Ps_j+2 : 1 : 256
        sum = 0;
        for x = 1 : 256
            sum = sum + HistMatrix(x, j);
            sum = sum + HistMatrix(x, j-1);
        end
        if sum < minValue
            minValue = sum;
            Pc_j = j;
        end
    end
end

function [Pc_j, minValue] = find_LHS(HistMatrix, Ps_j)
    minValue = 99999999999;
    for j = 1 : 1 : Ps_j-2
            sum = 0;
            for x = 1 : 256
                sum = sum + HistMatrix(x, j);
                sum = sum + HistMatrix(x, j+1);
            end
            if sum < minValue
                minValue = sum;
                Pc_j = j;
            end
    end
end

function  [ Pc_j, minValue ] = find_RLHS(HistMatrix, Ps_j)
    [Pc_j1, value1] = find_LHS(HistMatrix, Ps_j);
    [Pc_j2, value2] = find_RHS(HistMatrix, Ps_j);
    [Pc_j, minValue] = get_min(Pc_j1, value1, Pc_j2, value2);
end


%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function [image] = processing(image, Ps_i, Ps_j, Pc_i, Pc_j, D_r, D_c, message, i_j)
    image_size = size(image);
    if i_j == 0
        
        %Combine Pc_i with its neighbor
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if image(i, j) == Pc_i+D_c-1
                    image(i, j) = image(i, j) - D_c;
                end
            end
        end
        %Shift Ps_i neighbors towards Pc_i
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if D_c == 1
                    if image(i, j) > Pc_i-1 && image(i, j) < Ps_i-1
                        image(i, j) = image(i, j) - D_c;
                    end
                else
                    if image(i, j) < Pc_i-1 && image(i, j) > Ps_i-1
                        image(i, j) = image(i, j) - D_c;
                    end
                end
            end
        end
        %Embed
        temp = 1;
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if image(i,j) == Ps_i - 1
                    if message(temp) == 0
                        temp = temp + 1;
                    else 
                        image(i, j) = image(i, j) - D_c;
                        temp = temp + 1;
                    end
                end
            end
        end
        
        
    else
        %Combine Pc_j with its neighbor
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if image(i, j+1) == Pc_j-D_r-1
                    image(i, j+1) = image(i, j+1) + D_r;
                end
            end
        end
        %Shift Ps_j neighbors towards Pc_j
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if D_r == 1
                    if image(i, j+1) > Ps_j-1 && image(i, j+1) < Pc_j-1
                        image(i, j+1) = image(i, j+1) + D_r;
                    end
                else
                    if image(i, j+1) < Ps_j-1 && image(i, j+1) > Pc_j-1
                        image(i, j+1) = image(i, j+1) + D_r;
                    end
                end
            end
        end
        %Embed
        temp = 1;
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if image(i,j+1) == Ps_j - 1
                    if message(temp) == 0
                        temp = temp + 1;
                    else 
                        image(i, j+1) = image(i, j+1) + D_r;
                        temp = temp + 1;
                    end
                end
            end
        end
        
    end
    
    %Embed
%     temp = 1;
%     for i = 1 : image_size(1)
%         for j = 1 : 2 : image_size(2)
%             if image(i,j) == Ps_i - 1
%                 if message(temp) == 0
%                     temp = temp + 1;
%                 else 
%                     image(i, j) = image(i, j) - D_c;
%                     temp = temp + 1;
%                 end
%             end
%             if image(i,j+1) == Ps_j - 1
%                 if message(temp) == 0
%                     temp = temp + 1;
%                 else 
%                     image(i, j+1) = image(i, j+1) + D_r;
%                     temp = temp + 1;
%                 end
%             end
%         end
%     end

end

function [image] = last_processing(image, Ps_i, Ps_j, Pc_i, Pc_j, D_r, D_c, message, i_j)
    image_size = size(image);
    if i_j == 0

        %Combine Pc_i with its neighbor
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if i == 1 && j <= 17 && j >= 1
                    continue;
                else
                    if image(i, j) == Pc_i+D_c-1
                        image(i, j) = image(i, j) - D_c;
                    end
                end
            end
        end
        %Shift Ps_i neighbors towards Pc_i
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if i == 1 && j <= 17 && j >= 1
                    continue;
                else
                    if D_c == 1
                        if image(i, j) > Pc_i-1 && image(i, j) < Ps_i-1
                            image(i, j) = image(i, j) - D_c;
                        end
                    else
                        if image(i, j) < Pc_i-1 && image(i, j) > Ps_i-1
                            image(i, j) = image(i, j) - D_c;
                        end
                    end
                end
            end
        end
        %Embed Ps_i
        temp = 1;
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if i == 1 && j <= 17 && j >= 0
                    continue;
                else
                    if image(i,j) == Ps_i - 1
                        if message(temp) == 0
                            temp = temp + 1;
                        else
                            image(i, j) = image(i, j) - D_c;
                            temp = temp + 1;
                        end
                    end
                end
            end
        end
        
    else

        %Combine Pc_j with its neighbor
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if i == 1 && j <= 17 && j >= 1
                    continue;
                else
                    if image(i, j+1) == Pc_j-D_r-1
                        image(i, j+1) = image(i, j+1) + D_r;
                    end
                end
            end
        end
        %Shift Ps_j neighbors towards Pc_j
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if i == 1 && j <= 17 && j >= 1
                    continue;
                else
                    if D_r == 1
                        if image(i, j+1) > Ps_j-1 && image(i, j+1) < Pc_j-1
                            image(i, j+1) = image(i, j+1) + D_r;
                        end
                    else
                        if image(i, j+1) < Ps_j-1 && image(i, j+1) > Pc_j-1
                            image(i, j+1) = image(i, j+1) + D_r;
                        end
                    end
                end
            end
        end
        %Embed Ps_j
        temp = 1;
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if i == 1 && j <= 17 && j >= 0
                    continue;
                else
                    if image(i,j+1) == Ps_j - 1
                        if message(temp) == 0
                            temp = temp + 1;
                        else
                            image(i, j+1) = image(i, j+1) + D_r;
                            temp = temp + 1;
                        end
                    end
                end
            end
        end
        
        
    end
    
    
    %Embed Ps
%     temp = 1;
%     for i = 1 : image_size(1)
%         for j = 1 : 2 : image_size(2)
%             if i == 1 && j <= 32 && j >= 0
%                 continue;
%             else
%                 if image(i,j) == Ps_i - 1
%                     if message(temp) == 0
%                         temp = temp + 1;
%                     else
%                         image(i, j) = image(i, j) - D_c;
%                         temp = temp + 1;
%                     end
%                 end
%                 if image(i,j+1) == Ps_j - 1
%                     if message(temp) == 0
%                         temp = temp + 1;
%                     else
%                         image(i, j+1) = image(i, j+1) + D_r;
%                         temp = temp + 1;
%                     end
%                 end
%             end
%         end
%     end

end
