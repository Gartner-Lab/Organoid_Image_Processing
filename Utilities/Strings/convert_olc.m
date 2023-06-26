function [output] = convert_olc(str, type)
    str = lower(str);
    % old rows may have semi-colons or not
    if (contains(str, ';'))
        output = strsplit(str, ';');
    elseif strcmp(type, 'o')
        output = regexp(str, '(c|m|s|i|<s|>s|<m|>m)', 'tokens');
        output = [output{:}];
    elseif strcmp(type, 'l')
        output = regexp(str, '(0|1)', 'tokens');
        output = [output{:}];
    elseif strcmp(type, 'c')
        output = regexp(str, '(\d+|)', 'tokens');
        output = [output{:}];
    end
end