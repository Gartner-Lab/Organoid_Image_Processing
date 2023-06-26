% % 10 July 2017
% Jennifer Hu
%
% Loads czi files (z-stacks) and displays them in Gallery view. User
% records organization outcomes with letters, lumenization, 
% number of slice corresponding to center.
%
% Correct, Mixed, Split, Inverted = [c m s i]
% Mostly is now two categories: better than mixed or split (>m, >s).
% Same classifications apply to "mostly inverted" (<m, <s).
%
% May follow up with fill_skipped. Do not change the order or folder
% 'include' of rows in dir_info.csv. New folder rows can be appended to
% the end of the file.
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if (~exist('const', 'var'))
    [const, consts] = constants();
end
classed_header = consts{strcmp(consts{1}, "classed_header")};
processed_header = consts{strcmp(consts{1}, "processed_header")};
csvTable = readtable(const.csvfile,'Delimiter',',');

%% File I/O
if exist(const.classedfile, 'file')
    fprintf('Savefile: %s\n', const.classedfile);
    % read csv files
    classedTable = readtable(const.classedfile, 'Delimiter', ',', 'ReadVariableNames', true);
    % extract folder and name columns
    done_folders = classedTable.folder; done_names = classedTable.name;
    r = max(classedTable.r); lasti = find(strcmp(csvTable.folder, done_folders{end}));
    backup(const.classedfile);
    % a stands for append
    classedfID = fopen(const.classedfile, 'a');
    fprintf('\nAppending to %s...\nSkipping images up to (%s, %s)...\n', ...
        const.classedfile, done_folders{end}, done_names{end});
    r = r+1;
else
    % create new file
    fprintf('Savefile: %s\n', const.classedfile);
    classedfID = fopen(const.classedfile, 'w');
    % add classed_header row
    fprintf(classedfID, strjoin(classed_header, ','));
    % starting fresh! start at lastj = 2 because dir  has . and .. as elements
    lasti = 1; lastj = 2; r = 1;
end
if exist(const.processedfile, 'file')
    fprintf('Appending to file: %s\n', const.processedfile);
    backup(const.processedfile);
    % read csv files and find last
    processedTable = readtable(const.processedfile, ...
        'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
    % find last row in classedTable with non-empty outcomes/center
    lr = find(~(cellfun(@isempty, classedTable.outcomes) & arrayfun(@isempty, classedTable.center)), 1, 'last');
    assert(lr == processedTable.r(end), 'classed_raw and classed_processed should be at the same stage.');
    % a stands for append
    processedfID = fopen(const.processedfile, 'a');
    fprintf('Skipping images up to row %d...\n', r);
else
    if exist(const.classedfile, 'file'), process_classed(); end
    processedfID = fopen(const.processedfile, 'a');
    fprintf(processedfID, strjoin(processed_header, ','));
end

% initialize figure and callback functions
h = figure(1); set(h, 'Position', [0 0 1000 650])
% intiialize variables
metadata_array = cell(0); folder_name = ''; file_name = '';
% set(h, 'KeyPressFcn', {@imkey, const.classedfile});
% set(h, 'WindowScrollWheelFcn', @imscroll)

%% Iterate through CZI files
% generate list of czi files from folders
n_folders = height(csvTable);
for i = lasti:n_folders
    % folder access and channel info
    f = fullfile(const.czidir, csvTable.folder{i});
    f_contents = dir(f);
    % iterate over folder contents (each "content" is a czi file)
    ncontents = length(f_contents);
    [nch, chL, chM, chMG] = get_folder_ch(csvTable.folder{i}, csvTable);
    done_folder_names = done_names(strcmp(done_folders, csvTable.folder{i}));
    if length(done_folder_names) == ncontents, continue; end
    for j = 1:ncontents
        content = f_contents(j);
        [~, ~, ext] = fileparts(content.name);
        if (content.isdir || ~strcmp(ext, '.czi') || ...
                ismember(content.name, done_folder_names))
            % skip this one
            continue
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
        %% convert all to RGB first
        % find size of image
        siz = size(picdata{1, 1});
        rgbdata = zeros([nz, siz, 3]);
        % random number to swap L/M pixels (for better blinding)
        swapRG = mod(floor(10*rand()), 2) == 0;
        if swapRG
            chG = chM; chR = chL;
        else
            chG = chL; chR = chM;
        end
        for z = 1:nz
            % rgb is a [siz x 3] matrix 
            rgb = pic2rgb(picdata, z, nch, chG, chR);
            rgbdata(z, :, :, :) = rgb;
        end
        
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
        % set up user input dialog window
        options.WindowStyle = 'normal';
        if nz == 1
            prompt = {'Outcome [c m s i < >] Lumen (blank/l):'};
            default = {''};
            answer = inputdlg(prompt, 'Classification', 1, default, options);
            centers_sc = '1';
        else
            prompt = {'Outcome [c m s i < >] Lumen (blank/l) Center:'};
            default = {''};
            answer = inputdlg(prompt, 'Classification', 1, default, options);
        end
        % if user pushes Cancel button
        if isempty(answer)
            fclose all; close all;
            fprintf('\nProcessing canceled.\n');
            fprintf('Ended before (%s, %s)\n', ...
                csvTable.folder{i}, content.name);
            return
        end
        
        %% Record user answer
        if ~isempty(answer{1})
            % go get them
            [outs, lums, centers, n_outs, n_centers] = extract_olc(answer{1});
            if nz > 1
                if ~(all(cellfun(@(x) (isempty(x) || (str2double(x) <= nz)), centers)))
                    fclose all; close all;
                    fprintf('Center value not in z-stack.\n');
                    fprintf('Ended before (%s, %s)\n', ...
                        csvTable.folder{i}, content.name);
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
        % add data to const.classedfile preceded by newline
        fprintf(classedfID, ['\n', const.classed_format], ...
            r, csvTable.folder{i}, content.name, ...
            outs_sc, lums_sc, centers_sc, csvTable.imgtype{i});
        
        %% process file and folder names for metadata
        if (n_outs == 0) && (n_centers == 0)
            fprintf('\rno assignments');
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
                brightness = 'new';
                if (contains(csvTable.imgtype{i}, 'FP')), brightness = fluor_brightness(file_name); end
                sbgdir = fullfile('SBG', csvTable.imgtype{i}, brightness);
                metadata_array = extract_metadata(folder_name, file_name, csvTable, consts);
            end

            %% print into processed file
            n_rows = length(outs);
            for i_row=1:n_rows
                out = outs{i_row}; lum = lums{i_row}; cen = centers{i_row};
                % r, folder, name, imgtype, outcome, lumen, metadata
                fprintf(processedfID, ['\n', const.processed_format], ...
                    r, csvTable.folder{i}, sbgdir, content.name, csvTable.imgtype{i}, ...
                    out, lum, cen, metadata_array{:});
            end
        end
        fprintf('\r%d: %d of %d files', i-2, j-2, ncontents);
        r = r + 1;
        % now move to next file
    end
    % now move to next folder
    lastj = 2;
end
fclose all; close all; fprintf('\nDone!\n');
