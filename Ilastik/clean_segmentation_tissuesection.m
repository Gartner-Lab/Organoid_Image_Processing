%%  [cleaned] = clean_segmentation_tissuesection(img_segmentation)
%   2021-01-06
%   Jennifer Hu
%   For processing ilastik outputs of Sundus's tissue sections.
%   Takes input with px identities of L, M, D, U, E, and pixel size in um,
%   then processes out small features and gently smooths the outer surface.
%   Differences from clean_segmentation:
%   - allow holes inside objects
%   - allow multiple objects of interest
function [cleaned] = clean_segmentation_tissuesection(segmentation, psize)
    px = struct('L',42,'M',85,'D',127,'U',170,'E',212);
    plot_process = 1;
    cmap_5mask = zeros(255,3);
    cmap_5mask(px.L+1,:) = [13, 176, 75] / 255;
    cmap_5mask(px.M+1,:) = [240, 4, 127] / 255;
    cmap_5mask(px.D+1,:) = [242, 218, 3] / 255;
    cmap_5mask(px.U+1,:) = [50 50 50] / 255;
    cmap_5mask(px.E,:) = [0 0 0];
    %% size parameters in pixels
    blob_small = round(100/(psize^2)); % about a cell
    blob_vsmall = round(blob_small/5); % subcell size chunks
    blob_vvsmall = round(blob_vsmall/5); % debris
    blob_medium = blob_small * 5; % a few cells
    sesize = 1; % just a tiny structuring element
    if (plot_process)
        h = figure(20); subplot(2,3,1);
        imshow(segmentation, cmap_5mask); title('Original');
        figtitle('Cleaning Image Segmentation');
    end
    cleaned = segmentation;
    
    %% Remove cells+lumen objects touching the image border
    nonborder = imclearborder(cleaned ~= px.E);
    cleaned(~nonborder) = px.E;
    % and very small blobs
    cleaned(~bwareaopen(cleaned ~= px.E, blob_vsmall, 4) & (cleaned ~= px.E)) = px.E;
    
    %% Fill in ECM holes in lumen objects with lumen
    cleaned(imfill(cleaned == px.U, 'holes') & cleaned == px.E) = px.U;
    
    %% Remove objects that are all lumen or below a threshold # cells
    [object_labels, n] = bwlabel(cleaned ~= px.E);
    for i = 1:n
        object = cleaned(object_labels == i);
        if sum(object ~= px.U, 'all') < blob_medium
            cleaned(object_labels == i) = px.E;
        end
    end
    
    %% Remove lumen pixels on the outside of objects
    cleaned(~imfill(cleaned == px.L | cleaned == px.M, 'holes') & ...
        cleaned == px.U) = px.E;
    if (plot_process)
        figure(h); subplot(2,3,2); 
        imshow(cleaned, cmap_5mask); title('Lumen Cleaning');
    end
    
    %% Dilate MEP pixels because they tend to have little cytoplasm
    se = strel('disk', sesize);
    % replace nearby ECM/lumen bits with MEP
    cleaned(imdilate(cleaned == px.M, se) & ...
        (cleaned == px.E | cleaned == px.U)) = px.M; 
    % fill in any small holes generated with MEP
    MEPholes = imfill(cleaned == px.M, 'holes') & ...
        (cleaned == px.E | cleaned == px.U);
    [holelabels, n] = bwlabel(MEPholes);
    for i = 1:n
        if sum(holelabels == i, 'all') < blob_small/2
            cleaned(holelabels == i) = px.M;
        end
    end
    % erode the same amount and replace with ECM if that's what it was
    cleaned(((cleaned == px.M) - imerode(cleaned == px.M, se)) ...
         & (segmentation == px.E | segmentation == px.U)) = px.E;
    if (plot_process)
        figure(h); subplot(2,3,3); 
        imshow(cleaned, cmap_5mask); title('MEP Closing');
    end
    
    
    %% remove little bits
    [cell_labels, n] = bwlabel(cleaned ~= px.E);
    % remove cell regions that are only one cell type or below a certain size
    for i = 1:n
        types = unique(cleaned(cell_labels == i));
        % only accept L+M and D+M objects
        containsLM = all(ismember([px.L, px.M], types));
        containsDM = all(ismember([px.D, px.M], types));
        if ~(containsLM || containsDM) || (sum(cell_labels == i, 'all') < blob_medium)
            cleaned(cell_labels == i) = px.E;
        end
    end

    %% Basic region filling
    se = strel('disk', sesize*4); 
    % Erode off spindly bits
    spindles = imopen(imfill(cleaned ~= px.E, 'holes'), se) & (cleaned == px.E);
    cleaned(spindles) = px.E;
    % Fill in concavities with imclose with regionfill
    cells = imfill(cleaned ~= px.E, 'holes');
    concavities = imclose(cells, se) - cells;
    if any(concavities, 'all')
        cleaned = discretefill(cleaned, concavities);
    end
    % Fill in small ECM and vsmall lumen regions with regionfill
    % probably nuclei
    [ECMs, m] = bwlabel(imfill(cleaned ~= px.E, 'holes') & (cleaned == px.E));
    for j = 1:m
        if sum(ECMs == j, 'all') < blob_small
            cleaned = discretefill(cleaned, ECMs == j);
        end
    end
    [lumens, m] = bwlabel(imfill(cleaned ~= px.E, 'holes') & (cleaned == px.U));
    for j = 1:m
        if sum(lumens == j, 'all') < blob_vsmall
            cleaned = discretefill(cleaned, lumens == j);
        end
    end
    if (plot_process)
        figure(h); subplot(2,3,4); 
        imshow(cleaned, cmap_5mask); title('Small Filling');
    end

    % Remove tiny cell debris and fill in with regionfill
    for celltype = [px.D, px.L, px.M]
        vvsmall = (cleaned == celltype) - bwareaopen(cleaned == celltype, blob_vvsmall, 4);
        if any(vvsmall, 'all')
            cleaned = discretefill(cleaned, vvsmall);
            % Repeat removing things
            [cell_labels, n] = bwlabel(cleaned ~= px.E);
            % remove cell regions that are only one cell type
            for i = 1:n
                types = unique(cleaned(cell_labels == i));
                % only accept L+M and D+M objects
                containsLM = all(ismember([px.L, px.M], types));
                containsDM = all(ismember([px.D, px.M], types));
                if ~(containsLM || containsDM)
                    cleaned(cell_labels == i) = px.E;
                end
            end
            if (plot_process)
                figure(h); subplot(2,3,5); 
                imshow(cleaned, cmap_5mask); title('Cell Filling');
            end
        end
    end
    
    %% remove anything of almost only one cell type (>95%)
    [cell_labels, n] = bwlabel(cleaned ~= px.E);
    for i = 1:n
        object = cleaned(cell_labels == i & cleaned ~= px.U);
        Lpart = sum(object == px.L | object == px.D, 'all')/length(object);
        if Lpart > 0.95 || Lpart < 0.05
            cleaned(cell_labels == i) = px.E;
        end
    end
    % fill in any holes with lumen
    cleaned(imfill(cleaned ~= px.E, 'holes') & cleaned == px.E) = px.U;
    if (plot_process)
        figure(h); subplot(2,3,6); 
        imshow(cleaned, cmap_5mask); title('Tidying');
    end
end