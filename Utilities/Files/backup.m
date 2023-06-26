function [] = backup(filepath)
    if isfile(filepath)
        n = 0;
        old_filepath = filepath;
        % make a backup of the existing file at this path
        [path, name, ext] = fileparts(filepath);
        % make a backups subfolder
        path = fullfile(path, 'backups');
        if ~isfolder(path), mkdir(path); end
        if (contains(name, '_backup'))
            name = extractBefore(name, '_backup');
        end    
        while (isfile(filepath)) % keep going til you find an unused name
            filepath = sprintf('%s/%s_backup%d%s', path, name, n, ext);
            % increase the number at the end if need be
            n = n + 1;
        end
        copyfile(old_filepath, filepath);
    end
end