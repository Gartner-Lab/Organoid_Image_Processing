function [dmask] = ilastik2dmask(imIlastik, const)
    % convert Ilastik output numbers = struct('M', 1, 'L', 2, 'E', 3, 'H', 4);
    % into a dmask image with dmask output numbers. Collapse E and H.
    dmask = zeros(size(imIlastik));
    
    dmask(imIlastik == const.pxtype_ilastik.M) = const.pxtype_dmask.M;
    dmask(imIlastik == const.pxtype_ilastik.L) = const.pxtype_dmask.L;
    dmask(imIlastik == const.pxtype_ilastik.E | ...
        imIlastik == const.pxtype_ilastik.H) = const.pxtype_dmask.E;
end