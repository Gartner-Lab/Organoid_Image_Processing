function [dmask] = open_ilastik_p(path, const)
    % open image
    [~, bfdata] = evalc('bfopen(path)');
    img_size = size(bfdata{1,1}{1,1});
    n_pxtypes = numel(fieldnames(const.pxtype_ilastik));
    img_probabilities = zeros([img_size, n_pxtypes]);
    for k = 1:n_pxtypes
        img_probabilities(:,:,k) = bfdata{1,1}{k,1};
    end
    % convert probabilities to segmentation
    dmask = ilastikp2dmask(img_probabilities, const);
end