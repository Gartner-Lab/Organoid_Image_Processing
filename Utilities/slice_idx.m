function [idx] = slice_idx(z, ch, nch)
    % slices are stored in one long column cycling through channels.
    idx = (z-1)*nch + ch;
end