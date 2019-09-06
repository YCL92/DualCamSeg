function [list_front, list_rear] = splitDualCam(vid_name, vid_scale, f_start)
% this function splits the given veideo to
% two independent sub-imag sets.
% by yucheng.l@outlook.com 2017-10-19

%% load raw video file and split to sub-image sets

path_root = ['./', 'dataset'];
path_result = [path_root, '/', vid_name, '/', 'image'];

if ~exist(path_result, 'dir')
    mkdir(path_result);
    fprintf('Spliting input video to sub-image sets... ');
    
    % sub-frame size
    vid_raw = VideoReader([path_root, '/', vid_name, '.mp4']);
    vid_height = vid_raw.Height;
    vid_width = vid_raw.Width;
    
    if vid_height > vid_width
        vid_midpoint = ceil(vid_height/2);
    else
        vid_midpoint = ceil(vid_width/2);
    end
    
    % split video
    index = 1;
    
    for i = 1:f_start
        [~] = readFrame(vid_raw);
    end
    
    while hasFrame(vid_raw)
        f_current = readFrame(vid_raw);
        
        % for HTC bug only
        if hasFrame(vid_raw)
            [~] = readFrame(vid_raw);
        end
        
        % split frame
        if vid_height > vid_width
            f_front = f_current(1:vid_midpoint, 1:vid_width, :);
            f_rear = f_current(vid_midpoint+1:vid_height, 1:vid_width, :);
        else
            f_front = imrotate(f_current(1:vid_height, 1:vid_midpoint, :), -90);
            f_rear = imrotate(f_current(1:vid_height, vid_midpoint+1:vid_width, :), -90);
        end
        
        % pre-processing
        f_front = imresize(f_front, vid_scale);
        f_rear = imresize(f_rear, vid_scale);
        
        % write frame to sub-videos
        imwrite(f_front, [path_result, '/', 'front_', num2str(index, '%03d'), '.png']);
        imwrite(f_rear, [path_result, '/', 'rear_', num2str(index, '%03d'), '.png']);
        
        % update index
        index = index+1;
    end
end

list_front = dir([path_result, '/', 'front*.png']);
list_rear = dir([path_result, '/', 'rear*.png']);
field = {'date', 'bytes', 'isdir', 'datenum'};
list_front = rmfield(list_front, field);
list_rear = rmfield(list_rear, field);