function [h_matrix] = estHomography(input1, input2)
% this function estimates homography matrix
% between two images using M-estimator SAmple
% Consensus (MSAC) algorithm.
% by yucheng.l@outlook.com 2018-01-15

%% find matching point pairs
if size(input1, 3) == 3 && size(input2, 3) == 3
    img1 = rgb2gray(input1);
    img2 = rgb2gray(input2);
    
    % SURF features
    pt2d_img1 = detectSURFFeatures(img1);
    pt2d_img2 = detectSURFFeatures(img2);
    
    [ftr_img1, valid_img1] = extractFeatures(img1, pt2d_img1);
    [ftr_img2, valid_img2] = extractFeatures(img2, pt2d_img2);
    
    % match features
    pair_index = matchFeatures(ftr_img1, ftr_img2);
    pt2d_matched1 = valid_img1(pair_index(:, 1));
    pt2d_matched2 = valid_img2(pair_index(:, 2));
    
    % estimate homography matrix using RANSAC
    [tform, ~, ~] = estimateGeometricTransform(pt2d_matched1, pt2d_matched2, 'similarity', ...
        'MaxNumTrials', 5000, 'Confidence', 99.99, 'MaxDistance', 1.5);
    h_matrix = tform.T';
    
elseif size(input1, 2) == 2 && size(input2, 2) == 2
    [tform, ~, ~] = estimateGeometricTransform(input1, input2, 'similarity', ...
        'MaxNumTrials', 5000, 'Confidence', 99.99, 'MaxDistance', 1.5);
    h_matrix = tform.T';
else
    error('Input matrix should be either color image or Nx2 coordinates.');
end

function [pt2d_normalized, t_matrix] = normalize(pt2d)
x_bar = mean(pt2d(:, 1));
y_bar = mean(pt2d(:, 2));

s = sqrt(2)/mean(sqrt((pt2d(:, 1)-x_bar).^2+(pt2d(:, 2)-y_bar).^2));
tx = -s*x_bar;
ty = -s*y_bar;

t_matrix = [s, 0, tx; 0, s, ty; 0, 0, 1];
pt2d_homo = pt2d';
pt2d_homo(3, :) = 1;
pt2d_normalized = (t_matrix*pt2d_homo)';