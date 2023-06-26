%%  [cleaned] = clean_segmentation(img_segmentation, 
%                      [img_probabilities, plot_process, const])
%   2019-12-19
%   Jennifer Hu
%   Takes dmask input where MEP is 1 and LEP is 2, then processes out 
%   small features and gently smooths the outer surface.
function [cleaned] = clean_segmentation(segmentation, varargin)
    plot_process = 0; const = []; probabilities = [];
    if nargin > 1
        for i = 1:(nargin-1)
            if (isstruct(varargin{i}))
                const = varargin{i};
            elseif (size(varargin{i}, 1)) == size(segmentation, 1)
                probabilities = varargin{i};
            elseif (varargin{i} == 1 || varargin{i} == 0)
                plot_process = varargin{i};
            end
        end
    end
    if (isempty(const))
        warning('No constants struct provided in clean_segmentation.');
        [const, ~] = constants();
    end
    if (plot_process)
        figure(1); subplot(2,3,1); 
        imshow(segmentation, const.cmap_dmask); title('Original');
        figtitle('Cleaning Image Segmentation');
    end
    cleaned = segmentation;
    cells = (cleaned == const.pxtype_dmask.L) | (cleaned == const.pxtype_dmask.M);
    
    if ~any(cells, 'all') % it's empty
        return;
    end

    % Find and measure largest region of cells to calibrate size
    [cell_labels, n] = bwlabel(cells);
    cellstats = regionprops(cell_labels, 'FilledArea');
    [blob_biggest, ~] = max([cellstats.FilledArea]);
    blob_small = 500;
    blob_vsmall = round(blob_small/5);
    % medium = 0.2 of largest cell blob
    blob_medium = round(0.2 * blob_biggest);

    %% Find the primary organoid blob by size and centrality
    if (n > 1)
        cellstats = regionprops(cell_labels, 'FilledArea');
        [blob_biggest, ~] = max([cellstats.FilledArea]);
        % automatically delete anything less than 80% the size of blob_biggest
        small_idx = find([cellstats.FilledArea] < 0.8 * blob_biggest);
        for i = small_idx
            cleaned(cell_labels == i) = const.pxtype_dmask.E;
        end
        % reset
        cells = (cleaned == const.pxtype_dmask.L) | (cleaned == const.pxtype_dmask.M);
        [cell_labels, n] = bwlabel(cells);
        % remove all regions that are only one cell type
        if (n > 1)
            for i = 1:n
                if all(all(cleaned(cell_labels == i) == const.pxtype_dmask.L)) || ...
                        all(all(cleaned(cell_labels == i) == const.pxtype_dmask.M))
                    cleaned(cell_labels == i) = const.pxtype_dmask.E;
                end
            end
            % reset
            cells = (cleaned == const.pxtype_dmask.L) | (cleaned == const.pxtype_dmask.M);
            [cell_labels, n] = bwlabel(cells);
        end
        % remove all regions touching the edge if there is more than one
        if (n > 1)
            cleaned(imclearborder(cells) == 0) = const.pxtype_dmask.E;
            % reset
            cells = (cleaned == const.pxtype_dmask.L) | (cleaned == const.pxtype_dmask.M);
            [cell_labels, n] = bwlabel(cells);
        end
        % if still more than one, delete all but largest
        if (n > 1)
            cellstats = regionprops(cell_labels, 'FilledArea');
            [~, label_biggest] = max([cellstats.FilledArea]);
            cleaned(cell_labels ~= label_biggest) = const.pxtype_dmask.E;
        end
        if (plot_process)
            figure(1); subplot(2,3,2); 
            imshow(cleaned, const.cmap_dmask); title('Focusing');
        end
    end

    %% Basic region filling
    % Fill in medium and smaller ECM regions with regionfill
    medium3 = (cleaned == const.pxtype_dmask.E) - bwareaopen(cleaned == const.pxtype_dmask.E, blob_medium, 4);
    if any(any(medium3))
        cleaned = discretefill(cleaned, medium3);
        if (plot_process)
            figure(1); subplot(2,3,3); 
            imshow(cleaned, const.cmap_dmask); title('ECM Filling');
        end
    end

    % Remove tiny chunks of cells and fill in with regionfill
    for celltype = [const.pxtype_dmask.L, const.pxtype_dmask.M]
        vsmall = (cleaned == celltype) - bwareaopen(cleaned == celltype, blob_vsmall, 4);
        if any(any(vsmall))
            cleaned = discretefill(cleaned, vsmall);
            if (plot_process)
                figure(1); subplot(2,3,4); 
                imshow(cleaned, const.cmap_dmask); title('Cell Filling');
            end
        end
    end

    %% Fill in remaining large internal ECM with regionfill or most-probable cell type
    cells = (cleaned == const.pxtype_dmask.L) | (cleaned == const.pxtype_dmask.M);
    loose_ECM = cells - imfill(cells, 'holes');
    if any(any(loose_ECM))
        if isempty(probabilities)
            cleaned = discretefill(cleaned, loose_ECM);
        else
            [hole_labels, n] = bwlabel(loose_ECM);
            Lp = probabilities(:,:,const.pxtype_ilastik.L);
            Mp = probabilities(:,:,const.pxtype_ilastik.M);
            for j = 1:n
                % compare probabilities for L and M in hole
                if median(Lp(hole_labels == j), 'all') >= ...
                        median(Mp(hole_labels == j), 'all')
                    cleaned(hole_labels == j) = const.pxtype_dmask.L;
                else
                    cleaned(hole_labels == j) = const.pxtype_dmask.M;
                end
            end
        end
        if (plot_process)
            figure(1); subplot(2,3,5); 
            imshow(cleaned, const.cmap_dmask); title('Second Hole Filling');
        end
    end

    %% Fill in concavities with imclose with regionfill
    se = strel('disk', blob_small);
    cells = (cleaned == const.pxtype_dmask.L) | (cleaned == const.pxtype_dmask.M);
    concavities = imclose(cells, se) - cells;
    if any(any(concavities))
        cleaned = discretefill(cleaned, concavities);
        if (plot_process)
            figure(1); subplot(2,3,6); 
            imshow(cleaned, const.cmap_dmask); title('Concavity Filling');
        end
    end
end