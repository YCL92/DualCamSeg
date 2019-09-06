function lbl_global = updGlobalLabel(lbl_global, list_index, list_label)
% this function back-propagates the current label list
% to global label list so that trajectories already labeled
% before will not be missed even their durations are
% shorter than the current frame.
% by yucheng.l@outlook.com 2018-04-04

%% back propagation
% global label update
edge_global = [];
lbl_index = unique(lbl_global);

for label = lbl_index'
    if label == 0
        continue;
    end
    
    % global index
    tmp_index = find(lbl_global == label);
    tmp_edge = [tmp_index, circshift(tmp_index, 1)];
    edge_global = [edge_global; tmp_edge];
end
clear tmp*;

% local label back propagation
lbl_index = unique(list_label);

for label = lbl_index'
    % local index
    tmp_index = list_index(list_label == label);
    tmp_edge = [tmp_index, circshift(tmp_index, 1)];
    edge_global = [edge_global; tmp_edge];
end

% remove duplicate edges
edge_list = unique(sort(edge_global, 2), 'rows');

% assign labels to inliers
udir_graph = graph(edge_list(:, 1), edge_list(:, 2));

% find connected components
tmp_label = conncomp(udir_graph,'OutputForm', 'cell')';

% update global labels
for label = 1:length(tmp_label)
    tmp_index = cell2mat(tmp_label(label));
    
    % skip single node
    if numel(tmp_index) < 2
        continue;
    end
    
    lbl_global(tmp_index) = label;
end