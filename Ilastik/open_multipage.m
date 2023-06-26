%% opens a multipage tif that contains dmasks and reads them out into a matrix
% Set n_z and n_t for the third and fourth dimensions.
% If one is zero it will infer its size from the total number of slices.
function [dmask] = open_multipage(filepath, n_z, n_t)
    [~,bfdata] = evalc('bfopen(filepath)');
    n_s = size(bfdata{1,1},1);
    if (n_z == 0 && n_t > 1)
        n_z = n_s / n_t;
    elseif (n_t == 0 && n_z > 1)
        n_t = n_s / n_z;
    end
    if (n_z > 1 && n_t > 1)
        assert(n_s == n_z * n_t, 'Must have correct number of slices');    
        dmask = zeros([size(bfdata{1,1}{1,1}) n_z n_t]);
        for j = 1:n_z
            for k = 1:n_t
                dmask(:,:,j,k) = bfdata{1,1}{(k-1)*n_z + j,1};
            end
        end
    else
        dmask = zeros([size(bfdata{1,1}{1,1}) n_s]);
        for i = 1:n_s
            dmask(:,:,i) = bfdata{1,1}{i,1};
        end
    end
end