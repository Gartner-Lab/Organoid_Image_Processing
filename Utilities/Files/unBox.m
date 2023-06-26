% Remove suffixes that Box adds to file names for duplicates. Finds
% duplicate, if any. Removes or renames file as necessary.
function [newpath] = unBox(filepath)
[folder, filename, ext] = fileparts(filepath);

renamedname = strrep(filename,' (GartnerLab SVC-Box)','');
renamedname = strrep(renamedname,' (jennifer.hu@ucsf.edu)','');

if ~strcmp(renamedname, filename)
    newpath = fullfile(folder, [renamedname, ext]);
    if isfile(newpath)
        delete(fullfile(folder, [filename, ext]));
    else
        movefile(fullfile(folder, [filename, ext]), newpath);
    end
    fprintf('%s - renamed\n', filename);
else
    newpath = filepath;
end