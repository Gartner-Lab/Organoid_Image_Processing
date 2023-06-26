%   13 February 2018
%   Jennifer L Hu
%   invert_masks
%
%   Inverts masks in edited+processed. Saves in inverted.
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
constants();
n_files = length(editmasknames);	

for f=1:n_files
    % open image
	file = editmasknames(f);
    epfile = fullfile(epmaskdir,file.name);
    ifile = fullfile(imaskdir,file.name);
    if exist(ifile,'file') > 0
        % skip
        continue;
    end
	img = imread(epfile);
    [~, M, L, ~] = rgb2dmask(img);
    inverted = dmask2rgb(M*2 + L);
    % save
    imwrite(inverted,ifile);
end