%   20 January 2018
%   Jennifer L Hu
%   process_edits
%
%   Processes masks in edited and saves them to edited+processed.
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
constants();
n_files = length(editmasknames);	

for f=1:n_files
    % open image
	file = editmasknames(f);
    epfile = fullfile(epmaskdir,file.name);
    if exist(epfile,'file') > 0
        % skip existing
        continue;
    end
	img = imread(fullfile(emaskdir,file.name));
    dmask = rgb2dmask(img);
    processed = dmask2rgb(process_predictions(dmask));
    % save
    imwrite(processed,epfile);
    fprintf('%d of %d\n',f,n_files);
end
fprintf('Completed processing %d mask files.\n',n_files);