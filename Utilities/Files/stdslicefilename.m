%% Standardize slice file names.
% Remove suffixes that Box adds to file names for duplicates.
% Converts .tif file extensions to .tiff. Finds duplicate
% file, if any. Removes or renames file as necessary.
function [newpath] = stdslicefilename(filepath)
[folder, filename, ext] = fileparts(filepath);

renamedname = strrep(filename,' (GartnerLab SVC-Box)','');
renamedname = strrep(renamedname,' (jennifer.hu@ucsf.edu)','');
if strcmp(ext, '.tif'), ext = '.tiff'; end

if ~strcmp(renamedname, filename)
    newpath = fullfile(folder, [renamedname, ext]);
    if isfile(newpath)
        delete(filepath);
    else
        movefile(filepath, newpath);
    end
    fprintf('%s - renamed\n', filename);
else
    newpath = filepath;
end