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

%%
function segmentation = bilateralSpaceSegmentation(vid,mask,maskFrames,gridSize,dimensionWeights,unaryWeight,pairwiseWeight)
[h,w,~,f] = size(vid);


%% Lifting (3.1)
bilateralData = lift(vid,gridSize);
bilateralMask = lift(vid(:,:,:,maskFrames),gridSize,maskFrames);

maskValues = cat(2,mask(:)==1.,mask(:)==0);
bilateralValues = ones(size(bilateralData,1),1);

%% Splatting (3.2)
splattedMask = splat(bilateralMask, maskValues, gridSize);
splattedData = splat(bilateralData, bilateralValues, gridSize);

%% Graph Cut (3.3)
labels = graphcut(splattedData, splattedMask, gridSize, dimensionWeights, unaryWeight, pairwiseWeight);

%% Splicing (3.4)
slicedData = slice(labels,bilateralData,gridSize);

%% reshape output
segmentation = reshape(slicedData,[h,w,f]);