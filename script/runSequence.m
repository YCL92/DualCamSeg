function runSequence(file, scale, win, thr, str)
% this function runs a demo to the given video.

%% pre-processing
fprintf("\n===========================\n");

disp(['Processing video ', file, ': ']);

% split front & rear videos
[img.list_front, img.list_rear] = splitDualCam(file, scale, str);

% compute bidirectional optical flows
flow.front = biDirLDOF(img.list_front, 'front');
flow.rear = biDirLDOF(img.list_rear, 'rear');

% compute trajectories for front & rear cameras
if ~exist(['./dataset/', file, '/', 'trajectory.mat'], 'file')
    traj.front = ptTracker(img.list_front, flow.front, 8);
    traj.rear = ptTracker(img.list_rear, flow.rear, 8);
    save(['./dataset/', file, '/', 'trajectory.mat'], 'traj');
else
    load(['./dataset/', file, '/', 'trajectory.mat']);
end

% make folder for result
dir_result = ['./dataset/', file, '/', 'result'];
if ~exist(dir_result, 'dir')
    mkdir(dir_result);
end

clear flow;

%% main program
img.raw = imread([img.list_front(1).folder, '/', img.list_front(1).name]);
mask = zeros(size(img.raw, 1), size(img.raw, 2), length(img.list_front)-win.long+win.short);
prob.front = zeros(length(traj.front), 1);
prob.back = zeros(length(traj.front), 1);

for t = 1:length(img.list_front)-win.long
    fprintf("\n################################\n");
    disp(['Processing frame #', num2str(t), ':']);
    
    % load frame
    img.raw = imread([img.list_front(t+win.short).folder, '/', img.list_front(t+win.short).name]);
    
    % select a short clip from front camera
    [clip.front, idx.short] = selTrajectory(traj.front, t, t+win.short*2);
    
    % compute 3-distance and label undirected graph
    lbl.short = lblGraph(clip.front, thr.graph, thr.label);
    img.map = squeeze(clip.front(:, win.short+1, :));
    img.label = markLabel(img.raw, img.map, lbl.short);
    
    % select a long clip from each camera
    [clip.front, idx.long] = selTrajectory(traj.front, t, t+win.long-1);
    [clip.rear, ~] = selTrajectory(traj.rear, t, t+win.long-1);
    [~, index] = ismember(idx.long, idx.short);
    lbl.long = lbl.short(index);
    clear index;
    
    % estimate global & local path
    [path.global, ~] = estTransform(clip.rear, ones([size(clip.rear, 1), 1]), thr);
    [path.local, lbl.path] = estTransform(clip.front, lbl.long, thr);
    clear clip*;
    
    try
        % estimate GMM model
        [gmm, idx.class] = estGMM(path, thr.class);
        clear path;
        
        % update probability map
        prob = updProbMap(prob, idx, lbl, gmm);
        clear gmm;
    catch
        warning(['No enough points visible whitin ', num2str(win.long), ', skip to the next.']);
    end
    
    % dense binary segmentation
    [img.sparse, img.dense, img_bw] = biSegment(prob, img, idx, lbl);
    clear idx lbl;
    
    % save result
    img_result = [img.label, img.sparse, img.dense];
    imwrite(img_result, [dir_result, '/', 'result_', num2str(t, '%03d'), '.png']);
    mask(:, :, t+win.short) = img_bw;
end

save([dir_result, '/', file, '.mat'], 'mask');