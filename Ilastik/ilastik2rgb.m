function [rgb] = ilastik2rgb(imIlastik, const)
    % convert Ilastik output numbers = struct('M', 1, 'L', 2, 'E', 3, 'H', 4);
    % into an RGB image where R = M, G = L, and everything else is 0
    rgb = zeros([size(imIlastik) 3]);
    % red channel = MEP
    rgb(:,:,1) = imIlastik == const.pxtype_ilastik.M;
    % green channel = LEP
    rgb(:,:,2) = imIlastik == const.pxtype_ilastik.L;
end