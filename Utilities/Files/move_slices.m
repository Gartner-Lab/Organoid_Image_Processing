%% 21 October 2020
% The number of slices is now too big for File Explorer/Finder to open.
% This code looks in the segmented slices folder, the SBG imgtype/brightness
% or done folders, and the raw folders. It moves files to the right
% locations, in and out of the todo/done folders as needed. It also checks
% for filenames marking a sync conflict with Box and renames or removes them.
% In each raw/imgtype folder, there will be
% - new: generated by slice_imgs
% - done: has an SBG version already
% In each SBG/imgtype folder, there will be
% - new: generated by FIJI clean_slices.ijm
% - bright/dim: ready for Ilastik
% - done: Ilastik slice already generated
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %


if (~exist('const', 'var'))
    [const, consts] = constants();
end
segdir = fullfile(const.slicedir, 'masks');
simpledir = fullfile(segdir, 'Simple');
files_simple = dir(simpledir); nsimple = length(files_simple);
imgtypes = {'LSM_FP'}; nimgtypes = length(imgtypes);

%% remove Box duplicates from SBG imgtypes folders
for i = 1:nimgtypes
    imgtype = imgtypes{i};
    sbgdir = fullfile(const.slicedir, 'SBG', imgtype);
    if contains(imgtype, 'FP')
        subfolders = {'bright', 'dim'};
    else
        subfolders = {'new'};
    end
    for j = 1:length(subfolders)
        files_sbg = dir(fullfile(sbgdir, subfolders{j}));
        nsbg = length(files_sbg);
        for k = 1:nsbg
            if ~files_sbg(k).isdir
                stdslicefilename(fullfile(sbgdir, subfolders{j}, files_sbg(k).name));
            end
        end
    end
end



%% renewable files
% did you finish renewing Simple segmentations for renew folder?
renewed = true;
files_renew = dir(fullfile(const.slicedir, 'SBG', 'LSM_FP', 'renew'));
n_renew = length(files_renew);
for i = 1:n_renew
    if files_renew(i).isdir, continue; end
    slicename = files_renew(i).name;
    donefile = fullfile(const.slicedir, 'SBG', 'LSM_FP', 'done', slicename);
    todofile = fullfile(const.slicedir, 'SBG', 'LSM_FP', ...
        fluor_brightness(donefile), slicename);

    if (renewed)
        if isfile(todofile) ||  isfile(donefile)
            % remove it from renew folder
            delete(fullfile(const.slicedir, 'SBG', 'LSM_FP', 'renew', slicename));
            if ~isfile(donefile)
                movefile(todofile, donefile);
            end
            fprintf('%d/%d %s > done\n', i-2, n_renew-2, slicename);
        end
    else
        file_mask = fullfile(simpledir, slicename);
        file_cleaned = fullfile(segdir, 'Cleaned', slicename);
        % remove the existing Simple and Cleaned masks
        if isfile(file_mask)
            delete(file_mask);
        end
        if isfile(file_cleaned)
            delete(file_cleaned);
        end
        % move to 'new' folder
        if isfile(donefile)
            movefile(donefile, todofile);
        end
        fprintf('%d/%d %s > todo\n', i-2, n_renew-2, slicename);
    end
end


%% for segmented files, move the SBG from new/bright/dim to done
fprintf('%d segmentations.\n', nsimple-2);
for i = 1:nsimple
    if files_simple(i).isdir, continue; end
    [~, imname, ~] = fileparts(stdslicefilename(fullfile(simpledir, files_simple(i).name)));
    % have to go looking in imgtypes folders for original
    slicename = [imname, '.png']; sbgfile = '';
    for j = 1:nimgtypes
        imgtype = imgtypes{j};
        parentdir = fullfile(const.slicedir, 'SBG', imgtype);
        if (j == 1 || j == 2) % FP
            f = fullfile(parentdir, 'bright', slicename);
            if (isfile(f))
                sbgfile = f;
            else
                f = fullfile(parentdir, 'dim', slicename);
                if isfile(f), sbgfile = f; end
            end
        end
        f = fullfile(parentdir, slicename);
        if isfile(f), sbgfile = f; else
            f = fullfile(parentdir, 'new', slicename);
            if isfile(f), sbgfile = f; end
        end
        % move into done folder
        if ~isempty(sbgfile)
            movefile(sbgfile, fullfile(parentdir, 'done', slicename));
            fprintf('%d/%d [%s] %s > done\n', i-2, nsimple-2, imgtype, slicename);
            newrawfile = fullfile(const.slicedir, 'raw', imgtype, 'new', slicename);
            if isfile(newrawfile)
                movefile(newrawfile, strrep(newrawfile, 'new', 'done'));
            end
            break;
        end
    end
    % Remove Cleaned masks that are older than the corresponding Simple mask
    file_cleaned = fullfile(segdir, 'Cleaned', files_simple(i).name);
    if isfile(file_cleaned) && datetime(dir(file_cleaned).date) < datetime(files_simple(i).date)
        delete(file_cleaned);
    end
end

for i = 1:nimgtypes
    imgtype = imgtypes{i};
    % move unfinished ones from new into the correct brightness folder
    sbgnewdir = fullfile(const.slicedir, 'SBG', imgtype, 'new');
    sbgdonedir = fullfile(const.slicedir, 'SBG', imgtype, 'done');
    rawnewdir = fullfile(const.slicedir, 'raw', imgtype, 'new');
    rawdonedir = fullfile(const.slicedir, 'raw', imgtype, 'done');
    files_new = dir(sbgnewdir); nnew = length(files_new);
    fprintf('\n%d new %s SBG slices.\n', nnew-2, imgtype);
    for k = 1:nnew % newly SBG'd by Fiji
        if files_new(k).isdir, continue; end
        [~, imname, ext] = fileparts(stdslicefilename(fullfile(sbgnewdir,files_new(k).name)));
        slicename = [imname, ext];
        % does it have a mask? it better not
        assert(~isfile(fullfile(simpledir,[imname,'.tiff'])));
        if (i == 1 || i == 2) % FP: move into right brightness subfolder
            brightness = fluor_brightness(imname);
            movefile(fullfile(sbgnewdir, slicename), ...
                fullfile(const.slicedir, 'SBG', imgtype, brightness, slicename));
            fprintf('%d/%d [%s] %s > %s\n', k-2, nnew-2, imgtype, slicename, brightness);
        end % otherwise leave in 'new'
        % also move the raw slice out of its 'new' folder so you don't
        % run clean_slices on it again
        if isfile(fullfile(rawnewdir, slicename))
            movefile(fullfile(rawnewdir, slicename), fullfile(rawdonedir, slicename));
        end
        if isfile(fullfile(const.slicedir, 'raw', imgtype, slicename))
            movefile(fullfile(const.slicedir, 'raw', imgtype, slicename), ...
                fullfile(rawdonedir, slicename));
        end
    end
    % move SBG from done folder into correct brightness if mask doesn't exist
    files_done = dir(sbgdonedir); ndone = length(files_done);
    fprintf('\n%d done %s SBG slices.\n', ndone-2, imgtype);
    for k = 1:ndone % SBGs marked as done
        if files_done(k).isdir, continue; end
        [~, imname, ext] = fileparts(stdslicefilename(fullfile(sbgdonedir,files_done(k).name)));
        slicename = [imname, ext];
        % if something in done folder isn't in mask folder
        if ~isfile(fullfile(simpledir, [imname, '.tiff']))
            brightness = fluor_brightness(imname);
            % move into todo folder
            movefile(fullfile(sbgdonedir, slicename), ...
                fullfile(const.slicedir, 'SBG', imgtype, brightness, slicename));
            fprintf('%d/%d [%s] %s > %s\n', k-2, ndone-2, imgtype, slicename, brightness);
        end
        % move the raw slices out
        if isfile(fullfile(rawnewdir, slicename))
            movefile(fullfile(rawnewdir, slicename), fullfile(rawdonedir, slicename));
        end
        if isfile(fullfile(const.slicedir, 'raw', imgtype, slicename))
            movefile(fullfile(const.slicedir, 'raw', imgtype, slicename), ...
                fullfile(rawdonedir, slicename));
        end
    end
end
beep();
fprintf('\nRun again after finishing ilastik to put things in done folder.\n');