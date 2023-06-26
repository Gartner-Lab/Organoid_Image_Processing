% Takes an organoid RGB image and redistributes MEP and LEP pixels
% so that the resulting organoid has a LEP core and a MEP border.
function [idealized] = idealize(organoid)
    [~, M, ~, both] = rgb2dmask(organoid);
    % determine number of pixels that are MEP
    nMEP = sum(sum(M));
    if (nMEP > 0)
        % make a ball of LEP pixels
        idealized = both*2;
        % border region [nMEP] pixels in area
        eroded = erode_n(both, nMEP);
        % assign MEP to border region
        idealized(eroded) = 1;
        nMEP2 = sum(sum(idealized == 1));
        assert(nMEP2 == nMEP, sprintf('final %d, initial %d', nMEP2, nMEP))
        idealized = dmask2rgb(idealized);
    else
        idealized = organoid;
    end
end