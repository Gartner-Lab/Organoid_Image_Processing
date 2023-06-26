function [avgs] = avg_profiles(profiles)
    % add down the columns
    avgs = [sum(profiles(:,:,1)); ...
            sum(profiles(:,:,2))];
    % normalize by row sums
    avgs = [avgs(1,:)/(sum(avgs(1,:),2)); ...
            avgs(2,:)/(sum(avgs(2,:),2))];
end