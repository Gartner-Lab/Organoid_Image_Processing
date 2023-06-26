% process_predictions.m
% Processes MEP/LEP [0 1 2] images in preparation for quantification.
% Remove LEPs and MEPs off to the side/not attached to organoid.
% Fill in "cracks" and crevices of organoid defined by convex hull.

function [processed] = process_predictions(img)
    pruned = img;
    % everything labeled as cells
    [B,L,N,~] = bwboundaries(pruned > 0,8,'noholes');
    % only fix if more than one region
    if N > 1
        stats = regionprops(L,'Centroid','Area');
        % find largest region index
        [A, ind] = max([stats.Area]);
        boundary = B{ind};
        % put in x,y order
        boundary = [boundary(:,2),boundary(:,1)];
        % check if other regions should be removed
        for i=1:N
            if i ~= ind
                % min distance from boundary
                D = pdist2(boundary, stats(i).Centroid,'euclidean','Smallest',1);
                % if too far away, remove
                if D > 0.2*sqrt(A)
                    pruned(L == i) = 0;
                end
                % if too small, remove
                if stats(i).Area < 350
                    pruned(L == i) = 0;
                end
            end
        end
    end
    % identify minimal convex hull
    hull = bwconvhull(pruned);
    % use fill_regions to fill hull
    regions = hull & pruned == 0;
    [~,L] = bwboundaries(regions);
    processed = pruned;
    reassignments = fill_regions(L, processed);
    processed(reassignments == 1) = 1; processed(reassignments == 2) = 2;
    % if anything is now detached from the largest region, throw it out
    [~,L,N,~] = bwboundaries(processed > 0,8,'noholes');
    if N > 1
        stats = regionprops(L,'Centroid','Area');
        % find largest region index
        [~, ind] = max([stats.Area]);
        processed(L ~= ind) = 0;
    end
    
    % for debugging, just comment the display code below
%     colormap = [0 0 0; 1 0 0; 0 1 0];
%     figure(2)
%     subplot(2,2,1), imshow(img,colormap), title('Initial');
%     subplot(2,2,2), imshow(pruned, colormap), title('Pruned');
%     subplot(2,2,3), imshow(hull), title('Hull');
%     subplot(2,2,4), imshow(processed, colormap), title('Processed');
end