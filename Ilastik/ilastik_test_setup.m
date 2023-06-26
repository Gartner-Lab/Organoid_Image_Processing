% Set up for Ilastik workflow by looking in slicedatafile and drawing equally from most categories
rng(0);
[const, consts] = constants(); csvTable = dir_csv_reader(const.csvfile);
bad_dates = {'2018-07-10', '2019-09-11'};

% Use slice csv as source of information.
sliceTable = readtable(const.slicedatafile, 'Delimiter', ',', ...
    'ReadVariableNames', true, 'HeaderLines', 0, ...
    'Format', '%d%d%d%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s');

% Groups to divide data ----------------------------------------------------------------------
% Image types (LSM_FP, FP) - ignore CT for now
imgtypes = {'LSM_FP', 'FP'};
% Transgene: PIK3CA/H1047R usually dim... let's try keeping them together for now
dim = {'PIK3CA','E545K','H1047R','ERBB2','B1V737N'};
% Groups to sample somewhat evenly -----------------------------------------------------------
groups = {{'c'}, {'>s','s'}, {'>m','m'}, {'i','<s','<m'}};

% Fill in about 20 images per group -----------------------------------------------------------------
n_imgs = 20;
assert(exist(fullfile(const.slicedir, 'Ilastik', 'Training Data', imgtypes{1}, 'bright'), 'dir') > 0);

indices = ones(height(sliceTable),1);
for i = 1:length(indices)
    [~, ~, ~, chMG] = get_folder_ch(sliceTable.folder{i}, csvTable);
    % exclude images with Matrigel channel
    indices(i) = isempty(chMG) &&...
        ~any(strcmp(bad_dates, sliceTable.date{i})) && ...
        datetime(sliceTable.date{i}, 'InputFormat', 'yyyy-MM-dd') ...
        > datetime(2016, 12, 31);
end

%% Generate a training data set and a test dataset
traindir = fullfile(const.slicedir, 'Ilastik', 'Training Data');
testdir = fullfile(const.slicedir, 'Ilastik', 'Test Data');
assert(exist(testdir, 'dir') > 0);
for h = 1:2
    for i = 1:length(imgtypes)
        imgtype = imgtypes{i};
        fprintf('%s ------------------------------------\n', imgtype);
        assert(exist(traindir, 'dir') > 0);
        indices_imgtype = indices & strcmp(sliceTable.imgtype, imgtype);
        for j = 1:length(groups)
            for k = 1:2
                if (k == 1)
                    brightness = 'dim';
                    indices_group = indices_imgtype & ...
                        cellfun(@(v) any(contains(v, dim)), sliceTable.virus) & ...
                        cellfun(@(o) any(strcmp(groups{j}, o)), sliceTable.outcome);
                else
                    brightness = 'bright';
                    indices_group = indices_imgtype & ...
                        cellfun(@(v) ~any(contains(v, dim)), sliceTable.virus) & ...
                        cellfun(@(o) any(strcmp(groups{j}, o)), sliceTable.outcome);
                end
                % convert binary vector to numeric indices
                include = find(indices_group);
                % draw from numeric indices randomly
                if (length(include) > n_imgs)
                    include = datasample(include, n_imgs, 'Replace', false);
                end
                n_include = length(include);
                for l = 1:n_include
                    idx = include(l);
                    slicename = sliceTable.imfilename{idx};
                    slicefile = fullfile(const.rawslicedir, imgtype, slicename);
                    trainfile = fullfile(traindir, imgtype, brightness, slicename);
                    if h == 1
                        fprintf('  %d: %s\n', idx, slicename);
                        % copy file from rawslicedir to Ilastik training dir
                        copyfile(slicefile, trainfile);
                    else
                        if exist(trainfile, 'file')
                            fprintf('  %d: %s already used in training data\n', idx, slicename);
                            continue
                        else
                            testfile = fullfile(testdir, imgtype, brightness, slicename);
                            fprintf('  %d: %s\n', idx, slicename);
                            % copy file from rawslicedir to Ilastik training dir
                            copyfile(slicefile, testfile);
                        end
                    end
                end
            end
        end
    end
end