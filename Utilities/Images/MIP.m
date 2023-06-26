% Returns maximum intensity projection of image
function [mip] = MIP(varargin)
    % picdata,z,nch,chL,chM
    picdata = varargin{1}; nch = varargin{2};
    chL = varargin{3}; chM = varargin{4};
    % initialize
    siz = size(picdata{1,1});
    mipM = zeros(siz); mipL = zeros(siz);
    for z=1:nz
        imgLEP = picdata{slice_idx(z, chL, nch),1};
        imgMEP = picdata{slice_idx(z, chM, nch),1};
        mipL = max(mipL,imgLEP);
        mipM = max(mipM,imgMEP);
    end
    % scale values from 0 to 1
    mipM = double(mipM); mipM = mipM/max(max(mipM));
    mipL = double(mipL); mipL = mipL/max(max(mipL));
    % make RGB to save as image
    mip = zeros([siz 3]);
    mip(:,:,1) = mipM;
    mip(:,:,2) = mipL;
end