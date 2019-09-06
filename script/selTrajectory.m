function [traj_select, list_index] = selTrajectory(traj_raw, f_start, f_end)
% this function selects a clip from original trajectory
% by the given period start-end.
% by yucheng.l@outlook.com 2018-02-11

%% select trajectories that satisfied the given condition
mask = ([traj_raw(:).start] <= f_start & [traj_raw(:).end] >= f_end)';
list_index = find(mask);
obj_select = traj_raw(mask);

% convert to matrix
traj_select = zeros([length(obj_select), f_end-f_start+1, 2]);

for i = 1:length(obj_select)
    % trajectory start frame
    traj_start = obj_select(i).start;
    offset = f_start-traj_start;
    
    for j = 1:f_end-f_start+1
        if j == 1&& traj_start == f_start
            traj_select(i, j, 2) = obj_select(i).oRow;
            traj_select(i, j, 1) = obj_select(i).oCol;
        else
            traj_select(i, j, 2) = obj_select(i).mRow(offset+j-1);
            traj_select(i, j, 1) = obj_select(i).mCol(offset+j-1);
        end
    end
end