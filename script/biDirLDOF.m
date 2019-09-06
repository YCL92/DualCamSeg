function list_flow = biDirLDOF(list_img, file_head)
% this function computes bi-directional optical
% flows of given images listed in bmf file.
% by yucheng.l@outlook.com 2017-12-08

%% read all the image files
if nargin < 2
    error('No enough inputs.');
end

%% compute fore and back optical flows
path_root = [list_img(1).folder, '/../'];
path_result = [path_root, 'flow'];

% make a folder for flows
if ~exist(path_result, 'dir')
    mkdir(path_result);
end

if isempty(dir([path_result, '/', file_head, '*.flo']))
    disp(['Computing ', file_head, ' optical flows...']);
    
    parfor i = 1:length(list_img)-1
        disp(['Processing ', list_img(i).name, ' & ', list_img(i+1).name, '... ']);
        
        % read two images
        img1 = im2double(imread([list_img(i).folder, '/', list_img(i).name]));
        img2 = im2double(imread([list_img(i+1).folder, '/', list_img(i+1).name]));
        
        % compute optical flows
        flow_fore = mex_LDOF(img1, img2);
        flow_back = mex_LDOF(img2, img1);
        
        % save to flow files
        str = strsplit(list_img(i).name, '.');
        file_name = cell2mat(str(1));
        writeFlowFile(flow_fore, [path_result, '/', file_name, '_f', '.flo']);
        writeFlowFile(flow_back, [path_result, '/', file_name, '_b', '.flo']);
        img_flow = flowToColor([flow_fore, flow_back]);
        imwrite(img_flow, [path_result, '/', file_name, '_img', '.png']);
    end
end

list_fore = dir([path_result, '/', file_head, '*_f.flo']);
list_back = dir([path_result, '/', file_head, '*_b.flo']);
list_flow = [list_fore, list_back];