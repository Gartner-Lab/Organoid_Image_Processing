% 	6 January 2020
% 	Jennifer L Hu
%
% 	Accesses RGB images (Cleaned) and quantifies each.
%	Saves results in quantifile identified by row and slice (r and s).
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if (~exist('const', 'var'))
    [const, consts] = constants();
end
testdir = fullfile(const.slicedir, 'Test Data');
sourcedir = fullfile(testdir, 'Cleaned');
testquantifile = fullfile(testdir, 'quantified.csv');
sourcefiles = dir(sourcedir);
n_imgs = length(sourcefiles);
files_done = {};

%% initialize file with header
header = strjoin([{'imfilename', 'r', 's'}, consts{strcmp(consts{1}, 'metrics')}], ',');
if (exist(testquantifile, 'file'))
    c = input('Do you want to overwrite, append, or cancel? (o/a/): ', 's');
    switch c
        case 'o'
            % make a backup
            backup(testquantifile);
            datafID = fopen(testquantifile, 'w');
            fprintf(datafID, header);
        case 'a'
            backup(testquantifile);
            % read csv files and find existing
            dataTable = readtable(testquantifile, ...
                'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
            files_done = dataTable.imfilename;
            % a stands for append
            datafID = fopen(testquantifile, 'a');
        otherwise % cancel
            fprintf('... Canceled.\n')
            return
    end
else
    datafID = fopen(testquantifile, 'w');
    fprintf(datafID, header);
end
% start the timer
tic;


%%
for f=1:n_imgs
    filename = sourcefiles(f).name;
    [~, imname, ~] = fileparts(filename);
    if (startsWith(filename, '.') || endsWith(imname, '_LEP') || endsWith(imname, '_MEP'))
        continue
    end
    imname = strrep(imname, '_Cleaned Segmentation', '');
    % use same imfilename as slidedatafile does
    imfilename = sprintf('%s.png', imname);
    if (ismember(imfilename, files_done))
        continue
    end
    fprintf('\n%s - %s (%d of %d)', tocstring(), imname, f, n_imgs);

    %% open image produced by process_test, which is in Ilastik pixels-1
    imIlastik = imread(fullfile(sourcedir, filename)) + 1;
    % imwrite converts the indices to zero-based indices
    im = ilastik2rgb(imIlastik, const);

    %% Quantify
    % generate metrics for this image
    [metric_row, ideal] = quantify_img(im);
    % update the user if error
    assert(any(metric_row), 'Row is all zeros.');
    % save images
    % imwrite(ideal, fullfile(testdir, 'Idealized', filename));
    
    % determine r and s values from name (112R 24h-02_r818_s11.png)
    r = regexp(imfilename,'_r[0-9]+_','match');
    assert(length(r) == 1);
    r = r{1}; r = str2double(r(3:end-1));
    s = regexp(imfilename,'_s[0-9]+','match');
    assert(length(s) == 1);
    s = s{1}; s = str2double(s(3:end));
    
    % save all in file
    fprintf(datafID, sprintf(['\n%s', repmat(',%d', 1, 2+length(metric_row))], ...
        imfilename, r, s, metric_row(:)));
end

% finish
fprintf('\nCompleted after %s. Saved results in %s.\n', tocstring(), testquantifile); beep();
