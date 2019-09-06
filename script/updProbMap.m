function prob = updProbMap(prob, idx, lbl, gmm)
% this function updates the background probability
% map via given affinity list.
% by yucheng.l@outlook.com 2018-03-20

%% update probability map and classify
disp('Updating probability map... ');

% find class of background
[~, gnd_label] = max(sum(gmm.mu.^2, 2));

% update probability map
for i = 1:numel(lbl.path)
    % unreliable prediction
    if isnan(idx.class(i))
        continue;
    end
    
    % update trajectories of this label
    mask = (lbl.short == lbl.path(i));
    
    if ~isnan(idx.class(i))
        if idx.class(i) == gnd_label
            prob.back(idx.short(mask, 1)) = prob.back(idx.short(mask, 1))+1;
        else
            prob.front(idx.short(mask, 1)) = prob.front(idx.short(mask, 1))+1;
        end
    end
end