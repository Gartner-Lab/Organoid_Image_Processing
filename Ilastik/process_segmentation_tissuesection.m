% 2021 January 6
% Jennifer Hu
%   For processing ilastik outputs of Sundus's tissue sections.
% 	Fill in holes and concavities in organoid boundary, remove small 
%   regions, etc. Quantifies the results and saves in a csv file. 
%   Generates before and after images of processing.
%   Differences from process_segmentation:
%   - detach from constants.m; all constants are in first section
%   - creates a new line for each object in image
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%% Change this
boxdir = ''; % file path to folder for saving files

segdir = fullfile(boxdir,'masks','segmentation');

masksdirout = fullfile(boxdir, 'masks'); % masksdir will have subfolders Segmentation, Cleaned, SegmentationProcess
quantifile = fullfile(boxdir, '1Dapi_2K8_3K14_4K19 quant.csv'); % where you want the results csv to be saved
sizefile = fullfile(boxdir, 'px_scaling', 'COH_Rd1.csv');
% when the ilastik output is read in, what are the values of each cateogory?
px = struct('L',42,'M',85,'D',127,'U', 170, 'E', 212); % this is also in clean_segmentation_tissuesection

% what colors do you want the output image to have?
cmap_5mask = zeros(255,3);
cmap_5mask(px.L+1,:) = [13, 176, 75] / 255;
cmap_5mask(px.M+1,:) = [240, 4, 127] / 255;
cmap_5mask(px.D+1,:) = [242, 218, 3] / 255;
cmap_5mask(px.U+1,:) = [50 50 50] / 255;
cmap_5mask(px.E,:) = [0 0 0];
    
%% Set up
imgs = dir(segdir);
% metrics come from quantify_dmask
metrics = [{'MEP_Fraction', 'Pixels', 'Circularity', 'Diameter', ...
    'MEP_Components', 'LEP_Components', 'MEP_Solidity', 'LEP_Solidity', ...
    'Edge_MEP_Fraction'}, ...
    arrayfun(@(x) sprintf('Outer%d_MEP_Fraction', x), 1:10, 'UniformOutput', false), ...
    {'Inner_MEP_Fraction', 'Bounding_Box'}];
n_imgs = length(imgs); files_done = {}; appendmode = 0;
sizeTable = readtable(sizefile, ...
                'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);

%% initialize file with header
header = strjoin([{'imfilename', 'object'}, metrics], ',');
if (exist(quantifile, 'file'))
    c = input('Do you want to overwrite, append, or cancel? (o/a/): ', 's');
    switch c
        case 'o'
            % make a backup
            backup(quantifile);
            datafID = fopen(quantifile, 'w');
            fprintf(datafID, header);
        case 'a'
            backup(quantifile); appendmode = 1;
            % read csv files and find existing
            dataTable = readtable(quantifile, ...
                'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
            files_done = unique(dataTable.imfilename);
            % a stands for append
            datafID = fopen(quantifile, 'a');
        otherwise % cancel
            fprintf('... Canceled.\n')
            return
    end
else
    datafID = fopen(quantifile, 'w');
    fprintf(datafID, header);
end
% start the timer
tic
close all; h = figure(5); figure('Position', [100 100 800 300]);

for i=3:n_imgs
    filename = imgs(i).name; original_filename = filename;
    if contains(filename, '_Simple Segmentation')
        filename = strrep(filename, '_Simple Segmentation', ''); % remove suffix
    end
    if ismember(filename, files_done), continue; end
    if contains(filename, '.DS_Store'), continue; end
    %% Iterate through folder
    [~, imname, ~] = fileparts(filename);
    % print the current file and timer
    fprintf('\n%s - %s (%d of %d)', tocstring(), imname, i-2, n_imgs-2);
    
    %% Open and clean images   
    file_cleaned = fullfile(masksdirout, 'Cleaned', filename);
    psize = sizeTable.px(strcmp(sizeTable.imfilename, filename));
    if isempty(psize)
            warning('psize not assigned');
    end
    file_segmentation = fullfile(segdir, original_filename);
    img_segmentation = imread(file_segmentation);
    if (reuse_cleaned && isfile(file_cleaned))
        cleaned_segmentation = imread(file_cleaned);
        assert(all(cleaned_segmentation == px.E | ...
            cleaned_segmentation == px.L | ...
            cleaned_segmentation == px.M | ...
            cleaned_segmentation == px.U | ...
            cleaned_segmentation == px.D, 'all'), ...
            'Should have values matching mask.');
    else
        % Clean the Ilastik output
        cleaned_segmentation = clean_segmentation_tissuesection(img_segmentation, psize);
        imwrite(cleaned_segmentation, cmap_5mask, file_cleaned, 'png');
    end
    
    %% Quantify each object
    cells = (cleaned_segmentation ~= px.E);
    [cell_labels, n] = bwlabel(cells);
    for j = 1:n
        if appendmode && ismember(j,dataTable.object(strcmp(dataTable.imfilename, filename))), continue; end
        % generate metrics for this image
        object = cleaned_segmentation;
        object(cell_labels ~= j) = px.E;
        quantification = quantify_tissuesection(object, ...
            struct('n_metrics', length(metrics), 'px', px, 'psize', psize));
        assert(length(quantification.metric_row)+1 == length(metrics), ...
            '# quantification metrics needs to match metrics in constants.m'); % +1 for the string bounds
        % save all in file with bounds as a string
        fprintf(datafID, sprintf(['\n%s', repmat(',%g', 1, 1+length(quantification.metric_row)), ',%s'], ...
            filename, j, quantification.metric_row(:), regexprep(num2str(quantification.bounds),'\s*','-')));

        %% show before and after figure in the Results folder
        figure(h); subplot(1,2,1); imshow(imcrop(img_segmentation, quantification.bounds), cmap_5mask); title('Segmentation');
           subplot(1,2,2); imshow(imcrop(cleaned_segmentation, quantification.bounds), cmap_5mask); title('Processed');
        figtitle(sprintf('%s (%d) - Outer 2um LEP = %g', strrep(imname,'_','\_'), j, ...
            1-quantification.metric_row(strcmp(metrics, 'Outer2_MEP_Fraction'))));
        saveas(h, fullfile(masksdirout, 'SegmentationProcess', ...
            sprintf('%s (%d).png', imname, j)));
    end
    if ~(reuse_cleaned || isfile(file_cleaned))
        figure(h); subplot(1,2,1); imshow(img_segmentation, cmap_5mask); title('Segmentation');
           subplot(1,2,2); imshow(cleaned_segmentation, cmap_5mask); title('Processed');
        figtitle(sprintf('%s', strrep(imname,'_','\_')));
        saveas(h, fullfile(masksdirout, 'SegmentationProcess', ...
                sprintf('%s.png', imname)));
    end
end
fprintf('\n\nCompleted after %s.\n\n', tocstring());
fclose(datafID); close all;