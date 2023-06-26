% make new metadata
function [metadata] = extract_metadata(folder_name, file_name, csvTable, consts)
    % search file folder and name for date, time, strain
    full_name = fullfile(folder_name, file_name);
    [file_date, file_time, file_strain] = extract_dts(full_name, consts);
    if isempty(file_strain)
        file_strain = '240L,240L,240L';
        warning('Assuming 240L for %s (%s)', file_name, folder_name);
    end
    assert(~any(isempty([file_date, file_time, file_strain])));
    if isempty(csvTable)
        chL = ''; chM = '';
    else
        [~, chL, chM, ~] = get_folder_ch(folder_name, csvTable);
    end

    file_virus = extract_virus(folder_name, file_name, consts);

    % ECM
    if (contains(file_name, '50M') || contains(file_name, '50matrigel') || contains(file_name, 'lowMG'))
        file_ECM = '0';
    elseif contains(full_name, 'agarose')
        file_ECM = '-1';
    elseif contains(file_name, 'MGCOL')
        file_ECM = '2';
    elseif contains(file_name, 'COL')
        file_ECM = '3';
    elseif contains(file_name, '10pct_MG')
        file_ECM = '4';
    else % default, plain Matrigel
        file_ECM = '1';
    end
    
    % drugs
    if (contains(file_name, 'DMSO'))
        if (contains(file_name, 'DMSO2M'))
            file_drug = 'DMSO2M';
        else
            file_drug = 'DMSO';
        end
    elseif (contains(file_name, 'afuresertib'))
        if (contains(file_name, 'afuresertib2D'))
            file_drug = 'afuresertib2D';
        else
            file_drug = 'afuresertib';
        end
    elseif (contains(file_name, 'EHop016'))
        file_drug = 'EHop016';
    elseif (contains(file_name, 'GSK2334470'))
        file_drug = 'GSK2334470';
    elseif (contains(file_name, 'NSC23766'))
        file_drug = 'NSC23766';
    elseif (contains(file_name, 'CHIR66021') || contains(file_name, 'CHIR99021'))
        file_drug = 'CHIR99021';
    elseif (contains(file_name, 'Y27632'))
        file_drug = 'Y27632';
    elseif (contains(file_name, 'CI1040'))
        file_drug = 'CI1040';
    elseif (contains(file_name, 'Rapalink'))
        file_drug = 'Rapalink';
    elseif (contains(file_name, 'HGF'))
        file_drug = 'HGF';
    elseif (contains(file_name, 'EGF'))
        file_drug = 'EGF';
    elseif (contains(file_name, 'FGF2'))
        file_drug = 'FGF2';
    elseif (contains(file_name, 'TGFB'))
        file_drug = 'TGFB';
    elseif (contains(file_name, 'oldtyro'))
        file_drug = 'oldtyro';
    elseif (contains(file_name, 'NRG4'))
        file_drug = 'NRG4';
    elseif (contains(file_name, 'metformin'))
        file_drug = 'metformin';
    elseif (contains(file_name, 'metform01'))
        file_drug = 'metform01';
    elseif (contains(file_name, 'MK2206'))
        if (contains(file_name, 'MK22062D'))
            file_drug = 'MK22062D';
        else
            file_drug = 'MK2206';
        end
    elseif (contains(file_name, 'TFA'))
        if (contains(file_name, 'TFAcopanlisib') || contains(file_name, 'TFA2C'))
            file_drug = 'TFA2C';
        elseif (contains(file_name, 'copanlisibTFA'))
            file_drug = 'copanlisib2T';
        elseif (contains(file_name, 'TFA1C'))
            file_drug = 'TFA1C';
        else
            file_drug = 'TFA';
        end
    elseif (contains(file_name, 'copanlisib'))
        if (contains(file_name, 'copanlisib1T'))
            file_drug = 'copanlisib1T';
        elseif (contains(file_name, 'copanlisib2T'))
            file_drug = 'copanlisib2T';
        else
            file_drug = 'copanlisib';
        end
    elseif (contains(file_name, 'MK2D'))
        file_drug = 'MK22062D';
    elseif (contains(file_name, ' bat'))
        file_drug = 'bat';
    elseif (contains(file_name, 'SB431542') || contains(file_name, 'SB4351542') ...
            || contains(file_name, 'SB431542')) % I keep spelling it wrong
        if contains(file_name, 'SB431542uM100')
            file_drug = 'SB431542:100uM';
        elseif contains(file_name, 'SB431542nM100')
            file_drug = 'SB431542:100nM';
        elseif contains(file_name, 'SB431542uM10')
            file_drug = 'SB431542:10uM';
        else
            file_drug = 'SB431542:100uM';
        end
    elseif (contains(file_name, 'PMA'))
        file_drug = 'PMA';
    elseif (contains(file_name, 'ITSX'))
        file_drug = 'ITSX';
    elseif (contains(file_name, 'ITS'))
        file_drug = 'ITS';
    elseif (contains(file_name, 'aphidicolin'))
        file_drug = 'aphidicolin';
    elseif (contains(file_name, 'cytoD'))
        file_drug = 'cytoD';
    elseif (contains(file_name, 'jasp'))
        file_drug = 'jasp';
    elseif (contains(file_name, 'CK666'))
        file_drug = 'CK666';
    elseif (contains(file_name, 'RGDS'))
        file_drug = 'RGDS';
    elseif (contains(file_name, 'bleb'))
        file_drug = 'bleb';
    elseif (contains(file_name, 'TCI15'))
        file_drug = 'TCI15';
    else
        file_drug = '';
    end

    %% get confluence, MG_density, drug, virus
    % set default values
    file_confluence = '0';
    file_FDG = '';
    file_CD10 = '0';

    if (contains(file_name, ' d') || contains(file_name, ' sd'))
        file_confluence = '1';
    elseif (contains(file_name, ' s'))
        file_confluence = '-1';
    end

    if contains(file_name, 'hiS')
        file_FDG = 'h';
    elseif contains(file_name, 'loS')
        file_FDG = 'l';
    elseif contains(file_name, 'FDG')
        % user input required
        fprintf('\nFolder: %s\nFile: %s\n', folder_name, file_name);
        c = input('FDG: none/high/low (/h/l): ', 's');
        file_FDG = c;
    end
    
    if strcmp(file_date, '2017') % this is for VS data folder
        dt = datetime(2017,1,1); 
    else
        dt = datetime(file_date, 'InputFormat', 'yyyy-MM-dd');
    end
    if contains(file_name, 'CD10-')
        file_CD10 = '-1';
    % Muc1/CD10 sorts are also CD10+
    elseif (contains(file_name, 'CD10+') || dt < datetime(2017, 1, 1))
        file_CD10 = '1';
    end

    % update metadata with new information
    metadata = {string(chL), string(chM), file_date, file_time, file_strain, ...
        file_confluence, file_ECM, file_drug, file_virus, file_FDG, file_CD10};
end