function [gmm, idx_class] = estGMM(path, thr)
% this function uses global paths and local paths
% to estimate a GMM for later binary clustering
% by yucheng.l@outlook.com 2018-04-11

%% train a new GMM and predict label class
disp('Training new GMM...');

% data augmentation
[idx_global, idx_local] = meshgrid(1:size(path.global, 3));
path.global = path.global(:, :, :, idx_global(:));
path.local = path.local(:, :, :, idx_local(:));

% compute affinity
affin = cmpAffinity(path.global, path.local, 'augment');
ptnd_c1 = squeeze(affin(:, 1, :));
ptnd_c2 = squeeze(affin(:, 2, :));
ptnd_c3 = squeeze(affin(:, 3, :));
ptnd_c4 = squeeze(affin(:, 4, :));
ptnd_train = [ptnd_c1(:), ptnd_c2(:), ptnd_c3(:), ptnd_c4(:)];

% train GMM
option = statset('Display', 'off', 'MaxIter', 1000, 'TolFun', 1e-6);
gmm = fitgmdist(ptnd_train, 2, ...
    'RegularizationValue', 0.01, 'Options', option);

% predict label class
affin = cmpAffinity(path.global, path.local, 'noaugment');
ptnd_test = squeeze(mean(affin, 3));
[idx_class, ~, prob] = cluster(gmm, ptnd_test);

% remove unreliable predictions
idx_class((prob < 0.5+thr) & (prob > 0.5-thr)) = NaN;