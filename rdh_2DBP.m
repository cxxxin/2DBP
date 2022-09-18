% function rdh_BP
clear;

filepath = 'your_path';
index = 0;
dirOutput = dir(fullfile(filepath,'*.bmp'));
fileList = {dirOutput.name};

for i = 1:length(fileList)
name = char(fileList(i));
image = imread(strcat(filepath, strcat(name,"")));
for S = 1:20:80
    iteration_max = S;

%Payload
payload = imread('.\testimages2\2bit_bird.bmp');
payload_size = size(payload);
payload = reshape(payload, payload_size(1)*payload_size(2), 1);
payload = [payload; payload; payload; payload; payload; payload; payload; payload; payload; 
                 payload; payload; payload; payload; payload; payload; payload; payload; payload;
                 payload; payload; payload; payload; payload; payload; payload; payload; payload;
                 payload; payload; payload; payload; payload; payload; payload; payload; payload; 
                 payload; payload; payload; payload; payload; payload; payload; payload; payload;
                 payload; payload; payload; payload; payload; payload; payload; payload; payload;];

%Embedding
% [rdh_image, payload_embedding, payload_total, iteration]=embedding_0916(image, payload);
[r, payload_embedding1, payload_total, iterationr]=embedding_0916(image(:,:,1), payload, iteration_max);
[g, payload_embedding2, payload_total, iterationg]=embedding_0916(image(:,:,2), payload, iteration_max);
[b, payload_embedding3, payload_total, iterationb]=embedding_0916(image(:,:,3), payload, iteration_max);
if(max([iterationg,iterationr,iterationb]) <= iteration_max-20)
    continue;
end
% side_information = payload_total - length(payload_embedding);

% show rdh_image
% im = image(rdh_image);
rdh_image = [r,g,b];
image_size = size(r);
rdh_image = reshape(rdh_image,image_size(1),image_size(2),3);
rdh_image = uint8(rdh_image);
% img=imshow(uint8(rdh_image),'Border','tight','InitialMagnification',100);
savepath = 'your_savepath';
imwrite(uint8(rdh_image),char(strcat([savepath,num2str(S/2),'-'],strcat(name,""))));

%save rdh_image
 
%Recovery check
% [payload_rec1, r] = recovery_0916(r);
% [payload_rec2, g] = recovery_0916(g);
% [payload_rec3, b] = recovery_0916(b);
% re_image = [r,g,b];
% re_image = reshape(re_image,imgae_size(1),imgae_size(2),3);
% re_image = uint8(re_image);
% payload_rec1 = payload_rec1';
% payload_rec2 = payload_rec2';
% payload_rec3 = payload_rec3';
% payload_rec = [payload_rec1,payload_rec2,payload_rec3];

end

end %end for iterator of fileList
