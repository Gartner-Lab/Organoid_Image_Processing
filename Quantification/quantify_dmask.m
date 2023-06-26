% 	25 March 2020
% 	Jennifer L Hu
% 	quantify_dmask.m
%	
%	Runs on a segmented mask. Returns a struct with a row of metrics, the 
%	rectangular radial profile, and the LEP fractions of increasing
%	distance from the ECM. Defaults to no rps.
%       [metric_row, rps, bounds, LEPfracs]
%	Double check the result against the named metrics in constants.m.
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function quantification = quantify_dmask(dmask, varargin)
    const = []; rps = []; return_rps = false;
    if nargin > 1
        for i = 1:(nargin-1)
            if (isstruct(varargin{i}))
                const = varargin{i};
            else
                return_rps = strcmp(varargin{i}, 'rps');
            end
        end
    end
    if return_rps, rps = zeros(360, round(size(dmask,2)/2)); end
    if (isempty(const))
        warning('No constants struct provided in quantify_dmask.');
        [const, ~] = constants();
    end
    %% Generate masks for comparisons and quantifications
    M = dmask == const.pxtype_dmask.M;
    L = dmask == const.pxtype_dmask.L;
    both = M | L;
    if length(unique(both)) == 1
        % no cell pixels! or all cell pixels!
        fprintf('0'); % this will appear instead of '.' as a warning
        quantification = struct('metric_row', NaN(1, const.n_metrics-1), ...
            'bounds', '', 'rps', rps, 'LEPfracs', []);
        return;
    end
    has_MEP = any(M,'all'); has_LEP = any(L,'all'); 
    has_both = has_MEP && has_LEP;

    %% Basic region stats
    % only works for discontinuous regions if uint8.
    Mstats = regionprops(uint8(M),{'Centroid','Solidity','Area'});
    Lstats = regionprops(uint8(L),{'Centroid','Solidity','Area'});
    Tstats = regionprops(uint8(both),{'Area','Circularity',...
        'EquivDiameter','BoundingBox','Perimeter'});
    T_area = Tstats.Area; T_circ = Tstats.Circularity; EqD = Tstats.EquivDiameter;
    compactness = NaN(1,5);
    if (has_MEP)
        compactness(1) = Mstats.Solidity;
    else
        fracM = 0;
    end
    if (has_LEP)
        compactness(2) = Lstats.Solidity;
    else
        fracM = 1;
    end
    if has_both
        M_area = Mstats.Area; L_area = Lstats.Area; fracM = M_area/T_area;
    end
    
    %% Exit early if only one cell type
    if ~has_both
        if return_rps
            rps(:,:) = (has_LEP*const.pxtype_dmask.L + has_MEP*const.pxtype_dmask.M);
        end
        metric_row = [fracM, T_area, T_circ, EqD, compactness];
        metric_row = [metric_row, ...
            NaN(1, const.n_metrics - length(metric_row) - 1)];
        quantification = struct('metric_row', metric_row, ... 
            'rps', rps, 'LEPfracs', [1, 2;1-fracM, 1-fracM], ...
            'bounds', Tstats.BoundingBox);
        return
    end
    
    %% Add blob size and boundary ratio as compactness measures
    % cut off extra space
    support = imcrop(dmask, Tstats.BoundingBox); [nr,nc] = size(support);
    fourier = fftshift(fft2(-1*(support == const.pxtype_dmask.M) + (support == const.pxtype_dmask.L), ...
        2^nextpow2(nr), 2^nextpow2(nc)));
    [k1, k2] = meshgrid((1:(2^nextpow2(nc)))-2^(nextpow2(nc)-1)-.5, ...
        (1:(2^nextpow2(nr)))-2^(nextpow2(nr)-1)-.5);
    k = sqrt(k1.^2 + k2.^2); % magnitude
    % inverse weighted avg frequency = avg wavelength
    blobsize = sum(abs(fourier).^2,'all') / sum(abs(fourier).^2 .* k,'all');
    compactness(3) = blobsize * (nr+nc)/2; % wavelength is 1 for full image width/height; convert to px
    % Heterotypic score (normalized to area)
    inbetween = sum((L & bwdist(M) == 1) | (M & bwdist(L) == 1), 'all')/2;
    heterotypic_score = inbetween/T_area;
    compactness(4) = inbetween; compactness(5) = heterotypic_score;
    
    %% Distances with bwdist
    % edge - any pixel within 1 of an ECM pixel
    organoid_edge = dmask(bwdist(~imfill(both, 'holes'), 'chessboard') == 1);
    % Euclidean for more precise tasks
    edge_dists = bwdist(~imfill(both, 'holes'), 'euclidean');
    stagger = edge_dists + rand(size(both)) - 0.5;
    [~, order] = sort(stagger(:)); % need to linearize for order to work
    % the first element of order is the index of the smallest in staggered
    
	%% Correctness: on a scale from unideal to ideal [~0,1]
    ideal = idealize_dmask(dmask, order, const.pxtype_dmask.L, const.pxtype_dmask.M, const.pxtype_dmask.E);
    unideal = idealize_dmask(dmask, order, const.pxtype_dmask.M, const.pxtype_dmask.L, const.pxtype_dmask.E);
    correct = sum(dmask == ideal & both,'all');
    min_correct = sum(unideal == ideal & both,'all');
    correctness = (correct - min_correct)/(T_area - min_correct);

    %% Intercentroid distance (ICD): normalized to equivalent diameter
    % identify LEP and MEP centroids
    Mcx = Mstats.Centroid(1); Mcy = Mstats.Centroid(2);
    Lcx = Lstats.Centroid(1); Lcy = Lstats.Centroid(2);
    % inter-centroid distance
    ICD = sqrt((Mcx-Lcx)^2+(Mcy-Lcy)^2);
    % normalize ICD by equivalent diameter
    ICD = ICD/EqD;
    
    %% Region fractions: also compare to theoretical max
    rings = annular(dmask, order, 3, const);
    edge_area = length(organoid_edge);
    O_area = sum(rings(:,:,1) ~= const.pxtype_dmask.E,'all');
    I_area = sum(rings(:,:,3) ~= const.pxtype_dmask.E,'all');
    % outer, inner, edge
    if L_area >= O_area, max_outer_L = 1; else, max_outer_L = L_area / O_area; end
    if L_area >= I_area, max_inner_L = 1; else, max_inner_L = L_area / I_area; end
    outer_L = sum(rings(:,:,1) == const.pxtype_dmask.L,'all') / O_area;
    edge_L = sum(organoid_edge == const.pxtype_dmask.L,'all') / edge_area;
    inner_L = sum(rings(:,:,3) == const.pxtype_dmask.L,'all') / I_area;
    % Rim is the outer 4 pixels ~ 2 µm
    rim = (edge_dists > 0 & edge_dists < 5); 
    rim_L = sum(rim & L,'all') / sum(rim, 'all');
    region_fractions = [edge_L, rim_L, ...
                outer_L, outer_L / max_outer_L, ...
                inner_L, inner_L / max_inner_L];
            
    %% Radial LEP fractions by edge distance
    edge_dists_round = round(edge_dists); round_dists = 1:max(unique(edge_dists_round));
    LEPfracs = [round_dists; arrayfun(@(x) ...
        (sum(dmask(edge_dists_round == x) == const.pxtype_dmask.L, 'all') /...
        sum(edge_dists_round == x, 'all')), round_dists)];
    
    %% compile metric row
    metric_row = [fracM, T_area, T_circ, EqD, compactness, ...
    	region_fractions, correctness, ICD];
    
    %% Averaged radial profiles (rps)
    if return_rps
        stats = regionprops(uint8(both), 'Centroid');
        cx = stats.Centroid(1); cy = stats.Centroid(2);
        rps = rprofiles(dmask, cx, cy, const.pxtype_dmask.E);
    end
    
    %% stuff into a struct to return
    quantification = struct( ...
        'metric_row', metric_row, ...
        'rps', rps, 'bounds', Tstats.BoundingBox, ...
        'LEPfracs', LEPfracs);
    fprintf('.');
end