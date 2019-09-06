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
function [splattedData] = splat(bilateralData,bilateralVals,gridSize)

[nPoints,nDims] = size(bilateralData);
nPotentialVertices = prod(gridSize);
nClasses = size(bilateralVals,2);

% get ceil/floor for n-linear interpolation
floors = floor(bilateralData);
ceils = ceil(bilateralData);
remainders = bilateralData - floors;

% accumulate splat values on bilateral grid
splattedData = zeros(nPotentialVertices, nClasses,'single');

for i=1:2^nDims
    % use the binary representation as floor (0) and ceil (1)
    bin = dec2bin(i-1,nDims);
    
    weights = ones(nPoints,1);
    
    % multiply weights for each dimension
    for j=1:nDims
        if bin(j)=='0' % floor
                weights = weights .* (1-remainders(:,j));
            if j==1
                indices = floors(:,j);
            else
                indices = indices + prod(gridSize(1:j-1)).*(floors(:,j)-1);
            end
            
        else % ceil
                weights = weights .* remainders(:,j);
            if j==1
                indices = ceils(:,j);
            else
                indices = indices + prod(gridSize(1:j-1)).*(ceils(:,j)-1);
            end
            
        end
    end
    
    for c=1:nClasses    
        accumData = accumarray(indices,weights .* bilateralVals(:,c),[nPotentialVertices,1], @sum);        
        splattedData(:,c) = splattedData(:,c) + accumData;
    end
end