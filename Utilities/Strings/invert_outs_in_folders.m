% % 27 September 2019
% Jennifer Hu
%
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
[const, consts] = constants();
classed_header = consts{strcmp(consts{1}, "classed_header")};
processed_header = consts{strcmp(consts{1}, "processed_header")};

folders_to_invert = {'2018-02-24 240L 353P test\agarose 240L'};

%% File I/O
% make a backup
[~, name, ext] = fileparts(const.classedfile);
copyfile(const.classedfile, sprintf('%s/%s%s', const.backupdir, name, ext));
% make a backup
[~, name, ext] = fileparts(const.processedfile);
copyfile(const.processedfile, sprintf('%s/%s%s', const.backupdir, name, ext));

classedTable = readtable(const.classedfile, 'Delimiter', ',', ...
    'ReadVariableNames', true, 'headerLines', 0);
n = size(classedTable, 1);

folder_name = ''; file_name = '';
%% iterate through rows of classedTable
for i=1:n
    if ~any(strcmp(folders_to_invert, classedTable.folder{i}))
        continue
    end
    % invert outcome
    fprintf('%d ', i);
    classedTable.outcomes{i} = invert_outs(classedTable.outcomes{i}); 
end

%% Iterate through processed table
processedTable = readtable(const.processedfile, 'Delimiter', ',', ...
    'ReadVariableNames', true, 'headerLines', 0);
n = size(processedTable, 1);
for i = 1:n
    if ~any(strcmp(folders_to_invert, processedTable.folder{i}))
        continue
    end
    % invert outcome
    processedTable.outcome{i} = invert_outs(processedTable.outcome{i});
    
    %% folder access and channel info
    f = fullfile(const.czidir, processedTable.folder{i});
    [nch, chL, chM, chMG] = get_folder_ch(processedTable.folder{i}, const.csvTable);
    
    % evaluate with evalc to stuff bfopen warnings into T
    [T, bfdata] = evalc('bfopen(fullfile(f, processedTable.name{i}))');
    picdata = bfdata{1, 1};
    nz = length(picdata)/nch;
    siz = size(picdata{1, 1});
    
    % save slice
    if ~isnan(processedTable.center(i))
        slice_path = fullfile(const.slicedir, 'raw', ...
                        sprintf('%s_r%d_s%d.png', processedTable.name{i}, ...
                        processedTable.r(i), processedTable.center(i)));
        if isempty(chMG)
            rgb = pic2rgb(bfdata{1, 1}, processedTable.center(i), nch, chL, chM);
        else
            rgb = pic2rgb(bfdata{1, 1}, processedTable.center(i), nch, chL, chM, chMG);
        end
        imwrite(rgb, slice_path); % this overwrites whatever was there before
    end
end

%% save the updated tables
writetable(classedTable, const.classedfile, 'Delimiter', ',');
writetable(processedTable, const.processedfile, 'Delimiter', ',');
fprintf('\nAll set. Check for any typos.\n')