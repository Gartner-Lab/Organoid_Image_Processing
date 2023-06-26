% 7 Dec 2017
% Jennifer Hu
% 
% Reads classed.csv. Compares to i and j of folders listed in csvTable.
% If (i,j) is not in csv, display image and collect info; append to csv.
%
% Loads czi files (z-stacks) and displays them in Gallery view. User
% records organization outcomes with letters, lumenization,
% number of slice corresponding to center.
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
[const, consts] = constants();
classed_header = consts{strcmp(consts{1}, "classed_header")};
processed_header = consts{strcmp(consts{1}, "processed_header")};
csvTable = dir_csv_reader(const.csvfile);

%% File I/O
if exist(const.classedfile, 'file')
    c = input('Do you want to append or cancel? (a/): ','s');
    switch c
        case 'a'
            % read csv files
            classedTable = readtable(const.classedfile, 'Delimiter', ',', 'ReadVariableNames', true);
            r = max(classedTable.r)+1;
            % make a backup
            backup(const.classedfile); classedfID = fopen(const.classedfile, 'a');
            % read csv files and find last
            processedTable = readtable(const.processedfile, ...
                'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
            % find last row in classedTable with non-empty outcomes
            lr = find(~(cellfun(@isempty, classedTable.outcomes) & arrayfun(@isempty, classedTable.center)), 1, 'last');
            assert(lr == processedTable.r(end), ...
                'classed_raw and classed_processed should be at the same stage.');
            backup(const.processedfile); processedfID = fopen(const.processedfile, 'a');
        otherwise % cancel
            return
    end
else
    classify_outcomes(); % no classified file; make one here
    return
end
% start at lastj = 2 because dir  has . and .. as elements
lastj = 2;
%% read csv files
done_folders = classedTable.folder;
done_names = classedTable.name;
% initialize figure and callback functions
h = figure(1); set(h, 'Position', [50 50 1100 900])
set(h,'WindowScrollWheelFcn', @imscroll)

%% Iterate through CZI files
n_folders = height(csvTable);
for i=flip(1:n_folders) % start from the end
    %% folder access and channel info
    f = fullfile(const.czidir, csvTable.folder{i});
    f_contents = dir(f);
    [nch, chL, chM, chMG] = get_folder_ch(csvTable.folder{i}, csvTable);
    %% iterate over folder contents (each "content" is a czi file)
    ncontents = length(f_contents);
    if lastj >= ncontents
        % last file in this folder was already done
        lastj = 2;
        continue
    end
    % all the files that have been done already in this folder
    done_names_folder = done_names(strcmp(classedTable.folder, csvTable.folder{i}));
    for j=(lastj+1):ncontents
        % if this name is in the list, skip
        if ismember(f_contents(j).name, done_names_folder), continue; end
        content = f_contents(j);
        [~,~,ext] = fileparts(content.name);
        if (content.isdir || ~strcmp(ext, '.czi'))
            % skip this one
            continue
        end        
        % check if problem file
        if (contains(f, '2017-01-14 240L 353P') && ...
            (contains(content.name, '26h') || contains(content.name, '240L 48h') || contains(content.name, '240L 100M 48h')))
            chM = 1; chL = 3; chMG = 2;
        end
        %% Open image with BioFormats
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
            fprintf('Processing canceled.\n');
            fprintf('Ended before (%s, %d/%d)\n', ...
                csvTable.folder{i}, j-2, ncontents-2);
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
                    fprintf('Ended before (%s, %d/%d)\n', ...
                        csvTable.folder{i}, j-2, ncontents-2);
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
            if (n_outs == n_centers) % outcomes/lumens/centers match in number
                for i_out=1:n_outs
                    out = outs{i_out}; lum = lums{i_out}; cen = centers{i_out};
                    % r, folder, name, imgtype, outcome, lumen, metadata
                    fprintf(processedfID, ['\n', const.processed_format], ...
                        r, csvTable.folder{i}, content.name, csvTable.imgtype{i}, ...
                        out, lum, cen, metadata_array{:});
                    % construct image name from original_r#_s#.png
                    slice_path = fullfile(const.slicedir, 'raw', ...
                                            sprintf('%s_r%d_s%s.png', file_name, r, cen));
                    % save slice
                    if ~(exist(slice_path, 'file'))
                        if isempty(chMG)
                            rgb = pic2rgb(bfdata{1, 1}, cen, nch, chL, chM);
                        else
                            rgb = pic2rgb(bfdata{1, 1}, cen, nch, chL, chM, chMG);
                        end
                        imwrite(rgb, slice_path);
                    end
                    
                end
            else % # of centers != # outcomes/lumens
                % print outs and lums together
                if n_outs > 0
                    for i_out=1:n_outs
                        out = outs{i_out}; lum = lums{i_out};
                        fprintf(processedfID, ['\n', const.processed_format], ...
                            r, csvTable.folder{i}, content.name, csvTable.imgtype{i}, ...
                            out, lum, '', metadata_array{:});
                    end
                end
                % print centers by themselves
                if n_centers > 0
                    for i_out=1:n_centers
                        cen = centers{i_out};
                        fprintf(processedfID, ['\n', const.processed_format], ...
                            r, i, j, csvTable.folder{i}, content.name, csvTable.imgtype{i}, ...
                            '', '', cen, metadata_array{:});
                        % construct image name from original_r#_s#.png
                        slice_path = fullfile(const.slicedir, 'raw', ...
                                                sprintf('%s_r%d_s%s.png', file_name, r, cen));
                        % save slice
                        if ~(exist(slice_path, 'file'))
                            if isempty(chMG)
                                rgb = pic2rgb(bfdata{1, 1}, cen, nch, chL, chM);
                            else
                                rgb = pic2rgb(bfdata{1, 1}, cen, nch, chL, chM, chMG);
                            end
                            imwrite(rgb, slice_path);
                        end
                    end
                end
            end
        end
        % update row number and continue to next image
        r = r + 1; fprintf('%s: %d/%d\n', folder_name, j-2, ncontents-2);
    end
    % now move to next folder
    lastj = 2;
end
fclose all; close all; beep; fprintf('... Done! Now run slice_imgs.m\n')