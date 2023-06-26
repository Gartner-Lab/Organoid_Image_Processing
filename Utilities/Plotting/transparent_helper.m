%   13 February 2018
%   Jennifer L Hu
%   transparent_helper.m
%
%   Opens epmasks, crops them, converts black pixels to alpha, and saves as
%   pngs in alphadir.

constants();
n_files = length(editmasknames);
alphadir = fullfile(imdir,'masks','alpha');

for f=1:n_files
    % open image
	file = editmasknames(f);
    afile = fullfile(alphadir,file.name);
    if exist(afile,'file') > 0
        % skip
        continue;
    end
	RGB = imread(fullfile(epmaskdir,file.name));
    % remove black border
    dmask = rm_border(rgb2dmask(RGB));
    RGB = dmask2rgb(dmask);
    % find black pixels
    amask = double(dmask > 0);
    % save
    imwrite(RGB,afile,'png','Alpha',amask);
end

