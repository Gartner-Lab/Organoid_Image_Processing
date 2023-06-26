function [files] = files_in_dir_ending(inputdir, ending)
    files = dir(inputdir);
    files = files(endsWith({files.name}, ending));
end