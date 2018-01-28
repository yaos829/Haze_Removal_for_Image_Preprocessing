%clear workspace
clear;
clc;

%load test_picture
[fName pName]=uigetfile({'*.jpg'},'Open');

if fName
    original_im=imread([pName fName]); %∂¡»ÎÕº∆¨
end

%formatting im to float
original_im = double(original_im);
% separate different channels - RGB
R_channel = original_im(:, :, 1);
G_channel = original_im(:, :, 2);
B_channel = original_im(:, :, 3);

%create original_dark_channel image with same size
[m, n] = size(R_channel);
dark_channel_image = zeros(m,n);

%extract the minimum value of each point in RGB for dark_channel_image 
for i=1:m
    for j=1:n
        local_pixels =[R_channel(i,j), G_channel(i,j), B_channel(i,j)]; 
        dark_channel_image(i,j) = min(local_pixels );
    end
end

%image erode, minimum filtering
kernel = ones(30);
final_im = imerode(dark_channel_image, kernel);

%transform dark_channel_imaege into Picture Format
final_im = uint8(final_im);
figure,subplot(1,2,1), imshow(final_im);
title("Dark Channel Prior");

%definne the size of filter_window
wid_x = 2;
wid_y = 2;

%augment image by pixels(value=128)
augmented_im = ones(m+2*wid_x, n+2*wid_y, 3) * 128;
augmented_im(wid_x+1:m+wid_x, wid_y+1:n+wid_y, :) = original_im;

%find the value of Atmospheric light, which is the mean of top 0.1% value in
%dark_channel_prior
v_ac = reshape(dark_channel_image,1,m*n);
v_ac = sort(v_ac, 'descend');
Ac = mean(v_ac(1:uint8(0.001*m*n)));

%define and calculate minimum_matrix 
minimum = zeros(m+2*wid_x, n+2*wid_y);
for i= wid_x+1 : m+wid_x
    for j=wid_y+1: n+wid_y
        %extract local_window
        local_window = augmented_im(i-wid_x:i+wid_x, j-wid_y:j+wid_y, :);
        %separate RGB channels
        local_r = local_window(:, :, 1);
        local_g = local_window(:, :, 2);
        local_b = local_window(:, :, 3);
        
        %normalize this current pixel in 3 channels
        channel_values = [ R_channel(i-wid_x,j-wid_y) / Ac, G_channel(i-wid_x,j-wid_y) / Ac, B_channel(i-wid_x,j-wid_y) / Ac ];
        %find the min values in 3 channels
        minimum(i,j) = min(channel_values);
    end
end

%recover the augmented marix to previous size
original_minimum = ones(m,n);
original_minimum = minimum(wid_x+1:wid_x+m, wid_y+1:wid_y+n);

%assign the local minimum for each point(Image Erode)
kernel_erode = ones(2*wid_x+1,2*wid_y+1);
min_minimum = imerode(original_minimum, kernel_erode);

%define w as a parameter for adjustment 
w=0.95;
%define and calculate transmittance matrix
pre_t = ones(m,n);
true_t = pre_t - w*min_minimum;
subplot(1,2,2), imshow(uint8(true_t*255));
title("Transmittance map");

%set up a threshold for light transmittance
t0=0.1;
for i=1:m
    for j=1:n
        true_t(i,j) = max(t0, true_t(i,j));
    end
end

%recover the final image by haze function
final_image = (original_im - Ac) ./ true_t +Ac;
final_image = uint8(final_image);

%show the result
figure;

subplot(1,2,1), imshow(uint8(original_im));
title("Original image");

subplot(1,2,2),imshow(final_image);
title("After processing");