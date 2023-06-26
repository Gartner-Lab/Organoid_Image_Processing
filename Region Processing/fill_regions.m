% Jennifer L Hu
% given labels and MEP/LEP images or one [0 1 2] image, returns an image
% with [0 1 2] assigned to the labels based on whether MEP or LEP pixels
% are more common in the border
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
function [filled] = fill_regions(L, MEP, LEP)
    filled = zeros(size(MEP));
    n_regions = length(unique(L))-1;
    % grayscale images
    if length(unique(MEP)) > 3
        min_intensity = 0.01*max(max(max(LEP)), max(max(MEP)));
        MEPish = (MEP > LEP) & (MEP > min_intensity);
        LEPish = (LEP > MEP) & (LEP > min_intensity);
        for k = 1:n_regions
            region = (L == k);
            smoother = strel('disk', 3);
            border = imdilate(region, smoother) & ~region;
            % if more MEPish than LEPish 
            if sum(MEPish & border) > sum(LEPish & border)
                filled(region) = 1;
            else
                filled(region) = 2;
            end
        end
    % binary images
    else
        % passed in only one image containing [0 1 2]
        assert(~exist('LEP','var'))
        for k = 1:n_regions
            region = (L == k);
            smoother = strel('disk', 3);
            border = imdilate(region, smoother) & ~region;
            % if more MEPish than LEPish
            filled(region) = mode(MEP(border));
        end
    end
end