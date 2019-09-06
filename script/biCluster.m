function class = biCluster(gmm, path, thr)
% this function segments the given frame into
% foreground and background clusters.
% by yucheng.l@outlook.com 2018-03-20

%% select keypoints of t th frame and classify
disp('Binary clustering... ');

% compute affinity for each trajectory
path_mean1 = mean(path.global, 3);
path_mean2 = mean(path.local, 4);
list_affinity = cmpAffinity(path_mean1, path_mean2, 'noaugment');

% test GMM model on average points
list_probability = posterior(gmm, list_affinity);

% compute probability of background distribution
[~, gnd_label] = max(sum(gmm.mu.^2, 2));
class = double(list_probability(:, gnd_label) >= thr);
