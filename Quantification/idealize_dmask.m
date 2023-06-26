% Takes an organoid dmask and redistributes MEP and LEP pixels
% so that the resulting organoid has a LEP core and a MEP border.
% Doesn't care which is which, so reverse the arguments for unideal.
function [idealized] = idealize_dmask(organoid, distanceorder, centertype, bordertype, pxE)
    C = (organoid == bordertype);
    both = (organoid == centertype | C);
    % determine number of pixels that are MEP
    nC = sum(C, 'all'); nE = sum(~both, 'all');
    if (nC > 0)
        % make a ball of LEP pixels
        idealized = ones(size(both))*pxE; idealized(both) = centertype;
        % border region [nC] pixels in area by sorting
        border = distanceorder((nE+1):(nE+nC)); % the first nC pixels after
        nC2 = sum(both(border), 'all');
        assert(nC2 == nC, sprintf('final %d, initial %d', nC2, nC));
        % assign border region
        idealized(border) = bordertype;
    else
        idealized = organoid;
    end
end