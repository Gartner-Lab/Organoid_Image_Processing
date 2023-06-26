function [centersTable] = imsequence_centers(ilastikdir, const)

tic
probdir = fullfile(ilastikdir, 'Probabilities');
ilastikdatadir = fullfile(ilastikdir, 'Data');
maskdir = fullfile(ilastikdir,'Masks');
centersdir = fullfile(ilastikdir,'Centers');
allslicefile = fullfile(ilastikdatadir, 'slicedata_all.csv');
files_done = {};
imgs = dir(probdir); n_imgs = length(imgs);
slicesTable = table('Size', [n_imgs-2, 5], ...
    'VariableTypes', {'string','string','uint8','uint8','double'}, ...
    'VariableNames', {'filename','fileframe','frame','z','area'});
sliceformat = '%s,%s,%d,%d,%f\n'; 
sliceheader = 'filename,fileframe,frame,z,area\n';
if exist(allslicefile, 'file')
    slices_done = readtable(allslicefile);
    files_done = slices_done.filename;
    backup(allslicefile); fID = fopen(allslicefile, 'a');
else
    fID = fopen(allslicefile, 'w'); 
    fprintf(fID, sliceheader);
end
for j=3:n_imgs
    filename = imgs(j).name; i = j-2;
    if (startsWith(filename, '.'))
        continue
    end
    [~, imgname, ext] = fileparts(filename);
    imname = strrep(imgname, '.tif', '');
    if ~strcmp(imgname, imname)
        movefile(fullfile(probdir, filename), fullfile(probdir, [imname, ext]));
        filename = [imname, ext];
    end
    if ismember(filename, files_done)
        k = find(strcmp(slices_done.filename, filename));
        slicesTable.filename(i) = filename;
        slicesTable.fileframe(i) = string(extractBefore(filename, '_z'));
        slicesTable.frame(i) = slices_done.frame(k); 
        slicesTable.z(i) = slices_done.z(k);        
        slicesTable.area(i) = slices_done.area(k);
        continue
    end
    fprintf('%s: ',imname);
    % open image
    file_cleaned = fullfile(maskdir,sprintf('%s.png', imname));
    if exist(file_cleaned, 'file')
        cleaned_segmentation = imread(file_cleaned);
        A = sum(cleaned_segmentation ~= const.pxtype_dmask.E, 'all');
    else
        img_segmentation = open_ilastik_p(fullfile(probdir, filename), const);
        cells = (img_segmentation ~= const.pxtype_dmask.E);
        if ~any(cells, 'all')
            A = 0;
        else
            % cast to uint8 to make discontinuous work
            stats = regionprops(uint8(cells), {'Solidity','ConvexArea'});
            if stats.Solidity > 0.8
                fprintf('using convex area');
                A = stats.ConvexArea;
            else
                fprintf('cleaning')
                cleaned_segmentation = clean_segmentation(img_segmentation, const);
                A = sum(cleaned_segmentation ~= const.pxtype_dmask.E, 'all');
                fprintf(' done')
                imwrite(cleaned_segmentation+1, const.cmap_dmask, file_cleaned);
            end
        end
    end
    % fill in information in centersTable
    slicedata = extractAfter(imname, '_t'); slicedata = sscanf(slicedata, '%d_z%d');
    slicesTable.filename(i) = string(filename);
    slicesTable.fileframe(i) = string(extractBefore(imname, '_z'));
    slicesTable.frame(i) = slicedata(1); 
    slicesTable.z(i) = slicedata(2);
    slicesTable.area(i) = A;
    
    fprintf(fID, sliceformat, filename, extractBefore(imname, '_z'), ...
        slicedata(1), slicedata(2), A);
    fprintf('... %s\n',tocstring())
end
fclose(fID);
fprintf('all slices checked.\n')

%% now iterate through each timepoint to find biggest z
centersTable = unique(slicesTable(:,{'filename','fileframe','frame'}));
n_centers = height(centersTable);
files_done = {}; 
centersfile = fullfile(ilastikdatadir, 'slicedata_centers.csv');
if exist(centersfile, 'file')
    centers_done = readtable(centersfile);
    files_done = centers_done.fileframe;
    backup(centersfile); fID = fopen(centersfile, 'a');
else
    fID = fopen(centersfile, 'w'); 
    fprintf(fID, 'filename,fileframe,frame,z\n');
end
%%
for i = 1:n_centers
    fileframe = centersTable.fileframe(i); fprintf('\n%s',fileframe);
    if ismember(fileframe, files_done)
        continue
    end
    currentTable = slicesTable(strcmp(fileframe, slicesTable.fileframe), ...
        {'filename','area','z'});
    [~, idx] = max(currentTable.area); 
    if (length(currentTable.z(idx)) ~= 1)
        error('something is wrong')
    end
    [~,n,~] = fileparts(currentTable.filename(idx));
    file_cleaned = fullfile(maskdir, sprintf('%s.png', n));
    if ~exist(file_cleaned, 'file')       
        % open image
        img_segmentation = open_ilastik_p( ...
            fullfile(probdir, char(currentTable.filename(idx))), const);
        % Clean the Ilastik output
        cleaned_segmentation = clean_segmentation(img_segmentation, const);
        imwrite(cleaned_segmentation+1, const.cmap_dmask, file_cleaned);
    end
    fprintf(fID, '%s,%s,%s,%d\n', currentTable.filename(idx), fileframe, ...
        extractAfter(fileframe,'_t'), currentTable.z(idx));
    copyfile(file_cleaned, fullfile(centersdir, sprintf('%s.png', n)));
    fprintf('... %s', tocstring())
end
fclose(fID);
fprintf('\nall centers stored.\n')
