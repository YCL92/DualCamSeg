% Bilateral Space Video Segmentation
% CVPR 2016
% Nicolas Maerki, Oliver Wang, Federico Perazzi, Alexander Sorkine-Hornung
% 
% This is a personal reimplementation of the method described in the above paper.
% The code is released for research purposes only. If you use this software you must
% cite the above paper!
%
% Read the README.txt before proceeding. 
%
% This is a simplified, unoptimized version of our paper. It only performs
% one task, which is to propagate a mask over a video. 

%% parameters
vidFn = './data/ducks/ducks.mp4';
maskFn = {'./data/ducks/ducks01_0001_gt.ppm',...
          './data/ducks/ducks01_0100_gt.ppm',...
          './data/ducks/ducks01_0200_gt.ppm',...
          './data/ducks/ducks01_0300_gt.ppm',...
          './data/ducks/ducks01_0400_gt.ppm'};
maskFrames = [1];

% vidFn = './data/bear/bear.mp4';
% maskFn = {'./data/bear/bear01_0001_gt.ppm',...
%           './data/bear/bear01_0040_gt.ppm',...
%           './data/bear/bear01_0080_gt.ppm',...
%           './data/bear/bear01_0100_gt.ppm'};
% maskFrames = [1,40,80,100];

% Grid parameters
intensityGridSize = 35;
chromaGridSize = 15;
spatialGridSize = 20;
temporalGridSize = 5;

% Graph Cut Parameters
pairwiseWeight = 1;
unaryWeight = 100000;
temporalWeight = 1e5;
intensityWeight = 0.05;
colorWeight = 0.03;
spatialWeight = 0.3;
minGraphWeight = 0.001;

% Display parameters
threshold = .2;

%If you run out of memory, try a smaller video
maxtime = 200;
scale = .75;
speedscale = 1;

dimensionWeights = [colorWeight, colorWeight, colorWeight, spatialWeight, spatialWeight, temporalWeight];
gridSize = [intensityGridSize chromaGridSize chromaGridSize spatialGridSize spatialGridSize temporalGridSize];

%% load video
vidReader = VideoReader(vidFn);
vid = readFrame(vidReader);
f = 1;
% vid=vid(:,:,:,1:speedscale:f);
vid = imresize(vid,scale);
[h,w,~,f] = size(vid);
mask = zeros(h,w);

for i=1:1    
    mask = double(rgb2gray(im2double(imresize(imread(maskFn{i}),scale,'nearest')))~=1);
    mask(1:4:end, 1:4:end) = NaN;
end
maskFrames = ceil(maskFrames/speedscale);

%% run video segmentation
tic
segmentation = bilateralSpaceSegmentation(vid,mask,maskFrames,gridSize,dimensionWeights,unaryWeight,pairwiseWeight);
endtime = toc;
disp(['Segmentation took ' num2str(endtime/f) 's per frame']);

%% postprocess video
segmentation = uint8(255*segmentation);
%segmentation = imerode(segmentation,strel('disk',5));
%segmentation = imdilate(segmentation,strel('disk',5));

%% visualize result
segmentation = reshape(segmentation,[h,w,1,f]);
h2 = implay([segmentation(:,:,[1 1 1],:) vid]);
