% given a label matrix produced by bwboundaries, returns the k
% and min area of the smallest object in the region
function [min_area, min_k] = find_min_obj(L,k)
    [rows, cols] = size(L);
    min_area = rows*cols;
    min_k = 1;
    for i=1:k
        n = sum(sum(L == i));
        if n < min_area
            min_area = n;
            min_k = i;
        end
    end
end