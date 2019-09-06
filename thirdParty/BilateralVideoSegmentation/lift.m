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

% This function lifts data to [y,u,v,x,y,t] bilateral space
function bilateralData = lift(vid,gridsize,frames)

[h,w,~,f] = size(vid);
numDims = 6;
bilateralData = zeros([h*w*f, numDims], 'single');

%% add color features
colors = reshape(im2double(permute(vid,[1 2 4 3])),[h*w*f 3]);
colors = rgb2ntsc(colors); 
bilateralData(:,1:3) = colors;
clear colors;

%% add location features
[Y,X] = ndgrid(1:h,1:w);
Y = repmat(Y(:),[1 f]);
X = repmat(X(:),[1 f]);
bilateralData(:,4) = Y(:);
bilateralData(:,5) = X(:);

%% add temporal features. Can take sparse frame numbers or it just assumes sequential frames
if ~exist('frames','var')
    bilateralData(:,6) = repelem(1:f, w*h);
else
    bilateralData(:,6) = repelem(frames, w*h);
end
    
%% scale to grid size
eps = 0.001;
lBounds = min(bilateralData)-eps;
uBounds = max(bilateralData)+eps;
scaleFactors = (gridsize-1) ./ (uBounds - lBounds);
bilateralData = bsxfun(@minus, bilateralData, lBounds);
bilateralData = bsxfun(@times, bilateralData, scaleFactors)+1;
