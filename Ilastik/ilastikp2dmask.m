% Converts a Probabilities output from ilastik into a simple segmentation.
function [dmask] = ilastikp2dmask(p, const)
    [~, s] = max(p,[],3); % finds indices of max value along z
    dmask = ilastik2dmask(s, const);
end