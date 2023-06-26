% Cleans up a [0 1 2] image by filling in lumens and specks and smoothing
function [cleaned] = clean_masks(img)
    % max size of allowed speck in pixels
    max_speck = 50;
    cleaned = img;
    % run filling twice to clear any trouble spots
    for i = 1:2
        % fill in holes/lumens
        [~, lumens] = bwboundaries(imfill(cleaned > 0,8,'holes') & ...
                      cleaned == 0);
        reassignments = fill_regions(lumens, cleaned);
        cleaned(lumens > 0) = reassignments(lumens > 0);
        % fill in small regions, MEPs then LEPs
        Mspecks = bwareafilt(cleaned == 1, [0, max_speck]);
        [~, Mspecks] = bwboundaries(Mspecks);
        reassignments = fill_regions(Mspecks, cleaned);
        cleaned(Mspecks > 0) = reassignments(Mspecks > 0);
        Lspecks = bwareafilt(cleaned == 2, [0, max_speck]);
        [~, Lspecks] = bwboundaries(Lspecks);
        reassignments = fill_regions(Lspecks, cleaned);
        cleaned(Lspecks > 0) = reassignments(Lspecks > 0);
    end
    % smoothen borders of regions
    sMEP = uint8(smoothen(cleaned == 1));
    sLEP = uint8(smoothen(cleaned == 2));
    dpos = sMEP & sLEP;
    holes = imfill(sMEP | sLEP,8,'holes') & ~(sMEP | sLEP);
    % fill double-positive/hole regions with what was there before smoothing
    [~, replace] = bwboundaries(dpos | holes);
    scleaned = sMEP + 2*sLEP;
    scleaned(replace > 0) = cleaned(replace > 0);
    cleaned = scleaned;
end