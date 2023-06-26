% 	20 January 2018
% 	Jennifer L Hu
%	annular.m
%
%	Function that takes a mask and returns masks for outer and inner regions
%	that include the outer and inner 1/nrings of all pixels present.
%	Works on binary and double masks equally. For binary mask just give it
%	a const struct that has pxtype_dmask.E = 0.
%
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function [rings] = annular(mask, order, nrings, const)
	on_mask = (mask ~= const.pxtype_dmask.E); 
    nE = sum(~on_mask, 'all'); n_pixels = sum(on_mask, 'all');
	targets = round((0:nrings) * (n_pixels/nrings));
    
    rings = ones([size(mask), nrings]) * const.pxtype_dmask.E;
    for i=1:nrings
        idx = nE + ((targets(i)+1):targets(i+1));
        % replace indices in slice
        slice = rings(:,:,i); slice(order(idx)) = mask(order(idx));
        rings(:,:,i) = slice;
    end
end