function [despeckled] = despeckle(img)
    despeckled = img;
    for i=1:2
        I = despeckled(:,:,i);
        [~,L,N,~] = bwboundaries(I,8,'noholes');
        % only fix if more than one region
        if N == 1
            continue
        end
        stats = regionprops(L,'Area');
        for j=1:N
            % if region is small
            if stats(j).Area < 100
                o = mod(i,2)+1;
                other = despeckled(:,:,o);
                I(L == j) = 0;
                other(L == j) = 1;
                despeckled(:,:,i) = I;
                despeckled(:,:,o) = other;
            end
        end
    end
end