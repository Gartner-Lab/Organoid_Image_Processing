% 	25 March 2020
% 	Jennifer L Hu
% 	quantify_dmask.m
%	
%	Runs on an RGB image. Returns a row vector of metrics, a row of 
%	boundary pixels, and a rectangular radial profile.
%   [metric_row, rps, organoid_edge, Tstats.BoundingBox]
%	Double check the result against the named metrics in constants.m.
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function quantification = quantify_tissuesection(mask, varargin)
    const = [];
    if nargin > 1
        for i = 1:(nargin-1)
            if (isstruct(varargin{i}))
                const = varargin{i};
            end
        end
    end
    if (isempty(const))
        warning('No constants struct provided in quantify_dmask.');
        [const, ~] = constants();
    end
    %% Generate masks for comparisons and quantifications
    M = mask == const.px.M;
    L = mask == const.px.L;
    LD = L | mask == const.px.D;
    has_MEP = any(M,'all'); has_LEP = any(L,'all'); 
    if (~has_MEP && ~has_LEP)
        % no cell pixels!
        warning('Empty image.');
        quantification = struct('metric_row', NaN(1, const.n_metrics), ...
            'bounds', '');
        return;
    end
    has_both = has_MEP && has_LEP; cells = M | LD;    

    %% Basic region stats
    % only works for discontinuous regions if uint8.
    Mstats = regionprops(uint8(M),{'Centroid','Solidity','Area'});
    Lstats = regionprops(uint8(L),{'Centroid','Solidity','Area'});
    Tstats = regionprops(uint8(cells),{'Area','Circularity',...
        'EquivDiameter','BoundingBox'});
    T_area = Tstats.Area; T_circ = Tstats.Circularity; EqD = Tstats.EquivDiameter;
    basics = NaN(1,4);
    if (has_MEP)
        CC = bwconncomp(M);
        basics(1) = CC.NumObjects;
        basics(3) = Mstats.Solidity;
    else
        fracM = 0;
    end
    if (has_LEP)
        CC = bwconncomp(L);
        basics(2) = CC.NumObjects;
        basics(4) = Lstats.Solidity;
    else
        fracM = 1;
    end
    if has_both
        M_area = Mstats.Area; fracM = M_area/T_area;
    end
    
    %% Exit early if only one cell type
    if ~has_both
        metric_row = [fracM, T_area, T_circ, EqD, basics, ...
            NaN(1, const.n_metrics - 5 - length(basics))];
        quantification = struct('metric_row', metric_row, ...
            'bounds', Tstats.BoundingBox);
        return
    end
    
    %% Inner and outer regions by Euclidean distance to ECM
    edge_distances = bwdist(~imfill(cells, 'holes'), 'euclidean');
    outerbounds = [1, (1:10)/const.psize]; innerbound = 15/const.psize;
    OMFs = zeros(size(outerbounds));
    for i = 1:length(outerbounds)
        outerbound = outerbounds(i);
        outer = (edge_distances <= outerbound) & cells; O_area = sum(outer, 'all');
        OMFs(i) = sum(mask(outer) == const.px.M, 'all') / O_area;
    end
    inner = (edge_distances >= innerbound) & cells; I_area = sum(inner, 'all');
    IMF = sum(mask(inner) == const.px.M,'all') / I_area;
    region_fractions = [OMFs, IMF];
    %% compile metric row
    metric_row = [fracM, T_area, T_circ, EqD, basics, region_fractions];
    
    % stuff into a struct to return
    quantification = struct( ...
        'metric_row', metric_row, ...
        'bounds', Tstats.BoundingBox...
        );
    fprintf('.');
end