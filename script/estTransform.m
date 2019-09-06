function [path, label] = estTransform(clip, list_label, thr)
% this function estimates similarity transformation
% between the reference frame and each frame given point
% trajectories.
% by yucheng.l@outlook.com 2018-02-27

%% estmate global and local motion
if numel(unique(list_label)) == 1
    disp('Estimating global path... ');
else
    disp('Estimating local paths... ');
end

% initialized parameters
label = unique(list_label);
mask1 = zeros(size(label));
win_size = size(clip, 2);
path = zeros(numel(label), win_size-1, 4, thr.repeat);

for lbl = 1:numel(label)
    % extract trajectories belong to the same label
    mask2 = (list_label == label(lbl));
    
    % no enough valid trajectories
    if sum(mask2(:)) < 2
        mask1(lbl) = 1;
        continue;
    end
    
    % reference frame
    pt2d_img1 = squeeze(clip(mask2, 1, :));
    
    for i = 1:thr.repeat
        for j = 2:win_size
            % new frame
            pt2d_img2 = squeeze(clip(mask2, j, :));
            
            % estimate similarity transform using RANSAC
            t_matrix = estimateGeometricTransform(pt2d_img1, pt2d_img2, 'similarity', 'MaxNumTrials', 6000);
            h_matrix = t_matrix.T';
            
            % scaling
            path(lbl, j-1, 1, i) = sqrt(h_matrix(1, 1)*h_matrix(2, 2)-h_matrix(1, 2)*h_matrix(2, 1));
            
            % translation
            path(lbl, j-1, 2:3, i) = h_matrix(1:2, 3);
            
            % rotation
            h_matrix = h_matrix./path(lbl, j-1, 1, i);
            path(lbl, j-1, 4, i) = asin(-h_matrix(1, 2)*h_matrix(1, 1)+h_matrix(2, 2)*h_matrix(2, 1))/2*(180/pi);
        end
    end
end

% remove void labels & paths
label(logical(mask1)) = [];
path(logical(mask1), :, :, :) = [];