function list_label = lblGraph(clip, thr_graph, thr_label)
% this function creates a undirected graph for input
% trajectories based on given threshold and assigns
% a label for each node.
% by yucheng.l@outlook.com 2018-01-03

%% find connected components via 3-distance
% compute 3-distance
[list_dist, list_near] = cmp3Distance(clip);

fprintf('Labeling trajectory... ');

inlier = (list_dist < thr_graph);
node = 1:length(list_near);
edge12 = [node(inlier); list_near(inlier, 1)'];
edge23 = [list_near(inlier, 1)'; list_near(inlier, 2)'];
edge13 = [list_near(inlier, 2)'; node(inlier)];
edge_all = [edge12, edge23, edge13, [node; node]];

% remove duplicate edges
edge_list = unique(sort(edge_all, 1)', 'rows');

% assign labels to inliers
udir_graph = graph(edge_list(:, 1), edge_list(:, 2));

% find connected components
list_label = conncomp(udir_graph)';
tbl = tabulate(list_label);
mask = (tbl(:, 2) <= thr_label);
tbl_outlier = tbl(mask, 1);

for index = 1:numel(tbl_outlier)
    label = tbl_outlier(index);
    list_label(list_label == label) = NaN;
end

disp([num2str(length(list_label)), ' labeled.']);