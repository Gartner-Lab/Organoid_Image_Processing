% Works on binary images
function [img] = smoothen(img)
    [imX, imY] = size(img);
    % for each region
    [B, L, N, ~] = bwboundaries(img,'noholes');
    for i = 1:N
        img(L == i) = 0;
        b = B{i};
        windowWidth = 45;
        if length(b) < windowWidth
            continue
        end
        % smooth with a Savitzky-Golay sliding polynomial filter
        polynomialOrder = 2;
        smoothX = sgolayfilt(b(:,2), polynomialOrder, windowWidth);
        smoothY = sgolayfilt(b(:,1), polynomialOrder, windowWidth);
        new = poly2mask(smoothX, smoothY, imX, imY);
        % replace the region with the smoothed region
        img(new) = 1;
    end
end