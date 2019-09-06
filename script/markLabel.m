function img_mark = markLabel(img_raw, list_xy, list_label)
% this function marks every points given by list_label
% with different colors based on their labels.
% by yucheng.l@outlook.com 2018-01-03

%% initialization
% compute frequency table
tbl = tabulate(list_label);

if isempty(tbl)
    img_mark = img_raw;
    return;
end

%% mark each label with different color
img_mark = img_raw;
tbl_color = distinguishable_colors(length(tbl)+3)*255;

for i = 1:length(tbl)
    mask = (list_label == tbl(i));
    map(:, 1) = list_xy(mask, 1);
    map(:, 2) = list_xy(mask, 2);
    map(:, 3) = 2;
    
    % mark in image as filled circles
    img_mark = insertShape(img_mark, 'FilledCircle', map, 'color', tbl_color(i, :), 'Opacity', 1);
    clear map
end