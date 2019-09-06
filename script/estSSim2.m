function path_valid = estSSim2(clip, label)
% this function estimates paths for every valid trajectory
% pair provided by list_neighbor.
% by yucheng.l@outlook.com 2018-04-10

%% estimate similarity transform of each pair
disp('Estimating trajectory paths...');

rad = 16;
path_valid = ones([size(clip, 1), size(clip, 2)-1, 4])*NaN;

for lbl = label.path'
    pt2d_label = clip(label.long == lbl, :, :);  
    pt3d_set(:,1:2) = squeeze(pt2d_label(:, 1, :));
    pt3d_set(:, 3) = 0;
    pt3d_cloud = pointCloud(pt3d_set);
    
    % find a neighbor with given radius
    pt2d_neighbor = zeros(size(pt2d_label));
    
    for ind = 1:size(pt2d_label, 1)
        [pt3d_index, ~] = findNeighborsInRadius(pt3d_cloud, pt3d_set(ind, :), rad, 'Sort', true);
        
        if length(pt3d_index) < 2
            pt2d_neighbor(ind, :, :) = NaN;
            pt2d_label(ind, :, :) = NaN;
        else
            pt2d_neighbor(ind, :, :)= pt2d_label(pt3d_index(end), :, :);
        end
    end
    
    % scaling
    tmp_diff = pt2d_label-pt2d_neighbor;
    tmp_dist = sqrt(sum(tmp_diff.^2, 3));
    tmp_scal = tmp_dist(:, 2:end)./tmp_dist(:, 1);
    
    % rotation
    tmp_numer = sum(tmp_diff(:, 2:end, :).*tmp_diff(:, 1, :), 3);
    tmp_denom = tmp_dist(:, 2:end).*tmp_dist(:, 1);
    tmp_theta = acos(tmp_numer./tmp_denom);
    
    % translation
    tmp_sin = sin(tmp_theta);
    tmp_cos = cos(tmp_theta);
    tmp_sum = pt2d_label+pt2d_neighbor;
    tmp_align(:, :, 1) = tmp_scal.*(tmp_cos.*tmp_sum(:, 1, 1)-tmp_sin.*tmp_sum(:, 1, 2));
    tmp_align(:, :, 2) = tmp_scal.*(tmp_sin.*tmp_sum(:, 1, 1)+tmp_cos.*tmp_sum(:, 1, 2));
    tmp_trans = 0.5*(tmp_sum(:, 2:end, :)-tmp_align);
    
    path_valid(label.long == lbl, :, 1) = tmp_scal;
    path_valid(label.long == lbl, :, 2:3) = tmp_trans;
    path_valid(label.long == lbl, :, 4) = tmp_theta;
    clear pt2d* pt3d* tmp*;
end