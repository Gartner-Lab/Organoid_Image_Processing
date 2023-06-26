function [rgb] = pic2rgb(varargin)
    % picdata,z,nch,chL,chM,[chMG]
    picdata = varargin{1}; z = varargin{2};
    if ischar(z)
        z = str2double(z);
    end
    nch = varargin{3}; chL = varargin{4}; chM = varargin{5};
    siz = size(picdata{1,1});
    if ~isempty(chL)
        imgLEP = picdata{slice_idx(z, chL, nch),1};
    else
        imgLEP = zeros(siz);
    end
    if ~isempty(chM)
        imgMEP = picdata{slice_idx(z, chM(1), nch),1};
    else
        imgMEP = zeros(siz);
    end
    if length(chM) > 1
        imgMEP = imgMEP + picdata{slice_idx(z, chM(2), nch),1};
    end
    % scale values from 0 to 1
    imgMEP = double(imgMEP); imgMEP = imgMEP/max(max(imgMEP));
    imgLEP = double(imgLEP); imgLEP = imgLEP/max(max(imgLEP));
    % make RGB to save as image
    rgb = zeros([siz 3]);
    rgb(:,:,1) = imgMEP;
    rgb(:,:,2) = imgLEP;
    if nargin == 6
        chMG = varargin{6};
        imgMG = picdata{slice_idx(z,chMG,nch),1};
        imgMG = double(imgMG); imgMG = imgMG/max(max(imgMG));
        rgb(:,:,3) = imgMG;
    end
end