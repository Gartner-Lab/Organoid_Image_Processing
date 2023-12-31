% 2019 November 11
% Jennifer Hu
% Process segmentations generated by ML pipeline. Fill in holes and
% concavities in organoid boundary, remove small regions, etc. Quantifies
% the results using quantify_img and saves in a csv file. Generates before
% and after images of processing.
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%% Set up (can skip if already run and no changes needed)
% Change this if you need
reuse_cleaned = false; % set false if you want to make new cleaned mask
% if you want to re-quantify these cleaned masks
% renew_between = [datetime(2021,4,8), datetime(2021,04,9,12,0,0)];

[const, consts] = constants();
ilastikdir = fullfile(const.slicedir, 'masks');
segdir = fullfile(ilastikdir, 'Simple');
fprintf('Reading data from %s...\n', const.slicedatafile);
sliceTable = readtable(const.slicedatafile, 'Delimiter', ',', ...
    'ReadVariableNames', true, 'EmptyValue', 0, 'HeaderLines', 0, ...
    'Format', '%d%s%s%s%s%d%d%s%d%d%f%f%f%s%s%s%s%s%s%s%s%d%d%s%s%s%d%d');
metrics = consts{strcmp(consts{1}, 'metrics')};

%% initialize file with header
appendmode = false;
if (exist(const.quantadjfile, 'file'))
    c = input('Do you want to:\n- (a)ppend, (usually the right option) \n,- (o)verwrite entirely,\n- overwrite (j)ust new segmentations, or\n- cancel?\n(o/j/a/): ', 's');
    switch c
        case 'o'
            newTable = sliceTable;
        case 'j'
            adjTable = readtable(const.quantadjfile, ...
                'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
            metric_cols = (width(adjTable)-const.n_metrics+2):width(adjTable);
            % keep all the rows, we won't re-quantify the ones with Cleaned
            newTable = sliceTable;
            appendmode = false;
        case 'a'
            adjTable = readtable(const.quantadjfile, ...
                'Delimiter', ',', 'ReadVariableNames', true, 'HeaderLines', 0);
            % remove rows that have been completely quantified
            newTable = sliceTable( ...
                ~ismember([sliceTable.center, sliceTable.r, sliceTable.adj], ...
                [adjTable.center, adjTable.r, adjTable.adj], 'rows'),:);
            appendmode = true;
        otherwise % cancel
            fprintf('... Canceled.\n')
            return
    end
end
n_slices = height(newTable);

%% start the timer
tic
close all; h = figure('Position', [100 100 800 300]);
edge_LEP_metric_idx = strcmp(metrics, 'Edge_LEP_Fraction');
metricsmatrix = NaN(n_slices, const.n_metrics-1);
done_rows = zeros(n_slices,1);


for i=1:n_slices
    % print the current file and timer
    imname = newTable.imfilename{i};
    
    %% Open and clean images
    file_cleaned = fullfile(ilastikdir, 'Cleaned', [imname,'.png']);
    file_segmentation = fullfile(segdir, [imname,'.tiff']);
    if ~isfile(file_segmentation)
        continue % hasn't gone through ilastik yet
    end
    if c == 'j' && isfile(file_cleaned)
        maskdate = datetime(dir(file_cleaned).date);
        if maskdate < renew_between(1) || maskdate > renew_between(2)
            % read in the values of adjTable for this image
            j = find(strcmp(adjTable.imfilename, imname));
            if ~isempty(j)
                assert(length(j) == 1);
                % Add to newTable and metricsmatrix
                newTable.Bounding_Box{i} = adjTable.Bounding_Box{j};
                metricsmatrix(i,:) = adjTable{j,metric_cols};
                done_rows(i) = 1;
                continue
            end
        end
    end
    
    fprintf('\n%s - %s (%d/%d)', tocstring(), imname, i, n_slices);
    img_segmentation = ilastik2dmask(imread(file_segmentation), const);
    if (reuse_cleaned && isfile(file_cleaned))
        cleaned_segmentation = imread(file_cleaned);
%         assert(all(cleaned_segmentation == const.pxtype_dmask.E | ...
%             cleaned_segmentation == const.pxtype_dmask.L | ...
%             cleaned_segmentation == const.pxtype_dmask.M, 'all'), ...
%             'Should have values matching dmask.');
    else
        % Clean the Ilastik output
        cleaned_segmentation = clean_segmentation(img_segmentation, const);
        imwrite(cleaned_segmentation+1, const.cmap_dmask, file_cleaned, 'png');
        fprintf(' ');
    end
    
    %% Quantify
    % generate metrics for this image
    quantification = quantify_dmask(cleaned_segmentation, const);
    bbox = regexprep(num2str(quantification.bounds),'\s*','-');
    % Add to newTable and metricsmatrix
    newTable.Bounding_Box{i} = bbox;
    metricsmatrix(i,:) = quantification.metric_row;
    done_rows(i) = 1;

    %% show before and after figure in the Results folder
    file_cleaning = fullfile(const.datadir, 'Results', 'SegmentationProcess', [imname,'.png']);
    if ~isfile(file_cleaning) || ~reuse_cleaned
        h; 
        % find the matching slice
        file_slice = fullfile(const.slicedir, 'SBG', newTable.imgtype{i}, 'done', [imname,'.png']);
        if ~isfile(file_slice)
            file_slice = fullfile(const.slicedir, 'raw', newTable.imgtype{i}, 'done', [imname,'.png']);
        end
        if isfile(file_slice)
            subplot(1,3,1); imshow(file_slice); title('Original');
        end
        subplot(1,3,2); imshow(img_segmentation+1, const.cmap_dmask); title('Segmentation');
        subplot(1,3,3); imshow(cleaned_segmentation+1, const.cmap_dmask); title('Processed');
        figtitle(sprintf('%s - EdgeLEP = %g', strrep(imname,'_','\_'), ...
            quantification.metric_row(edge_LEP_metric_idx)));
        saveas(h, file_cleaning);
    end
    if mod(i, round(n_slices/10)) == 0 || i == n_slices
        fprintf('\n');
    end
end

%% cut off NaN parts of matrices
% Save tables
% exclude bounding box because I already added it
metricsTable = array2table(metricsmatrix, 'VariableNames', metrics(1:(end-1)));
newTable = horzcat(newTable, metricsTable);
% skip the skipped rows
newTable = newTable(done_rows == 1,:);

% make a backup
backup(const.quantadjfile);
if appendmode
    writetable(newTable, const.quantadjfile, 'WriteMode', 'Append',...
        'WriteVariableNames', false);
else
    writetable(newTable, const.quantadjfile);
end
fprintf('\n\nCompleted after %s.\n\n', tocstring());
close all;