% 2020 March 25
% Jennifer Hu
% Process probabilities generated by ilastik. Fill in holes and
% concavities in organoid boundary, remove small regions, etc. Quantifies
% the results using quantify_img and saves in a csv file. Generates before
% and after images of processing.
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if (~exist('const', 'var'))
    [const, consts] = constants();
end
if (exist('\Volumes', 'dir'))
    exptdir = fullfile('E:', 'timelapse', '2019-06-14 timelapse');
else
    exptdir = fullfile('/Volumes', 'JenniferHD', 'timelapse', '2019-06-14 timelapse');
end
ilastikdir = fullfile(exptdir, 'Ilastik');
probdir = fullfile(ilastikdir, 'Probabilities'); mkdir(probdir);
centersdir = fullfile(ilastikdir, 'Centers'); mkdir(centersdir);
% tdatadir = fullfile('C:','Users','jhu','Box','Gartnerlab Data', ...
%     'Individual Folders','Jennifer Hu','Data','Timelapse Data',...
%     '2019-06-14','Data');
tdatadir = fullfile(exptdir, 'Data'); mkdir(tdatadir);
tdatafile = fullfile(tdatadir, 'quantifiedt.csv');
trpsfile = fullfile(tdatadir, 'radialprofilest.csv');

%% find center slices for z-stacks using the segmentations
centersTable = imsequence_centers(ilastikdir, const);

%% initialize file with header
files_done = {};
header_metrics = strjoin( ...
    [{'imfilename', 'frame', 'z'}, consts{strcmp(consts{1}, 'metrics')}], ',');
header_rps = 'imfilename,frame,z,x,fM';
if (exist(tdatafile, 'file'))
    c = input('Do you want to overwrite, append, or cancel? (o/a/): ', 's');
    switch c
        case 'o'
            % make a backup
            backup(tdatafile);
            datafID = fopen(tdatafile, 'w');
            fprintf(datafID, header_metrics);
            % make a backup
            backup(trpsfile);
            rpfID = fopen(trpsfile, 'w');
            fprintf(rpfID, header_rps);
        case 'a'
            backup(tdatafile);
            backup(trpsfile);
            % read csv files and find existing
            dataTable = readtable(tdatafile, ...
                'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
            files_done = dataTable.imfilename;
            % a stands for append
            datafID = fopen(tdatafile, 'a');
            rpfID = fopen(trpsfile, 'a');
        otherwise % cancel
            fprintf('... Canceled.\n')
            return
    end
else
    datafID = fopen(tdatafile, 'w');
    rpfID = fopen(trpsfile, 'w');
    fprintf(datafID, header_metrics);
    fprintf(rpfID, header_rps);
end

% iterate through
% start the timer
tic
n_imgs = height(centersTable);
for i=1:n_imgs
    filename = centersTable.filename{i};
    % open file
    [~,imname,~] = fileparts(filename);
    if (ismember(imname, files_done))
        continue
    end
    % print the current file and timer
    fprintf('\n    %s - %s (%d of %d)', tocstring(), imname, i, n_imgs);
    dmask = imread(fullfile(centersdir, [imname, '.png'])); 
    % generate metrics for this image
    [metric_row, rp] = quantify_dmask(dmask, const);
    % update the user if error
    assert(any(metric_row), 'Row is all zeros.');
    % save all in files
    fprintf(datafID, sprintf(['\n%s', repmat(',%d', 1, 2+length(metric_row))], ...
        imname, centersTable.frame(i), centersTable.z(i), metric_row(:)));
    if ~isempty(rp)
        values = [(0:99); rp]; fprintf(rpfID, '\n');
        fprintf(rpfID, strjoin(repmat({sprintf('%s,%d,%d,%%d,%%g', ...
            imname, centersTable.frame(i), centersTable.z(i))},100,1), '\n'), values);
    end
end
fprintf('\n\nCompleted after %s.\n\n', tocstring());
fclose(datafID); fclose(rpfID);