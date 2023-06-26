%% goal: cell arrays (outs, lums, centers) containing matched strings
function [outs, lums, centers, n_outs, n_centers] = extract_olc(answerstr)
    answerstr = lower(deblank(answerstr));
    % inject semicolons between unseparated organoid annotations
    answerstr = regexprep(answerstr,'(\d+|c|m|s|i|<s|>s|<m|>m|l)(c|m|s|i|<|>)','$1;$2');
    % separate into annotations by splitting along semicolons
    answers = strsplit(answerstr, {',',';'});
    % remove any accidental empty entries
    answers = {answers{~cellfun(@isempty, answers)}};
    n_answers = length(answers);

    % initialize variables
    outs = cell(1, n_answers);
    lums = cell(1, n_answers);
    centers = cell(1, n_answers);
    n_outs = 0;
    n_centers = 0;

    if (n_answers == 0)
        return
    end
    
    for i = 1:n_answers
        % extract outcome
        strs = regexp(answers{i}, '(c|m|s|i|<s|>s|<m|>m|)([l]{0,1})(\d+|)', 'tokens');
        strs = strs{1};
        assert(length(strs) == 3);
        outs{i} = strs{1};
        % this is lowercase l for 'lumen'
        if isempty(strs{2})
            lums{i} = '0';
        else
            lums{i} = '1';
        end
        if ~isempty(outs{i})
            n_outs = n_outs + 1;
        end
        centers{i} = strs{3};
        if ~isempty(strs{3})
            n_centers = n_centers + 1;
        end
    end

end