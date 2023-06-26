% Takes any 2D image ([0 1 2] or grayscale) and returns 360 radial
% profiles as a 2D matrix of size [360xncol/2].
function [rps] = rprofiles(img, cx, cy, E)
	[nrow, ncol] = size(img); ncolout = round(ncol/2);
    rps = zeros(360, ncolout); % initalize with zeros
    if img(round(cy+1),round(cx+1)) == 0 % centroid is outside of organoid
        return;
    end

    %% Use trigonometry to find x and y coordinate at the edge for each angle
    dx = ncol - cx; dy = nrow - cy; sx = cx-1; sy = cy-1; % distance is -1
     % add a half turn to the last two for full coverage
    corners = round(atan([-sx/sy, dx/sy, -dx/dy, sx/dy])*180/pi + [0 0 180 180]);
    nd = 360; angles = (1:nd)+corners(1); slopes = tan(angles/180*pi);
    quad = [corners(2)-corners(1), corners(3)-corners(2), ...
        corners(4)-corners(3), corners(1)-corners(4)+360]-1;
    corneridx = cumsum(quad+1); % index into angles array
    coords = ones(2,nd); % initialize coordinates with image edges
    coords(1,corneridx(1):corneridx(2)) = ncol;
    coords(2,corneridx(2):corneridx(3)) = nrow;
    coords(1,1:corneridx(1)-1)                  = cx+sy.*slopes(1:corneridx(1)-1);
    coords(2,(corneridx(1)+1):(corneridx(2)-1)) = cy-dx./slopes((corneridx(1)+1):(corneridx(2)-1));
    coords(1,(corneridx(2)+1):(corneridx(3)-1)) = cx-dy.*slopes((corneridx(2)+1):(corneridx(3)-1));
    coords(2,(corneridx(3)+1):(corneridx(4)-1)) = cy+sx./slopes((corneridx(3)+1):(corneridx(4)-1));
    assert(~any(coords < 1 | [coords(1,:) > ncol; coords(2,:) > nrow], 'all'), 'Out of range.')
    
    %% Get profile from line between cx,cy and x2,y2
    for i = 1:nd
        line = improfile(img, [cx,coords(1,i)], [cy,coords(2,i)]);
        % keep up to the first ECM value
        keepto = find(line == E, 1)-1; 
        if ~isempty(keepto), line = line(1:keepto); end
        line = imresize(line, [1 ncolout]);
        rps(i,:) = line;
    end

end