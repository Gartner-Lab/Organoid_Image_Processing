% circle.m
% Start with an RGB image of an organoid. Remove the border.
% From cx,cy, make radial intensity profiles. (Includes trimming 0 values
% from ends and stretching intensity profiles to match longest line).
% Return 2 new RGB images: profiles and profiles weighted by pixel use.
function [profiles, weighted] = circle(img,cx,cy)
    % get masks from RGB image
    [dmask,~,~,~] = rgb2dmask(img);
    % convert to 2D
	[profiles2d, cov_img] = rprofiles(dmask,cx,cy);
    [cprofiles2d, ~] = rprofiles(cov_img,cx,cy);
    profiles = zeros([size(profiles2d), 3]);
    profiles(:,:,1) = profiles2d == 1;
    profiles(:,:,2) = profiles2d == 2;
    % interpolate any 0 values out
    cprofiles2d(cprofiles2d == 0) = NaN;
    cprofiles2d = inpaint_nans(cprofiles2d);
    assert(~any(any(isnan(cprofiles2d))))
    % if anything's 0 or less, set it to eps
    cprofiles2d(cprofiles2d <= 0) = eps;
    % divide by # of times pixel was used
    weighted = double(profiles);
    weighted(:,:,1) = weighted(:,:,1) ./ cprofiles2d;
    weighted(:,:,2) = weighted(:,:,2) ./ cprofiles2d;
end