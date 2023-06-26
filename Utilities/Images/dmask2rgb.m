% turns a [0 1 2] mask to an RGB image (values 0 and 1)
function [rgb] = dmask2rgb(dmask)
    rgb = zeros([size(dmask) 3]);
    % red channel = MEP
    rgb(:,:,1) = dmask == 1;
    % green channel = LEP
    rgb(:,:,2) = dmask == 2;
end