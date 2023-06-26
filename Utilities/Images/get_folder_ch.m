%   Looks up folder in csvTable. Returns total number of channels, chL, and
%   chM.

function [nch, chL, chM, chMG] = get_folder_ch(folder, csvTable)
    % find the folder's index in csvTable
    f = find(strcmp(csvTable.folder, folder));    
    if length(f) ~= 1
        nch = 0; chL = 0; chM = 0; chMG = 0;
        return
    end
    % determine total # channels based on number of non-empty entries in csvTable
    row = [csvTable.Ch1(f), csvTable.Ch2(f), csvTable.Ch3(f), csvTable.Ch4(f), csvTable.Ch5(f)];
    nch = sum(~strcmp(row, ''));
    % determine which channels are L and M (or M1/M2). 
    % Store as 2 or 1. Store MG channel as 3.
    chID_row = cellfun(@(x) (strcmp(x, 'M') || strcmp(x, 'M1') || strcmp(x, 'M2')) ...
        + 2*strcmp(x, 'L') + 3*strcmp(x, 'MG'), row);
    chL = find(chID_row == 2);
    chM = find(chID_row == 1); % can be two
    chMG = find(chID_row == 3);
end