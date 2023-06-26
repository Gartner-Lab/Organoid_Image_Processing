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

ilastikdir = fullfile(const.slicedir, 'Ilastik', 'Probabilities');
maskdir = fullfile(const.slicedir, 'masks');
imgtype_brights = {'FP bright', 'FP dim', 'LSM_FP bright', 'LSM_FP dim'};
files_done = {};
h = figure('Position', [100 100 800 400]);

%% initialize file with header
header_metrics = strjoin( ...
    [{'imfilename', 'r', 's'}, consts{strcmp(consts{1}, 'metrics')}], ',');
header_rps = 'imfilename,r,s,x,fM';
if (exist(const.quantifile, 'file'))
    c = input('Do you want to overwrite, append, or cancel? (o/a/): ', 's');
    switch c
        case 'o'
            % make a backup
            backup(const.quantifile);
            datafID = fopen(const.quantifile, 'w');
            fprintf(datafID, header_metrics);
            % make a backup
            backup(const.rpfile);
            rpfID = fopen(const.rpfile, 'w');
            fprintf(rpfID, header_rps);
        case 'a'
            backup(const.quantifile);
            backup(const.rpfile);
            % read csv files and find existing
            dataTable = readtable(const.quantifile, ...
                'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
            files_done = dataTable.imfilename;
            % a stands for append
            datafID = fopen(const.quantifile, 'a');
            rpfID = fopen(const.rpfile, 'a');
        otherwise % cancel
            fprintf('... Canceled.\n')
            return
    end
else
    datafID = fopen(const.quantifile, 'w');
    rpfID = fopen(const.rpfile, 'w');
    fprintf(datafID, header_metrics);
    fprintf(rpfID, header_rps);
end

%% iterate through
n_imgtypes = length(imgtype_brights);
% start the timer
tic
for j=1:n_imgtypes
    imgtype_bright = imgtype_brights{j};
    if (~exist(fullfile(ilastikdir, imgtype_bright), 'dir'))
        continue
    end
    imgtype_bright_split = split(imgtype_bright, ' ');
    imgtype = imgtype_bright_split{1}; brightness = imgtype_bright_split{2};
    imgs = dir(fullfile(ilastikdir, imgtype_bright));
    n_imgs = length(imgs);
    fprintf('%s ----------------------------', imgtype_bright);
    for i=1:n_imgs
        filename = imgs(i).name;
        if (startsWith(filename, '.'))
            continue
        end
        [~, imname, ~] = fileparts(filename);
        imname = strrep(imname, '_Probabilities', '');
        % use same imfilename as slidedatafile does
        imfilename = sprintf('%s.png', imname);
        if (ismember(imfilename, files_done))
            continue
        end
        % print the current file and timer
        fprintf('\n    %s - %s (%d of %d)', tocstring(), imname, i, n_imgs);
        % open images
        file_probabilities = fullfile(ilastikdir, imgtype_bright, filename);
        [~, bfdata] = evalc('bfopen(file_probabilities)');
        img_size = size(bfdata{1,1}{1,1});
        n_pxtypes = numel(fieldnames(const.pxtype_ilastik));
        img_probabilities = zeros([img_size, n_pxtypes]);
        for k = 1:n_pxtypes
            img_probabilities(:,:,k) = bfdata{1,1}{k,1};
        end
        % convert probabilities to segmentation
        img_segmentation = ilastikp2dmask(img_probabilities, const);

        %% Clean the Ilastik output
        cleaned_segmentation = clean_segmentation(img_segmentation, const, img_probabilities);

        % save the result in Cleaned subfolder
        file_cleaned = fullfile(maskdir, 'Cleaned', sprintf('%s_Segmentation.png', imname));
        imwrite(cleaned_segmentation+1, const.cmap_dmask, file_cleaned, 'png');
        
        %% show before and after figure in the Results folder
        file_slice = fullfile(const.slicedir, 'raw', imgtype, imfilename);
        h; subplot(1,3,1); imshow(file_slice); title('Original');
           subplot(1,3,2); imshow(fullfile(const.slicedir, 'SBG', 'raw', imgtype, brightness, imfilename)); title('Pre-Processed');
           subplot(1,3,3); imshow(cleaned_segmentation+1, const.cmap_dmask); title('Segmented');
        figtitle(strrep(imname,'_','\_'));
        saveas(h, fullfile(const.datadir, 'Results', 'SegmentationProcess', sprintf('%s_Segmentation.png', imname)));
        % if no cells, skip image
        if ~any(cleaned_segmentation ~= const.pxtype_dmask.E, 'all')
            fprintf(' - no cells found.')
            continue
        end
        
        %% Quantify
        % generate metrics for this image
        [metric_row, rp] = quantify_dmask(cleaned_segmentation, const);
        % update the user if error
        assert(any(metric_row), 'Row is all zeros.');

        % determine r and s values from name (112R 24h-02_r818_s11.png)
        r = regexp(imfilename,'_r[0-9]+_','match');
        assert(length(r) == 1);
        r = r{1}; r = str2double(r(3:end-1));
        s = regexp(imfilename,'_s[0-9]+','match');
        assert(length(s) == 1);
        s = s{1}; s = str2double(s(3:end));

        % save all in files
        fprintf(datafID, sprintf(['\n%s', repmat(',%d', 1, 2+length(metric_row))], ...
            imfilename, r, s, metric_row(:)));
        values = [(0:99); rp]; fprintf(rpfID, '\n');
        fprintf(rpfID, strjoin(repmat({sprintf('%s,%d,%d,%%d,%%g', ...
            imfilename, r, s)},100,1), '\n'), values);
    end
    fprintf('\n');
end
fprintf('\n\nCompleted after %s.\n\n', tocstring());
fclose(datafID); fclose(rpfID);