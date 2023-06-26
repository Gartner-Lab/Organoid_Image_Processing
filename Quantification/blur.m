function [blurred] = blur(img)
    % img is an RGB
    M = imgaussfilt(img(:,:,1),2);
    L = imgaussfilt(img(:,:,2),2);
    blurred = img;
    blurred(:,:,1) = M;
    blurred(:,:,2) = L;
end