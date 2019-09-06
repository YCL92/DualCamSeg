function trajectory = readTrack(vid_name, buf_size)
% this function reads the tracks file obtained by
% tracking function, only tracks that are visible
% in all frames will be selected.
% by yucheng.l@outlook.com 2017-12-21

%% read track file properties
file_path = ['./', vid_name, '/', vid_name, 'Results/'];
file_name =[vid_name, 'Tracks', num2str(buf_size+1), '.dat'];
file_id = fopen([file_path, file_name]);

if file_id < 0
    error(['Cannot open ', vid_name, '.']);
end

% read all contents
file_content = fscanf(file_id, '%f');

% get track properties
track_total_frame = file_content(1);
track_total_count = (length(file_content)-1)/(track_total_frame*2);
tracker = struct('oRow', {}, 'oCol', {}, 'mRow', {}, 'mCol', {});

% select tracks
for i = 1:track_total_count
    track_offset = (i-1)*track_total_frame*2;
    tracker(i).oCol = file_content(track_offset+2);
    tracker(i).oRow = file_content(track_offset+3);
    
    for j = 2:track_total_frame
        track_offset = (i-1)*track_total_frame*2+(j-1)*2;
        tracker(i).mCol(j-1) = file_content(track_offset+2);
        tracker(i).mRow(j-1) = file_content(track_offset+3);
    end
end

trajectory = tracker';