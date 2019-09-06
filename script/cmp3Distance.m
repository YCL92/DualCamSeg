function [list_dist, list_near] = cmp3Distance(clip)
% this function computes the 3-distance of each
% trajectory given with two of its nearest neighbours,
% the first frame is chosen as the reference.
% by yucheng.l@outlook.com 2017-12-28

%% compute 3-disnatnce for every trajectory
disp('Computing 3-distance... ');

[traj_size, buf_size, ~] = size(clip);
list_dist = zeros(traj_size, 1);
list_near = zeros(traj_size, 2);
pnt_set = squeeze(clip(:, 1, :));
pnt_set(:, 3) = 0;
pnt_cloud = pointCloud(pnt_set);
d_t = zeros(buf_size-1, 1);
clear pnt_set;

for i = 1:traj_size
    % find nearst points
    [pnt_index, ~] = findNearestNeighbors(pnt_cloud, pnt_cloud.Location(i, :), 3);
    
    % compute point pair motion
    for j = 1:buf_size-1
        pnt_p1 = [squeeze(clip(pnt_index(1), 1, :)), squeeze(clip(pnt_index(1), j+1, :))];
        pnt_p2 = [squeeze(clip(pnt_index(2), 1, :)), squeeze(clip(pnt_index(2), j+1, :))];
        pnt_p3 = [squeeze(clip(pnt_index(3), 1, :)), squeeze(clip(pnt_index(3), j+1, :))];
        
        % scaling
        t_s12 = norm(pnt_p1(:, 2)-pnt_p2(:, 2))/norm(pnt_p1(:, 1)-pnt_p2(:, 1));
        t_s13 = norm(pnt_p1(:, 2)-pnt_p3(:, 2))/norm(pnt_p1(:, 1)-pnt_p3(:, 1));
        t_s23 = norm(pnt_p2(:, 2)-pnt_p3(:, 2))/norm(pnt_p2(:, 1)-pnt_p3(:, 1));
        
        % rotation
        t_r12 = acos(((pnt_p1(:, 2)-pnt_p2(:, 2))'*(pnt_p1(:, 1)-pnt_p2(:, 1)))/...
            (norm(pnt_p1(:, 2)-pnt_p2(:, 2))*norm(pnt_p1(:, 1)-pnt_p2(:, 1))));
        t_r13 = acos(((pnt_p1(:, 2)-pnt_p3(:, 2))'*(pnt_p1(:, 1)-pnt_p3(:, 1)))/...
            (norm(pnt_p1(:, 2)-pnt_p3(:, 2))*norm(pnt_p1(:, 1)-pnt_p3(:, 1))));
        t_r23 = acos(((pnt_p2(:, 2)-pnt_p3(:, 2))'*(pnt_p2(:, 1)-pnt_p3(:, 1)))/...
            (norm(pnt_p2(:, 2)-pnt_p3(:, 2))*norm(pnt_p2(:, 1)-pnt_p3(:, 1))));
        t_r12_matrix = [cos(t_r12), -sin(t_r12); sin(t_r12), cos(t_r12)];
        t_r13_matrix = [cos(t_r13), -sin(t_r13); sin(t_r13), cos(t_r13)];
        t_r23_matrix = [cos(t_r23), -sin(t_r23); sin(t_r23), cos(t_r23)];
        
        % translation
        t_t12 = 0.5*((pnt_p1(:, 2)+pnt_p2(:, 2))-...
            t_s12*t_r12_matrix*(pnt_p1(:, 1)+pnt_p2(:, 1)));
        t_t13 = 0.5*((pnt_p1(:, 2)+pnt_p3(:, 2))-...
            t_s13*t_r13_matrix*(pnt_p1(:, 1)+pnt_p3(:, 1)));
        t_t23 = 0.5*((pnt_p2(:, 2)+pnt_p3(:, 2))-...
            t_s23*t_r23_matrix*(pnt_p2(:, 1)+pnt_p3(:, 1)));
        
        % l2 distance
        d_l2_p12 = norm(t_s12*t_r12_matrix*pnt_p3(:, 1)+t_t12-pnt_p3(:, 2));
        d_l2_p13 = norm(t_s13*t_r13_matrix*pnt_p2(:, 1)+t_t13-pnt_p2(:, 2));
        d_l2_p23 = norm(t_s23*t_r23_matrix*pnt_p1(:, 1)+t_t23-pnt_p1(:, 2));
        
        % d-ratio
        d_ratio_p12 = (0.5*(norm(pnt_p1(:, 1)-pnt_p2(:, 1))/norm(pnt_p1(:, 1)-pnt_p3(:, 1))+...
            norm(pnt_p1(:, 1)-pnt_p2(:, 1))/norm(pnt_p2(:, 1)-pnt_p3(:, 1)))).^0.25;
        d_ratio_p13 = (0.5*(norm(pnt_p1(:, 1)-pnt_p3(:, 1))/norm(pnt_p1(:, 1)-pnt_p2(:, 1))+...
            norm(pnt_p1(:, 1)-pnt_p3(:, 1))/norm(pnt_p3(:, 1)-pnt_p2(:, 1)))).^0.25;
        d_ratio_p23 = (0.5*(norm(pnt_p2(:, 1)-pnt_p3(:, 1))/norm(pnt_p2(:, 1)-pnt_p1(:, 1))+...
            norm(pnt_p2(:, 1)-pnt_p3(:, 1))/norm(pnt_p3(:, 1)-pnt_p1(:, 1)))).^0.25;
        
        % d-t
        d_t(j) = max([d_ratio_p12*d_l2_p12, d_ratio_p13*d_l2_p13, d_ratio_p23*d_l2_p23]);
    end
    
    % assign to point
    list_dist(i) = max(d_t);
    list_near(i, :) = pnt_index(2:3);
end