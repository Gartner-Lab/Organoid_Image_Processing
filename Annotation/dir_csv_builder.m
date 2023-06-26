% Script to start off the CSV containing folder info.
[const, ~] = constants();

%% normal code (skip if generating other dir_info)
% ignore any directory with these strings
exclude = [".DAV", "meh", "tif", "gif", "mp4", "oop", "timelapse", "streaming", "10AT", "thing", "cm", "2D"];
header_string = 'folder,imgtype,include,Ch1,Ch2,Ch3,Ch4,Ch5\n';
empty_row_string = '%s,,,,,\n';

%% 
if exist(const.dir_csv, 'file')
    overwrite = input('Directory csv already exists. Overwrite? (0/1): ');
    if (~overwrite)
        [path, name, ext] = fileparts(const.dir_csv);
        copyfile(const.dir_csv, sprintf('%s/%s%s', const.backupdir, name, ext))
    end
end

fprintf('Opening %s\nin write mode...\n', const.dir_csv);
fID = fopen(const.dir_csv, 'w');
if fID < 0
   [fID, errmsg] = fopen(const.dir_csv);
   disp(errmsg);
   return
end
fprintf(fID, header_string);

folders = regexp(genpath(const.czidir), '[^;]*', 'match');
n_folders = length(folders);
for f=1:n_folders
    if (~contains(folders{f}, exclude))
        % print empty row string
        fprintf(fID, empty_row_string, folders{f});
    end
end

fprintf('All done setting up. Go fill in the file info!\n');
fclose(fID);