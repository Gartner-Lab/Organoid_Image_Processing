function [swapped] = invert_outs(outs)
    if isempty(outs)
        swapped = outs;
        return
    end
    % read outcome, convert to cell array of strings if necessary
    use_cell_array = iscell(outs);
    if ~use_cell_array
        outs = expand_string(outs);
    end
    for i=1:length(outs)
        switch outs{i}
            case 'c'
                outs{i} = 'i';
            case '>m'
                outs{i} = '<m';
            case '<m'
                outs{i} = '>m';
            case '>s'
                outs{i} = '<s';
            case '<s'
                outs{i} = '>s';
            case 'i'
                outs{i} = 'c';
        end
    end
    if use_cell_array
        swapped = outs;
    else
        swapped = join(outs,';');
        % string, not cell
        swapped = swapped{1};
    end
end