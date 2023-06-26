% turns an RGB image into a double mask [0 1 2]
% RGB may be [0 255] or [0 1]
% also returns MEP, LEP, and both masks
function [dmask, M, L, both] = rgb2dmask(rgb, varargin)
    if (nargin == 1)
        [const, ~] = constants();
    else
        const = varargin(2);
        assert(isstruct(const));
    end
    % depending on the cmap this may not be pure red/green
    red = max(rgb(:,:,1),'all'); green = max(rgb(:,:,2),'all');
    dmask = const.pxtype_dmask.M*(rgb(:,:,1) == red) + ...
        const.pxtype_dmask.L*(rgb(:,:,2) == green);
    M = dmask == const.pxtype_dmask.M; L = dmask == const.pxtype_dmask.L; 
    both = dmask ~= const.pxtype_dmask.E;
end