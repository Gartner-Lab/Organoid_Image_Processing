%   Code for fixing names with double viruses because of substrings.
%   Input: cell array of strings (virus names) and array of indices to
%   collapse.

function [file_idx] = remove_subtrings(file_idx, viruses)
    % if one part of name is a substring of another part, remove it
    for i = find(file_idx)
        superstrings = find(contains(viruses, viruses{i}) & file_idx);
        if length(superstrings) > 1
            for j = superstrings
                if i == j
                    continue;
                elseif contains(viruses{j}, viruses{i})
                    % reassign i to 0
                    file_idx(i) = 0;
                end
            end
        end
     end
end