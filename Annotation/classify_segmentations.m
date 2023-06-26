% 4 November 2020
% Jennifer L Hu
% For annotating images that I already made segmentations of
% using process_segmentation_multipage.m. I want it to be an upgraded but
% backwards-compatible version of classify_outcomes.

if (~exist('const', 'var'))
    [const, consts] = constants();
end
classed_header = consts{strcmp(consts{1}, "classed_header")};
processed_header = consts{strcmp(consts{1}, "processed_header")};
%% File I/O
if exist(const.classedfile, 'file')
    fprintf('Savefile: %s\n', const.classedfile);
    % read csv files
    classedTable = readtable(const.classedfile, 'Delimiter', ',', 'ReadVariableNames', true);
    % extract first two columns of const.classedfile and get last values
    lasti = max(classedTable.i);
    lastj = max(classedTable.j(classedTable.i == lasti));
    r = height(classedTable);
    [~, name, ext] = fileparts(const.classedfile);
    backup(const.classedfile);
    % a stands for append
    classedfID = fopen(const.classedfile, 'a');
    fprintf('\nAppending to %s...\nSkipping images up to (%d, %d)...\n', ...
        const.classedfile, lasti, lastj);
else
    % create new file
    fprintf('Savefile: %s\n', const.classedfile);
    classedfID = fopen(const.classedfile, 'w');
    % add classed_header row
    fprintf(classedfID, strjoin(classed_header, ','));
    % starting fresh! start at lastj = 2 because dir  has . and .. as elements
    lasti = 1; lastj = 2; r = 0;
end
if exist(const.processedfile, 'file')
    fprintf('Appending to file: %s\n', const.processedfile);
    backup(const.processedfile);
    % read csv files and find last
    processedTable = readtable(const.processedfile, ...
        'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
    % find last row in classedTable with non-empty outcomes
    lr = r;
    while isempty(classedTable.outcomes{lr})
        lr = lr-1;
    end
    assert(lr == processedTable.r(end), 'classed_raw and classed_processed should be at the same stage.');
    % a stands for append
    processedfID = fopen(const.processedfile, 'a');
    fprintf('Skipping images up to row %d...\n', r);
else
    processedfID = fopen(const.processedfile, 'w');
    fprintf(processedfID, strjoin(processed_header, ','));
    % start fresh
    r = 0;
end

% initialize figure and callback functions
h = figure(1); set(h, 'Position', [0 0 1000 650])
% intiialize variables
metadata_array = cell(0); folder_name = ''; file_name = '';

%% Iterate through CZI files
% generate list of czi files from folders
csvTable = dir_csv_reader(const.csvfile);
n_folders = height(csvTable);
for i = lasti:n_folders
    % folder access and channel info
    f = fullfile(const.czidir, csvTable.folder{i});
    f_contents = dir(f);
    [nch, chL, chM, chMG] = get_folder_ch(csvTable.folder{i}, csvTable);
    % if this file exists the images have been segmented and quantified
    datapath = fullfile(f, '..', 'organoid_data.csv');
    seg = false;
    if isfile(datapath)
        seg = true;
        % open the data file
        segTable = readtable(datapath, ...
            'Delimiter',',','ReadVariableNames',true);
        % here are the centers
        imgs = dir(fullfile(f, '..', 'masks', 'Centers'));
        n_imgs = length(imgs); assert(n_imgs-2 == height(segTable), 'Image count mismatch.');
    end
    % iterate over folder contents (each "content" is a czi file)
    ncontents = length(f_contents);
    if lastj >= ncontents
        % last file in this folder was already done
        lastj = 2;
        continue
    end
    % contents' first two entries are . and .. so start at j = 3
    for j = (lastj+1):ncontents
        content = f_contents(j);
        [~, namecore, ext] = fileparts(content.name);
        if (content.isdir || ~strcmp(ext, '.czi'))
            % skip this one
            continue
        end
        
        % check if problem file
        if (contains(f, '2017-01-14 240L 353P') && ...
            (contains(content.name, '26h') || contains(content.name, '240L 48h') || contains(content.name, '240L 100M 48h')))
            chM = 1; chL = 3; chMG = 2;
        end
    
        % evaluate with evalc to stuff bfopen warnings into T
        [T, bfdata] = evalc('bfopen(fullfile(content.folder, content.name))');
        picdata = bfdata{1, 1};
        nz = length(picdata)/nch;
        first_img = 1;
        if nz > 21
            if nz < 30
                first_img = floor(nz/2)-9;
            else
                % this way I just have to scroll one direction
                first_img = 5;
            end
        end
        %% convert all slices to RGB and plot in a grid
        % find size of image
        siz = size(picdata{1, 1}); centerseg = 0; centersegpath = ''; rgbdata = 0;
        chG = chL; chR = chM; swapRG = 0;
        if seg
            % add one last slice for the segmentation
            centersegpath = fullfile(f, '..', 'masks', 'Centers', sprintf('%s.tiff', namecore));
            % find the center cleaned slice and display as the last image
            centerseg = dmask2rgb(imread(centersegpath));
            rgbdata = zeros([nz+1, siz, 3]);
        else
            % random number to swap L/M pixels (for better blinding)
            swapRG = mod(floor(10*rand()), 2) == 0;
            if swapRG
                chG = chM; chR = chL;
            end
            rgbdata = zeros([nz, siz, 3]);
        end
        for z = 1:nz
            % rgb is a [siz x 3] matrix 
            rgb = pic2rgb(picdata, z, nch, chG, chR);
            rgbdata(z, :, :, :) = rgb;
        end
        rgbdata(nz+1, :, :, :) = centerseg;
        
        %% plot
        clf(h);
        if (nz == 1)
            imshow(squeeze(rgbdata(1, :, :, :)));
        else
            imdata = {first_img, rgbdata};
            set(h, 'UserData', imdata);
            % plot multiple in grid
            h = imsgrid(h);
        end
        if seg % already segmented
            % find this in the segTable to get the quantification
            idx = find(strcmp(segTable.Filename, sprintf('%s.tiff', namecore)));
            assert(length(idx) == 1, sprintf('Should be exactly 1 matching %s', namecore));
            emf = segTable.Edge_MEP_Fraction(idx);
            icd = segTable.Intercentroid(idx);
            if emf > 0.75
                o = 'c';
            elseif emf < 0.25
                o = 'i';
            elseif icd > 0.25
                o = 's';
            elseif emf > 0.6 && icd > 0.2
                o = '>s';
            elseif emf < 0.4 && icd > 0.2
                o = '<s';
            elseif emf > 0.6
                o = '>m';
            elseif emf < 0.4
                o = '<m';
            else
                o = 'm';
            end
            % get the default answer ready
            default = {sprintf('%s%d', o, segTable.Z(idx))};
            % print the default slice number on the last slice
            ntitle(num2str(segTable.Z(idx)),'location','southeast','fontsize',20,'color','w');
        else
            default = {''};
        end
        % set up user input dialog window
        options.WindowStyle = 'normal';
        if nz == 1
            prompt = {'Outcome [c m s i < >] Lumen (blank/l):'};
            answer = inputdlg(prompt, 'Classification', 1, default, options);
            centers_sc = '1';
        else
            prompt = {'Outcome [c m s i < >] Lumen (blank/l) Center:'};
            answer = inputdlg(prompt, 'Classification', 1, default, options);
        end

        % if user pushes Cancel button
        if isempty(answer)
            fclose all; close all;
            fprintf('Processing canceled.\n');
            fprintf('Ended before (%d, %d)\n', ...
                i, j);
            return
        end
        if ~isempty(answer{1})
            % now go get them
            [outs, lums, centers, n_outs, n_centers] = extract_olc(answer{1});
            if nz > 1
                if ~(all(cellfun(@(x) (isempty(x) || (str2double(x) <= nz)), centers)))
                    fclose all; close all;
                    fprintf('Center value not in z-stack.\n');
                    fprintf('Ended before (%d, %d)\n', ...
                        i-2, j-2);
                    return
                end
                % outputs a cell because join works on string arrays
                centers_sc = join(centers, ';'); centers_sc = centers_sc{1};
            end
            if swapRG
                % modify answer{1}
                outs = invert_outs(outs);
            end
            outs_sc = join(outs, ';'); outs_sc = outs_sc{1};
            lums_sc = join(lums, ';'); lums_sc = lums_sc{1};
        else
            outs_sc = ''; lums_sc = ''; centers_sc = '';
            n_outs = 0; n_centers = 0;
        end        
        % add new line to const.classedfile preceded by newline
        fprintf(classedfID, '\n');
        fprintf(classedfID, const.classed_format, ...
            i, j, csvTable.folder{i}, content.name, ...
            outs_sc, lums_sc, centers_sc, csvTable.imgtype{i});
        r = r + 1;
        
        %% process file and folder names for metadata
        if (n_outs == 0) && (n_centers == 0)
            fprintf('no assignments\n');
        else
            %% check if this row is going to be the same as the last
            % compare to previous file name
            [~, new_name, ~] = fileparts(content.name);
            [~, old_name, ~] = fileparts(file_name);
            % reassign file name
            file_name = new_name;
            % not counting the numeric suffix, these names are the same and are in same folder
            if strcmp(folder_name, content.folder) && ...
                (strcmp(new_name(1:end-3), old_name(1:end-3)) ...
                || strcmp(new_name(1:end-3), old_name) ...
                || (strcmp(new_name, old_name(1:end-3))))
                % don't change the metadata
            else % acquire new metadata
                folder_name = csvTable.folder{i};
                metadata_array = extract_metadata(folder_name, file_name, consts);
            end

            %% print into processed file
            n_rows = length(outs);
            for i_row=1:n_rows
                out = outs{i_row}; lum = lums{i_row}; cen = centers{i_row};
                % r, i, j, folder, name, imgtype, outcome, lumen, metadata
                fprintf(processedfID, '\n');
                fprintf(processedfID, const.processed_format, ...
                    r, i, j, csvTable.folder{i}, content.name, csvTable.imgtype{i}, ...
                    out, lum, cen, metadata_array{:});
            end
        end
        fprintf('%d: %d of %d files\n', i-2, j-2, ncontents);
        % now move to next file
    end
    % now move to next folder
    lastj = 2;
end
fclose all; close all;
% now that all images are annotated, make slice table
c = input('You may want to double-check metadata. Would you like to make images from center slices now? (y/n): ', 's');
switch c
    case 'y'
        slice_imgs();
    case 'n'
        fprintf('\nRun slice_imgs() later. All done for now.\n');
end