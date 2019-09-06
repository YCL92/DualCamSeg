% DEMO program
% Uncomment line 21-24 for different motions
% by yucheng.l@outlook.com 2018-01-29

%% initialization
clear; clc; 

addpath(genpath('script'));
addpath(genpath('thirdParty'));

% user defined parameters
scale = 0.4;
win.long = 10;
thr.graph = 3;
thr.label = 6;
thr.repeat = 15;
thr.class = 0.35;

%% find all videos and run sequence
list_vid = dir('./dataset/vid*');
list_motion = [6, 8, 9, 10, 11, 15]; win.short = 1;   % win.long >= 3
% list_motion = [12, 7, 1, 17, 13]; win.short = 2;  % win.long >= 5
% list_motion = [2, 4, 19, 14, 16]; win.short = 3;    % win.long >=7
% list_motion = [18, 3, 20, 5]; win.short = 4;    % win.long >= 9

for index = 1:length(list_motion)
    tmp_name = list_vid(list_motion(index)).name;
    tmp_split = strsplit(tmp_name, '.');
    file = cell2mat(tmp_split(1));
    runSequence(file, scale, win, thr, 1);
end