function trajectory = ptTracker(list_img, list_flow, smp_gap)
% this function tracks point trajectories in the image
% sequence given with a sampling smp_gap.
% The script in c++ is originally from T. Brox. It has
% been slightly modified to only output trajectories
% of points that are visible in all frames.
% re-written by yucheng.l@outlook.com 2017-12-21

%% main script
if nargin < 3
    error('No enough inputs.');
end

% initial trajectory structure
fprintf('Tracking trajectory... ');
tracker = struct('start', {}, 'end', {}, 'oRow', {}, 'oCol', {}, 'mRow', {}, 'mCol', {}, 'stopped', {});

% % load first image
f_start = 1;
img = imread([list_img(f_start).folder, '/', list_img(f_start).name]);
[height, width, ~] = size(img);

for t = 1:length(list_flow)
    % load image
    img = imread([list_img(t).folder, '/', list_img(t).name]);
    img = smoothFilter(double(img), 0.8);
    
    % mark areas sufficiently covered tracks
    area_covered = zeros(height, width);
    
    if t > f_start
        for i = 1:length(tracker)
            if tracker(i).stopped == false
                mCol_end = round(tracker(i).mCol(end));
                mRow_end = round(tracker(i).mRow(end));
                area_covered(mRow_end, mCol_end) = 1;
            end
        end
        area_covered = bwdist(area_covered);
    end
    
    % set up new tracking points in uncovered areas
    area_corner = cmpCorner(img, 10);
    area_corner_average = mean(area_corner(:));
    
    for aRow = 4:smp_gap:height-4
        for aCol = 4:smp_gap:width-4
            if area_covered(aRow, aCol) < smp_gap && t > f_start
                continue;
            end
            
            area_boundary = exp(-0.1*min([aRow, aCol, width-aCol, height-aRow]));
            
            if area_corner(aRow, aCol) < area_corner_average*(0.1+area_boundary)
                continue;
            end
            
            if area_corner(aRow, aCol) < 1.0+area_boundary
                continue;
            end
            
            tracker(end+1).start = t;
            tracker(end).end = t;
            tracker(end).oCol = aCol;
            tracker(end).oRow = aRow;
            tracker(end).stopped = false;
        end
    end
    
    % read bidirectional LDOF from files
    file_flo1 = [list_flow(t, 1).folder, '/', list_flow(t, 1).name];
    file_flo2 = [list_flow(t, 2).folder, '/', list_flow(t, 2).name];
    flow_fore = readFlowFile(file_flo1);
    flow_back = readFlowFile(file_flo2);
    [flow_height, flow_width, ~] = size(flow_fore);
    
    % check consistencCol of forward flow via backward flow
    [dx(:, :, 1), dy(:, :, 1)] = imgradientxy(flow_fore(:, :, 1), 'central');
    [dx(:, :, 2), dy(:, :, 2)] = imgradientxy(flow_fore(:, :, 2), 'central');
    
    area_motion = sum(dx.^2+dy.^2, 3);
    area_valid = ones(height, width);
    flow_fore_sum = sum(flow_fore.^2, 3);
    mask = (area_motion > 0.01*flow_fore_sum+0.002);
    area_valid(mask) = 0;
    
    [aCol, aRow] = meshgrid(1:flow_width, 1:flow_height);
    bCol = aCol+flow_fore(:, :, 1);
    bRow = aRow+flow_fore(:, :, 2);
    cCol = floor(bCol);
    cRow = floor(bRow);
    mask = ((cCol < 1) | (cRow < 1) | (cCol >= width) | (cRow >= height));
    area_valid(mask) = 0;
    alpha = bRow-cRow;
    beta = bCol-cCol;
    
    cCol(mask) = 1;
    cRow(mask) = 1;
    idx_noshift = sub2ind([flow_height, flow_width], cRow, cCol);
    idx_shift_x = sub2ind([flow_height, flow_width], cRow, cCol+1);
    idx_shift_y = sub2ind([flow_height, flow_width], cRow+1, cCol);
    idx_shift_xy = sub2ind([flow_height, flow_width], cRow+1, cCol+1);
    
    flow_temp = flow_back(:, :, 1);
    a = (1-alpha).*flow_temp(idx_noshift)+alpha.*flow_temp(idx_shift_x);
    b = (1-alpha).*flow_temp(idx_shift_y)+alpha.*flow_temp(idx_shift_xy);
    u = (1-beta).*a+beta.*b;
    flow_temp = flow_back(:, :, 2);
    a = (1-alpha).*flow_temp(idx_noshift)+alpha.*flow_temp(idx_shift_x);
    b = (1-alpha).*flow_temp(idx_shift_y)+alpha.*flow_temp(idx_shift_xy);
    v = (1-beta).*a+beta.*b;
    dCol = bCol+u;
    dRow = bRow+v;
    
    mask = (((dCol-aCol).^2+(dRow-aRow).^2) >= (0.01*(flow_fore_sum+u.^2+v.^2)+0.5));
    area_valid(mask) = 0;
    
    for i = 1:length(tracker)
        if tracker(i).stopped == true
            continue;
        end
        
        if tracker(i).start == t
            eRow = tracker(i).oRow;
            eCol = tracker(i).oCol;
        else
            eRow = tracker(i).mRow(end);
            eCol = tracker(i).mCol(end);
        end
        
        eCol_integer = round(eCol);
        eRow_integer = round(eRow);
        
        if area_valid(eRow_integer, eCol_integer) ~= 1
            tracker(i).stopped = true;
        else
            fCol = eCol+flow_fore(eRow_integer, eCol_integer, 1);
            fRow = eRow+flow_fore(eRow_integer, eCol_integer, 2);
            fCol_integer = round(fCol);
            fRow_integer = round(fRow);
            
            if fCol_integer < 1 || fRow_integer < 1 || fCol_integer > width || fRow_integer > height
                tracker(i).stopped = true;
            else
                tracker(i).mCol(end+1) = fCol;
                tracker(i).mRow(end+1) = fRow;
                tracker(i).end = t+1;
            end
        end
    end
end

% filter output trajectories
trajectory = rmfield(tracker, 'stopped')';
disp([num2str(length(trajectory)), ' trajectories found.']);


%% compute corners
function cnr = cmpCorner(img, rho)

% img_gray = rgb2gray(img);
[height, width, channel] = size(img);
dxx = zeros([height, width]);
dyy = zeros([height, width]);
dxy = zeros([height, width]);

for ch = 1:channel
    % compute gradient
    [dx, dy] = imgradientxy(squeeze(img(:, :, ch)), 'central');
    
    % compute second moment matrix
    dxx = dxx+dx.^2;
    dyy = dyy+dy.^2;
    dxy = dxy+dx.*dy;
end

% smooth second moment matrix
dxx = smoothFilter(dxx, rho);
dyy = smoothFilter(dyy, rho);
dxy = smoothFilter(dxy, rho);

% compute smallest eigenvalue
temp = 0.5*(dxx+dyy);
temp2 = temp.^2+dxy.^2-dxx.*dyy;
cnr = temp-sqrt(temp2);
cnr(temp2 < 0) = 0;


%% recursive gaussian filter
function result= smoothFilter(signal, sigma)
para_alpha = 2.5/(sqrt(pi)*sigma);
para_exp1 = exp(-para_alpha);
para_exp1sqr = para_exp1^2;
para_exp2 = 2*para_exp1;
para_k = (1-para_exp1)^2/(1+2*para_alpha*para_exp1-para_exp1sqr);
para_minus = para_exp1*(para_alpha-1);
para_plus = para_exp1*(para_alpha+1);
[size_row, size_col, size_channel] = size(signal);
result = zeros([size_row, size_col, size_channel]);

for ch = 1:size_channel
    signal_2d = squeeze(signal(:, :, ch));
    
    % smooth along rows
    para_forward = zeros([size_row, size_col]);
    para_backward = zeros([size_row, size_col]);
    para_forward(:, 1) = (0.5-para_k*para_minus)*signal_2d(:, 1);
    para_forward(:, 2) = para_k*(signal_2d(:, 2)+para_minus*signal_2d(:, 1))...
        +(para_exp2-para_exp1sqr)*para_forward(:, 1);
    
    for col = 3:size_col
        para_forward(:, col) = para_k*(signal_2d(:, col)+para_minus*signal_2d(:, col-1))...
            +para_exp2*para_forward(:, col-1)-para_exp1sqr*para_forward(:, col-2);
    end
    
    para_backward(:, size_col) = (0.5+para_k*para_minus)*signal_2d(:, size_col);
    para_backward(:, size_col-1) = para_k*((para_plus-para_exp1sqr)*signal_2d(:, size_col))...
        +(para_exp2-para_exp1sqr)*para_backward(:, size_col);
    
    for col = size_col-2:1
        para_backward(:, col) = para_k*(para_plus*signal_2d(:, col+1)-para_exp1sqr*signal_2d(:, col+2))...
            +para_exp2*para_backward(:, col+1)-para_exp1sqr*para_backward(:, col+2);
    end
    
    temp_signal = para_forward+para_backward;
    
    % smooth along columns
    para_forward = zeros([size_row, size_col]);
    para_backward = zeros([size_row, size_col]);
    para_forward(1, :) = (0.5-para_k*para_minus)*temp_signal(1, :);
    para_forward(2, :) = para_k*(temp_signal(2, :)+para_minus*temp_signal(1, :))...
        +(para_exp2-para_exp1sqr)*para_forward(1, :);
    
    for row = 3:size_row
        para_forward(row, :) = para_k*(temp_signal(row, :)+para_minus*temp_signal(row-1, :))...
            +para_exp2*para_forward(row-1, :)-para_exp1sqr*para_forward(row-2, :);
    end
    
    para_backward(size_row, :) = (0.5+para_k*para_minus)*temp_signal(size_row, :);
    para_backward(size_row-1, :) = para_k*((para_plus-para_exp1sqr)*temp_signal(size_row, :))...
        +(para_exp2-para_exp1sqr)*para_backward(size_row, :);
    
    for row = size_row-2:1
        para_backward(row, :) = para_k*(para_plus*temp_signal(row+1, :)-para_exp1sqr*temp_signal(row+2, :))...
            +para_exp2*para_backward(row+1, :)-para_exp1sqr*para_backward(row+2, :);
    end
    
    result(:, :, ch) = para_forward+para_backward;
end