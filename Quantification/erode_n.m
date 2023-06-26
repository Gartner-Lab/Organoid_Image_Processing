% 	22 January 2018
% 	Jennifer L Hu
%	erode_n.m
%
%	Function that takes a binary mask and returns a binary mask of a eroded ring
%	that is [target] pixels in area. (1 in the ring.)
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
function [eroded] = erode_n(original, target)
    assert(all(original == 0 | original == 1, 'all'), 'Input should be binary.');
    % ensure that target is an integer
    target = round(target);
	[nrow, ncol] = size(original);
	mask = original; initial = sum(mask, 'all');
    % distance matrix away from the edge (invert because bwdist measures to nonzero)
    D = bwdist(mask == 0);
    [~, I] = sort(reshape(D, [nrow * ncol, 1])); % get the linear indices
    % skip the ECM pixels, which have distance 0 and get sorted first
    nskip = sum(D == 0, 'all');
    idx_erode = I((nskip+1):(nskip+target));
    assert(length(idx_erode) == target, 'This should be the correct number of pixels.');
    mask(idx_erode) = 0; % remove pixels from mask
    [~, k] = bwlabel(mask, 4); % possible islands cut off
    while k > 1
        % generate minconvhull of objects
        hull = bwconvhull(mask);
        % reshape, though not past original boundaries
        mask(hull & original) = 1;
        % recalculate
        remaining = target - (initial - sum(mask, 'all'));
        assert(remaining > 0, 'There should be more pixels to remove.');
        % distance matrix away from the edge (invert because bwdist measures to nonzero)
        D = bwdist(mask == 0); nskip = sum(D == 0, 'all');
        [~, I] = sort(reshape(D, [nrow * ncol, 1])); % get the indices
        idx_erode = I((nskip+1):(nskip+remaining)); 
        assert(length(idx_erode) == remaining, 'This should be the correct number of pixels.');
        mask(idx_erode) = 0;
        [~, k] = bwlabel(mask, 4);
    end
    %%  Old version using boundary  
% 	while (n_eroded < target)
% 		remaining = target - n_eroded;
% 		[B, L, k, ~] = bwboundaries(mask, 4, 'noholes');
%         first_hull_attempt = true;
%         % eroding may cause islands to appear if the shape is poky
%         while k > 1 
%             % find the smallest region remaining
%             [min_area, min_k] = find_min_obj(L,k);
%             % toss the smallest object if smaller than remaining
%             if min_area <= remaining
%                 % erode pixels
%                 eroded(L == min_k) = 1;
%                 mask(L == min_k) = 0;
%                 % recalculate
%                 n_eroded = sum(sum(eroded));
%                 remaining = target - n_eroded; assert(remaining >= 0);
%             else % island is too big: regenerate from hull and retry
%                 % not sure this is geometrically possible but check anyway
%                 assert(first_hull_attempt,'Hull attempt failed.');
%                 % generate minconvhull of objects
%                 hull = bwconvhull(mask);
%                 % reshape, though not past original boundaries
%                 eroded(hull) = 0;
%                 mask(hull & original) = 1;
%                 % recalculate
%                 n_eroded = sum(sum(eroded));
%                 remaining = target - n_eroded; assert(remaining > 0);
%                 % continue paring unless this happens again
%                 first_hull_attempt = false;
%             end
%             % how many regions remain?
%             [B, L, k, ~] = bwboundaries(mask, 4, 'noholes');
%         end
%         % actually I suppose it wouldn't be the end of the world
%         assert(k == 1, sprintf('%d',k)); B = B{1};
%         % end while loop if none remaining (min_area == remaining)
%         if remaining == 0
%             break
%         end
% 
%         % B (border) is a Q-by-2 matrix of row/column coordinates
%         outer_edge_n = size(B,1); assert(outer_edge_n > 0);
%         % trim B if needed
%         if outer_edge_n > remaining
%             B = B(1:remaining,:);
%         	outer_edge_n = size(B,1);
%         end
%         % reassign rows and columns
%         r = B(:,1); c = B(:,2);
%         assert(max(r) <= nrow); assert(max(c) <= ncol);
%         % not sure why I can't assign all at once
%         for i = 1:outer_edge_n
%             eroded(r(i), c(i)) = 1;
%             mask(r(i), c(i)) = 0;
%         end
%         % recalculate
%         n_eroded = sum(sum(eroded));
% 	end
    %% Final check and return the eroded pixels
	eroded = (mask ~= original); % record these pixels removed
    n_eroded = sum(eroded, 'all'); assert(n_eroded == target);
end