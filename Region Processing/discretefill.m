%%  discretefill(im, mask)
%   A variant of the MATLAB built-in function regionfill, with values as
%   discrete nominal labels rather than continuous values. Assigns highest
%   probability label to each pixel.
function [filledim] = discretefill(im, mask)
    colors = unique(im);
    ncolors = length(colors);
    [h, w] = size(im);
    probabilities = zeros(h, w, ncolors);
    for i = 1:ncolors
        probabilities(:,:,i) = regionfill(mat2gray(im == colors(i), [0,1]), mask);
    end
    % return 2D matrix with index of max probability across dimension 3
    [~, idx] = max(probabilities, [], 3);
    % index into color map and return filledim
    filledim = colors(idx);
end