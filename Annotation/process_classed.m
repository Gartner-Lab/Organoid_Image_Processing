% 9 Dec 2017
% Jennifer Hu
%
% Goes through classed.csv and pulls up folder/file name.
% Extracts information on independent variables from names:
% timept, strain(s), drug, virus, confluence, embed density, ECM.
% Assigns strain info from strainfile.
% If next filename is the same except the number, reuse selections.
% Splits lines with multiple annotations into separate lines.
% Saves new csv in const.processedfile.
%
% Before running this, ensure that any new dates, timepoints, strains, 
% viruses, (etc.) are listed in constants.m.
%
% Format of classed.csv = i, j, folder, name, outcomes, lumens, center
% Format of classed_processed.csv =
% 	r, folder, name, outcome, lumen, center, chL, chM, date, timepoint, strain, 
%	confluence, ECM, drug, virus, FDG
%
% confluence [-1, 0, 1] = under, confluent, over
% MG_density [0, 1] = low, high/normal
% FDG ['', 'l', 'h'] = none, FDG-low, FDG-high
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%% set up constants
[const, consts] = constants();
processed_header = consts{strcmp(consts{1}, "processed_header")};
csvTable = readtable(const.csvfile,'Delimiter',',');

% r, folder, name, imgtype, outcome, lumen, center, chL, chM, date, 
% timepoint, strain, strainM, strainL, confluence, ECM, drug, virus, FDG, CD10


%% check for previous const.processedfile
if exist(const.processedfile, 'file')
    c = input('Do you want to overwrite, append, or cancel? (o/a/): ', 's');
    switch c
        case 'o'
            % make a backup
            backup(const.processedfile);
            processedfID = fopen(const.processedfile, 'w');
            fprintf(processedfID, strjoin(processed_header,','));
            fprintf('\nOverwriting...\n');
            last_r = 0;
        case 'a'
            fprintf('Appending to file: %s\n', const.processedfile);
            % read csv files and find last
            saveTable = readtable(const.processedfile, 'Delimiter', ',', 'ReadVariableNames', true);
            last_r = saveTable.r(end);
            backup(const.processedfile);
            % a stands for append
            processedfID = fopen(const.processedfile, 'a');
            fprintf('Skipping images up to row %d...\n', ...
                const.processedfile, last_r);
        otherwise % cancel
            fprintf('... Canceled.\n')
            return
    end
else
    processedfID = fopen(const.processedfile, 'w');
    fprintf(processedfID, processed_header);
    % start fresh
    last_r = 0;
end

%% Import metadata.
% read classed.csv into table. Ensure lumens is read as string.
classedTable = readtable(const.classedfile, 'Delimiter', ',', ...
    'ReadVariableNames', true, 'headerLines', 0); % i, j, folder, name, outcomes, lumens, center, imgtype
n = size(classedTable, 1); step = n/20;

folder_name = ''; file_name = '';
%% iterate through rows of classedTable
for r=(last_r+1):n
    %% First look for outcomes and center assignments
    % cell arrays (outs, lums, centers) containing matched strings
    outs = convert_olc(classedTable.outcomes{r},'o'); n_outs = length(outs);
    lums = convert_olc(classedTable.lumens{r},'l');
    if isempty(lums) || length(lums) ~= n_outs
        lums = repmat({'0'},1,n_outs);
    end
    centers = convert_olc(string(classedTable.center(r)),'c'); n_centers = length(centers);
    if (n_outs == 0) && (n_centers == 0)
        continue
    end
    if mod(r, step) == 0, fprintf('.'); end % progress bar

    %% check if this row is going to be the same as the last
    % compare to previous file name
    [~, new_name, ~] = fileparts(classedTable.name{r});
    [~, old_name, ~] = fileparts(file_name);
    % reassign file name
    file_name = classedTable.name{r};
    % not counting the suffix, these names are the same and are in same folder
    if strcmp(folder_name, classedTable.folder{r}) && ...
        (strcmp(new_name(1:end-3), old_name(1:end-3)) ...
        || strcmp(new_name(1:end-3), old_name) ...
        || (strcmp(new_name, old_name(1:end-3))))
        % don't change the metadata
    else
        folder_name = classedTable.folder{r};
        metadata_array = extract_metadata(folder_name, file_name, csvTable, consts);
        %% find subdirectory for slices
        brightness = 'new';
        if (contains(classedTable.imgtype{r}, 'FP')), brightness = fluor_brightness(file_name); end
        sbgdir = fullfile('SBG', classedTable.imgtype{r}, brightness);
    end
    
    %% print into file
    if (n_outs == n_centers) % outcomes/lumens/centers match in number
        for i=1:n_outs
            out = outs{i}; lum = lums{i}; cen = centers{i};
            % r, folder, name, imgtype, outcome, lumen, metadata
            fprintf(processedfID, ['\n',const.processed_format], ...
                r, folder_name, sbgdir, file_name, classedTable.imgtype{r}, ...
                out, lum, cen, metadata_array{:});
        end
    else % # of centers != # outcomes/lumens
        % print outs and lums together
        if n_outs > 0
            for i=1:n_outs
                out = outs{i}; lum = lums{i};
                % r, folder, name, imgtype, outcome, lumen, metadata
                fprintf(processedfID, ['\n',const.processed_format], ...
                    r, folder_name, '', file_name, classedTable.imgtype{r}, ...
                    out, lum, '', metadata_array{:});
            end
        end
        % print centers by themselves
        if n_centers > 0
            for i=1:n_centers
                cen = centers{i};
                % r, folder, name, imgtype, outcome, lumen, metadata
                fprintf(processedfID, ['\n', const.processed_format], ...
                    r, folder_name, sbgdir, file_name, classedTable.imgtype{r}, ...
                    '', '', cen, metadata_array{:});
            end
        end
    end
end
fclose all;
fprintf('\nProcessing complete. Error checking recommended.\n')