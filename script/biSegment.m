function [img_label, img_dense, img_bw] = biSegment(prob, img, idx, lbl)
% this function segments the given frame into
% foreground and background fragments.
% by yucheng.l@outlook.com 2018-03-20

%% final classification
disp('Binary segmenting... ');

list_result = zeros(size(idx.short));
list_result(isnan(idx.short)) = NaN;

for label = lbl.path'
    list_index = (lbl.short == label);
    cnt_front = prob.front(idx.short(list_index));
    cnt_back = prob.back(idx.short(list_index));
    prpt = sum(cnt_back)/sum(cnt_back+cnt_front);
    
    if prpt < 0.5
        list_result(list_index) = 1;
	end
end

%% dense segmentation
tmp_map = round(squeeze(img.map));
[tmp_row, tmp_col, tmp_ch] = size(img.raw);
idx_map = sub2ind([tmp_row, tmp_col], tmp_map(:, 2), tmp_map(:, 1));
idx_fore = idx_map(list_result == 1);
idx_nan = idx_map(isnan(lbl.short));

% two-class mask
mask = ones([tmp_row, tmp_col])*NaN;
mask(idx_map) = 0;
mask(idx_fore) = 1;
mask(idx_nan) = NaN;

% bilateral segmentation
% Grid parameters
intensityGridSize = 35;
chromaGridSize = 10;
spatialGridSize = 15;
temporalGridSize = 5;

% Graph Cut Parameters
pairwiseWeight = 1;
unaryWeight = 100000;
temporalWeight = 1e5;
colorWeight = 0.03;
spatialWeight = 0.3;
dimensionWeights = [colorWeight, colorWeight, colorWeight, spatialWeight, spatialWeight, temporalWeight];
gridSize = [intensityGridSize chromaGridSize chromaGridSize spatialGridSize spatialGridSize temporalGridSize];

img_bw = bilateralSpaceSegmentation(img.raw, mask, 1, gridSize, dimensionWeights, unaryWeight, pairwiseWeight);
img_back = zeros(size(img.raw));
img_fore = zeros(size(img.raw));

for ch = 1:tmp_ch
        img_back(:, :, ch) = im2double(img.raw(:, :, ch)).*double(~img_bw)*0.25;
        img_fore(:, :, ch) = im2double(img.raw(:, :, ch)).*double(img_bw)*0.5+double(img_bw)*0.5;
end

img_dense = im2uint8(img_back+img_fore);

% annotate labels of valid keypoints
img_label = markLabel(img.raw, img.map, list_result);