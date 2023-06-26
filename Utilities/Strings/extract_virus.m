function [virus] = extract_virus(folder, file, consts)
    viruses = consts{strcmp(consts{1}, 'viruses')};
    % RFP- or R- means negative for virus reporter
    if (contains(file,'RFP-') || contains(file,'R-') || contains(file,'p16sh--') || contains(file,'p16sh-.'))
        virus = '';
        return
    end
    % I did some experiments with CD10
    if (contains(file,'CD10'))
        virus = '';
        return
    end
    
    %% proper name replacements
    file = replace(file, 'shpuro', 'sh1puro');
    file = replace(file, 'Myc', 'MYC');
    file = replace(file, 'Her2', 'ERBB2');
    file = replace(file, 'PGKAkt', 'PGK_Akt');
    file = replace(file, 'Ecad', 'CDH1');
    file = replace(file, 'p16', 'CDKN2A');
    file = replace(file, 'p53', 'TP53');
    file = replace(file, 'p63', 'TP63');
    file = replace(file, 'Akt', 'AKT');
    file = replace(file, ' B1', ' ITGB1');
    file = replace(file, ' D1', ' CCND1');
    file = replace(file, 'cyclinD1', 'CCND1');
    
    %% check for viruses in name
    file_idx = cellfun(@(x) contains(file,x), viruses);
    
    %% replace RFP with correct virus
    RFP = cellfun(@(x) strcmp('RFP',x),viruses);
    % if name contains RFP
    if file_idx(RFP)
        % remove RFP
        file_idx(RFP) = 0;
        % look for other viruses in file_idx
        if any(file_idx(~RFP))
        else
            % look in folder for clue about virus identity
            file_idx = cellfun(@(x) contains(folder,x), viruses);
            assert(any(file_idx))
        end
    end
    
    %% name processing
    % some virus names are substrings of each other, so collapse to longest
    if (sum(file_idx == 1) > 1)
        file_idx = remove_substrings(file_idx, viruses);
    elseif (sum(file_idx) == 0)
        % no virus here
        virus = '';
        return
    end
    % if E17K, convert to AKTE17K
    if file_idx(strcmp(viruses, 'E17K'))
        file_idx(strcmp(viruses, 'AKT1')) = 0;
        file_idx(strcmp(viruses, 'E17K')) = 0;
        file_idx(strcmp(viruses, 'AKTE17K')) = 1;
    end
   
    % combine different names for same condition
    % For mixed aggregates: 1st LEP 2nd MEP (e.g. GFPL+mCh_CTNND1sh1M)
    % For MEP/LEP only aggregates: 1st Control 2nd KD Construct (e.g. mChM+GFP_CTNND1sh1M)
    degenerates = consts{strcmp(consts{1}, 'degenerates')};
    for j=1:length(degenerates)
        virus_set = degenerates{j};
        % indices of degenerate strings in the viruses cell array
        degenerate_idx = ismember(viruses, virus_set(2:end));
        if any(file_idx(degenerate_idx))
            file_idx(degenerate_idx) = 0;
            file_idx(strcmp(viruses, virus_set{1})) = 1;
        end
    end
    % squish together names
    virus = strjoin(viruses(logical(file_idx)),' ');
    if sum(file_idx) > 1
        warning('Multiple virus names found in %s (%s)', file, virus)
    end
    
    % don't need this anymore I think
%     % I used SFFV p16 viruses before
%     if (contains(virus,'p16') && ~contains(folder,'EF1a'))
%         virus = ['SFFV ',virus];
%     end
    
end