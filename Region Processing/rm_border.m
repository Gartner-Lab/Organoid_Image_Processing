% Removes rows and columns that have only zeros
% Only works on 2D images.
function [no_border] = rm_border(img)
    % sum along rows and columns
    row_sum = sum(img,2); col_sum = sum(img,1);
    % smallest row/col with nonzero value
    r1 = find(row_sum, 1);
    c1 = find(col_sum, 1);
    % largest row/col with nonzero value
    r2 = find(row_sum, 1, 'last');
    c2 = find(col_sum, 1, 'last');
    % subset inputs
    no_border = img(r1:r2, c1:c2);
end