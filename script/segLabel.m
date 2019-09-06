function list_segment = segLabel(list_label, list_affinity, thr_segment)
% this function clusters labels to either foreground
% or background by their affinity with background
% motion model.
% by yucheng.l@outlook.com 2018-02-01

%% find labels with small variance as many as possible
list_segment = zeros(size(list_label))*NaN;
fprintf('Clustering labels... ');

% test #1
var_previous = 0;
[pt3d_set, pt3d_index] = removeInvalidPoints(pointCloud(list_affinity));

% find label nearest to origin
[pt3d_near, ~] = findNearestNeighbors(pt3d_set, [0, 0, 0] , 1);
pt3d_origin = pt3d_set.Location(pt3d_near, :);

for i = 1:length(pt3d_index)
    [pt3d_near, ~] = findNearestNeighbors(pt3d_set, pt3d_origin, i);
    
    % compute Euclidean distance
    list_distance = sqrt(sum(pt3d_set.Location(pt3d_near, :).^2, 2));
    var_current = var(list_distance);
    disp(var_current);
    
    % new origin
    pt3d_origin = mean(pt3d_set.Location(pt3d_near, :), 1);
    
    if i > 2 && abs(var_current-var_previous) > thr_segment
        break;
    else
        var_previous = var_current;
    end
end

for j = 1:i-1
    list_segment(list_label == pt3d_index(pt3d_near(j))) = 1;
end

disp('Done.');