% regionprops() returns "unexpected results) if regions are discontinuous.
% This function uses bwboundaries() instead, simply counting the number of
% pixels in the boundary. Connectivity conn. 4 will give more boundary
% pixels than 8 (the default). This function averages the two...
function [perimeter] = perimeter(mask)
    B = bwboundaries(mask, 4, 'holes');
    perimeter = 0;
    for i=1:length(B)
        perimeter = perimeter + size(B{i}, 1);
    end
    B = bwboundaries(mask, 8, 'holes');
    for i=1:length(B)
        perimeter = perimeter + size(B{i}, 1);
    end
    perimeter = perimeter/2;
end