%   24 February 2018
%   expand_string.m
%
%   Given a string that may or may not contain semi-colons,
%   returns a cell array of strings corresponding to separate outcomes,
%   lumens, or centers. If string is empty, return empty cell array.
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

function [output] = expand_string(input)
    if isempty(input)
        output = {};
        return
    end
    % return cell array of strings that were separated by semicolons
    incell = strsplit(input,';');
    % if string contained semicolons our work is already done
    if length(incell) > 1
        output = incell;
    else
        % find numbers/letters
        isalphanum = isstrprop(input,'alphanum');
        n = length(isalphanum);
        % initialize cell array
        output = cell(1,n);
        for i=1:n
            % letter or number
            if isalphanum(i)
                % if previous character is not alphanumeric
                if i > 1 && ~isalphanum(i-1)
                    % include previous character
                    output{i} = [input(i-1), input(i)];
                else
                    % write just this character
                    output{i} = input(i);
                end
            end
        end
        % remove empty cell elements from output
        output = output(~cellfun('isempty',output));
    end
end