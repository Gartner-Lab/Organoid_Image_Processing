% 9 December 2017
% Jennifer Hu
%
% Reads classed_processed.csv. Opens original image files and extracts
% slices of centers, saved as RGB. If MG channel is present, save as B
% channel. Save slice info in const.slicedatafile and const.sliceadjfile.
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
if (~exist('const', 'var'))
    [const, consts] = constants();
end
% set = 1 if you want to save the const.slicedatafile
saveslices = 1;
% new folders to overwrite
overwritefolders = {};
csvTable = readtable(const.csvfile,'Delimiter',',');

%% Use processed csv as source of information.
processedTable = readtable(const.processedfile, ...
    'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
% restrict to rows with center slice specified
use_rows = ~arrayfun(@isnan, processedTable.center);
sliceTable = processedTable(use_rows, :);
adjTable = [sliceTable; sliceTable];
n = size(sliceTable, 1);

%% Save (imwrite) slice files to name_r#_s#.png
bfdata = 0; prev_czifile = ''; nch = 0; nz = 0;
fprintf('Starting to check %d images to slice', n);
for t_row = 1:n
    if mod(t_row, n/20) == 0, fprintf('.'); end
    czifile = sliceTable.name{t_row};
    folder = sliceTable.folder{t_row};
    filepath = fullfile(const.czidir, folder, czifile);
    % get center slice #
    center = sliceTable.center(t_row);
    % construct image name from original_r#_s#.png
    [~, name, ~] = fileparts(czifile);
    center_name = sprintf('%s_r%d_s%d.png', name, sliceTable.r(t_row), center);
    slice_names = {strrep(center_name, '.png', '(-1).png'), center_name, ...
                    strrep(center_name, '.png', '(+1).png')};
    
    % check if problem file
    if contains(folder, '2019-09-10/7d K19')
        continue
    end
    if ~isfile(filepath)
        fprintf('\nFile %d of %d: %s... missing %s\n', t_row, n, center_name, filepath);
        return
    end
    
    % put name of image in table
    sliceTable.imdir{t_row} = fullfile('raw', sliceTable.imgtype{t_row});
    sliceTable.imfilename{t_row} = center_name;
    adjTable.imdir{t_row} = fullfile('raw', sliceTable.imgtype{t_row});
    adjTable.imfilename{t_row} = slice_names{1};
    adjTable.imdir{t_row+n} = fullfile('raw', sliceTable.imgtype{t_row});
    adjTable.imfilename{t_row+n} = slice_names{3};
    
    % look for existing files
    if sum(isfile([fullfile(const.rawslicedir, sliceTable.imgtype{t_row},'new',slice_names), ...
        fullfile(const.rawslicedir, sliceTable.imgtype{t_row}, 'done', slice_names)])) == 3
        continue; % skip image that already exists
    end
    
    %% Get image from czi file
    [~, chL, chM, chMG] = get_folder_ch(folder, csvTable);
    if chL == 0 || chM == 0
        continue; % can't find folder in csv table
    end
    zs = [center-1, center, center+1];
    % open image if it's different from last
    if ~strcmp(prev_czifile, czifile)
        % open czi file
        [T, bfdata] = evalc('bfopen(filepath)');
        % get number of channels from bfdata{1, 1}{1, 2}
        bfinfo = strsplit(bfdata{1, 1}{1, 2}, 'C=1/');
        nch = str2double(bfinfo{2});
        nz = length(bfdata{1, 1})/nch;
        prev_czifile = czifile;
    end    
    for i = 1:3
        z = zs(i);
        if z == 0 || z > nz % skip out of range slice
            % remove from table
            adjTable.imdir{t_row+n} = '';
            adjTable.imfilename{t_row+n} = '';
            continue; 
        end
        slice_name = slice_names{i};
        slice_path = fullfile(const.rawslicedir, sliceTable.imgtype{t_row}, 'new', slice_name);
        if any(isfile({slice_path, ...
            fullfile(const.rawslicedir, sliceTable.imgtype{t_row}, 'done', slice_name)}))
            continue; % skip image that already exists
        end
        % get RGB matrix
        if isempty(chMG)
            rgb = pic2rgb(bfdata{1, 1}, z, nch, chL, chM);
        else
            rgb = pic2rgb(bfdata{1, 1}, z, nch, chL, chM, chMG);
            % save one slice in the chMG folder
            imwrite(rgb, strrep(slice_path, sliceTable.imgtype{t_row}, 'chMG'));
            % remove the blue channel to save normally
            rgb(:,:,3) = 0;
        end
        % write RGB images to file
        fprintf('\n%d/%d: %s', t_row, n, fullfile(sliceTable.imgtype{t_row}, 'new', slice_name));
        imwrite(rgb, slice_path);
    end
end
if saveslices
    % write sliceTable to csv file
    backup(const.slicedatafile); backup(const.sliceadjfile);
    writetable(sliceTable, const.slicedatafile, 'Delimiter', ',');
    writetable(adjTable, const.sliceadjfile, 'Delimiter', ',');
    fprintf('\nSlice data saved:\n-%s\n-%s\n', const.slicedatafile, const.sliceadjfile);
end
fprintf('Run Ilastik/clean_slices.ijm and Annotation/px_sizes.ijm in FIJI next.\n');