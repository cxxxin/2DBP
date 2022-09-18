function [payload_rec, re_image]=recovery_0916(rdh_image)
tic
image_size = size(rdh_image);
image_hor = reshape(rdh_image',image_size(1)*image_size(2),1);
% ref_image_hor(:,1) = reshape(rdh_image,image_size(1)*image_size(2),1);

% Reverse Operation
first_17_pixels_rec=bitxor(image_hor(1:17), mod(image_hor(1:17),2));
i_j_rec = bi2de(mod(image_hor(17)', 2));
Ps_rec = bi2de(mod(image_hor(1:8)', 2));
Pc_rec = bi2de(mod(image_hor(9:16)', 2));
if i_j_rec == 0
    if Ps_rec > Pc_rec %UHS
        D_c = 1;
    else %DHS
        D_c = -1;
    end
    
    message_rec = [];
    for i = 1 : image_size(1)
        for j = 1 : 2 : image_size(2)
            if i == 1 && j <= 17 && j >= 1
                continue;
            else
                if rdh_image(i, j) == Ps_rec
                    message_rec = [message_rec, 0];
                elseif rdh_image(i, j) == Ps_rec - D_c
                    message_rec = [message_rec, 1];
                    rdh_image(i, j) = rdh_image(i, j) + D_c;
                end
            end
        end
    end
    
    LM_size = 0;
    for i = 1 : image_size(1)
        for j = 1 : 2 : image_size(2)
            if i == 1 && j <= 17 && j >= 1
                continue;
            else
                if rdh_image(i, j) == Pc_rec
                    LM_size = LM_size + 1;
                end
            end
        end
    end
    
    
else
    Ps_rec = bi2de(mod(image_hor(1:8)', 2));
    Pc_rec = bi2de(mod(image_hor(9:16)', 2));
    if Ps_rec < Pc_rec %RHS
        D_r = 1;
    else %LHS
        D_r = -1;
    end
    
    message_rec = [];
    for i = 1 : image_size(1)
        for j = 1 : 2 : image_size(2)
            if i == 1 && j <= 17 && j >= 1
                continue;
            else
                if rdh_image(i, j+1) == Ps_rec
                    message_rec = [message_rec, 0];
                elseif rdh_image(i, j+1) == Ps_rec + D_r
                    message_rec = [message_rec, 1];
                    rdh_image(i, j+1) = rdh_image(i, j+1) - D_r;
                end
            end
        end
    end
    
%     isequal(message, message_rec)
    
    LM_size = 0;
    for i = 1 : image_size(1)
        for j = 1 : 2 : image_size(2)
            if i == 1 && j <= 17 && j >= 1
                continue;
            else
                if rdh_image(i, j+1) == Pc_rec
                    LM_size = LM_size + 1;
                end
            end
        end
    end

end




%%Undo first iteration
%Extract vertical Payload + side information
% message_rec = [];
% for i = 1 : image_size(1)
%     for j = 1 : 2 : image_size(2)
%         if i == 1 && j <= 32 && j >= 1
%             continue;
%         else
%             if rdh_image(i, j) == Ps_i_rec
%                 message_rec = [message_rec, 0];
%             elseif rdh_image(i, j) == Ps_i_rec - D_c
%                 message_rec = [message_rec, 1];
%                 rdh_image(i, j) = rdh_image(i, j) + D_c;
%             end
%             if rdh_image(i, j+1) == Ps_j_rec
%                 message_rec = [message_rec, 0];
%             elseif rdh_image(i, j+1) == Ps_j_rec + D_r
%                 message_rec = [message_rec, 1];
%                 rdh_image(i, j+1) = rdh_image(i, j+1) - D_r;
%             end
%         end
%     end
% end


% LM_size = 0;
% for i = 1 : image_size(1)
%     for j = 1 : 2 : image_size(2)
%         if i == 1 && j <= 32 && j >= 1
%             continue;
%         else
%             if rdh_image(i, j+1) == Pc_j_rec
%                 LM_size = LM_size + 1;
%             end
%             if rdh_image(i, j) == Pc_i_rec
%                 LM_size = LM_size + 1;
%             end
%         end
%     end
% end

LM_rec=message_rec(1:LM_size);
i_j_p = bi2de(message_rec(17+LM_size));
if i_j_p == 0
    Ps_p = bi2de(message_rec(1+LM_size : 8+LM_size));
    Pc_p = bi2de(message_rec(9+LM_size : 16+LM_size));
else
    Ps_p = bi2de(message_rec(1+LM_size : 8+LM_size));
    Pc_p = bi2de(message_rec(9+LM_size : 16+LM_size));
end
first_17_pixels_rec = bitxor(first_17_pixels_rec, message_rec(18+LM_size : 34+LM_size)');
payload_rec=message_rec(35+LM_size:end);

%Shift back
if i_j_rec == 1
    for i = 1 : image_size(1)
        for j = 1 : 2 : image_size(2)
            if i == 1 && j <= 17 && j >= 1
                continue;
            else
                if D_r == 1
                    if rdh_image(i, j+1) > Ps_rec && rdh_image(i, j+1) < Pc_rec
                        rdh_image(i, j+1) = rdh_image(i, j+1) - D_r;
                    end
                else
                    if rdh_image(i, j+1) < Ps_rec && rdh_image(i, j+1) > Pc_rec
                        rdh_image(i, j+1) = rdh_image(i, j+1) - D_r;
                    end
                end
            end
        end
    end
else
    for i = 1 : image_size(1)
        for j = 1 : 2 : image_size(2)
            if i == 1 && j <= 17 && j >= 1
                continue;
            else
                if D_c == 1
                    if rdh_image(i, j) > Pc_rec && rdh_image(i, j) < Ps_rec
                        rdh_image(i, j) = rdh_image(i, j) + D_c;
                    end
                else
                    if rdh_image(i, j) < Pc_rec && rdh_image(i, j) > Ps_rec
                        rdh_image(i, j) = rdh_image(i, j) + D_c;
                    end
                end
            end
        end
    end
end

%Undo location map
if LM_size ~= 0
    temp = 1;
    for i = 1 : image_size(1)
        for j = 1 : 2 : image_size(2)
            if i == 1 && j <= 17 && j >= 1
                continue;
            else
                if i_j_rec == 0
                    if rdh_image(i, j) == Pc_rec
                        if LM_rec(temp) == 1
                            rdh_image(i, j) = rdh_image(i, j) + D_c;
                            temp = temp + 1;
                        else
                            temp = temp + 1;
                        end
                    end
                else
                    if rdh_image(i, j+1) == Pc_rec
                        if LM_rec(temp) == 1
                            rdh_image(i, j+1) = rdh_image(i, j+1) - D_r;
                            temp = temp + 1;
                        else
                            temp = temp + 1;
                        end
                    end
                end
            end
        end
    end

end
for j = 1 : 17
    rdh_image(1, j) = first_17_pixels_rec(j, 1);
end


%Undo rest of the iteration
i_j_rec = i_j_p;
Ps_rec = Ps_p;
Pc_rec = Pc_p;

% disp("P_s")
% isequal(P_s_rec,P_s_list(iteration+1))
% disp("P_c")
% isequal(P_c_rec,P_c_list(iteration+1))

while (Ps_rec ~= 0 || Pc_rec ~= 0)
    if i_j_rec == 0
        if Ps_rec > Pc_rec %UHS
            D_c = 1;
        else %DHS
            D_c = -1;
        end

        message_rec = [];
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                    if rdh_image(i, j) == Ps_rec
                        message_rec = [message_rec, 0];
                    elseif rdh_image(i, j) == Ps_rec - D_c
                        message_rec = [message_rec, 1];
                        rdh_image(i, j) = rdh_image(i, j) + D_c;
                    end
            end
        end

        LM_size = 0;
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                    if rdh_image(i, j) == Pc_rec
                        LM_size = LM_size + 1;
                    end
            end
        end


    else
        if Ps_rec < Pc_rec %RHS
            D_r = 1;
        else %LHS
            D_r = -1;
        end

        message_rec = [];
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                    if rdh_image(i, j+1) == Ps_rec
                        message_rec = [message_rec, 0];
                    elseif rdh_image(i, j+1) == Ps_rec + D_r
                        message_rec = [message_rec, 1];
                        rdh_image(i, j+1) = rdh_image(i, j+1) - D_r;
                    end
            end
        end
        
        LM_size = 0;
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                    if rdh_image(i, j+1) == Pc_rec
                        LM_size = LM_size + 1;
                    end
            end
        end
    end
    
%     LM_size = 0;
%     if i_j_rec == 0
%         for i = 1 : image_size(1)
%             for j = 1 : 2 : image_size(2)
%                 if rdh_image(i, j) == Pc_rec
%                     LM_size = LM_size + 1;
%                 end
%             end
%          end
%     else
%         for i = 1 : image_size(1)
%             for j = 1 : 2 : image_size(2)
%                  if rdh_image(i, j+1) == Pc_rec
%                     LM_size = LM_size + 1;
%                  end
%             end
%          end
%     end
    LM_rec=message_rec(1:LM_size);
    
    i_j_p = bi2de(message_rec(17+LM_size));
    if i_j_p == 0
        Ps_p = bi2de(message_rec(1+LM_size : 8+LM_size));
        Pc_p = bi2de(message_rec(9+LM_size : 16+LM_size));
    else
        Ps_p = bi2de(message_rec(1+LM_size : 8+LM_size));
        Pc_p = bi2de(message_rec(9+LM_size : 16+LM_size));
    end

    
%     Ps_i_p = bi2de(message_rec(1+LM_size : 8+LM_size));
%     Ps_j_p = bi2de(message_rec(9+LM_size : 16+LM_size));
%     Pc_i_p = bi2de(message_rec(17+LM_size : 24+LM_size));
%     Pc_j_p = bi2de(message_rec(25+LM_size : 32+LM_size));
    payload_rec=[ message_rec(18+LM_size:end), payload_rec]; 
    
    %Shift back
    if i_j_rec == 1
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if D_r == 1
                    if rdh_image(i, j+1) > Ps_rec && rdh_image(i, j+1) < Pc_rec
                        rdh_image(i, j+1) = rdh_image(i, j+1) - D_r;
                    end
                else
                    if rdh_image(i, j+1) < Ps_rec && rdh_image(i, j+1) > Pc_rec
                        rdh_image(i, j+1) = rdh_image(i, j+1) - D_r;
                    end
                end
            end
        end
    else
        for i = 1 : image_size(1)
            for j = 1 : 2 : image_size(2)
                if D_c == 1
                    if rdh_image(i, j) > Pc_rec && rdh_image(i, j) < Ps_rec
                        rdh_image(i, j) = rdh_image(i, j) + D_c;
                    end
                else
                    if rdh_image(i, j) < Pc_rec && rdh_image(i, j) > Ps_rec
                        rdh_image(i, j) = rdh_image(i, j) + D_c;
                    end
                end
            end
        end
    end
    
    
    %Undo location map

        if LM_size ~= 0
            temp = 1;
            if i_j_rec == 0
                for i = 1 : image_size(1)
                    for j = 1 : 2 : image_size(2)
                            if rdh_image(i, j) == Pc_rec
                                if LM_rec(temp) == 1
                                    rdh_image(i, j) = rdh_image(i, j) + D_c;
                                    temp = temp + 1;
                                else
                                    temp = temp + 1;
                                end
                            end                           
                    end
                end
            else
                for i = 1 : image_size(1)
                    for j = 1 : 2 : image_size(2)
                            if rdh_image(i, j+1) == Pc_rec
                                if LM_rec(temp) == 1
                                    rdh_image(i, j+1) = rdh_image(i, j+1) - D_r;
                                    temp = temp + 1;
                                else
                                    temp = temp + 1;
                                end
                            end
                    end
                end
            end
        end
    
    i_j_rec = i_j_p;
    Ps_rec = Ps_p;
    Pc_rec = Pc_p;
        %     disp("image_hor")
    %     isequal(image_hor,ref_image_hor(:,iteration+1))
    %     [P_s_rec P_c_rec]
end

re_image=rdh_image;
% payload_length_max=2*ceil(log2(image_size(1)*image_size(2)+1)); 
% payload_length=bi2de(payload_rec(1:payload_length_max)');
% payload_rec(1:payload_length_max)=[];
% payload_rec(payload_length+1:end)=[];
toc
end

