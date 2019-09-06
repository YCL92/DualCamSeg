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
function labels = graphcut(splattedData, splattedMask, gridSize, dimensionWeights, unaryWeight, pairwiseWeight)

%% init
% addpath('GCMex2.0');
debugPrintout = 0;

%% get only the vertices that will be sliced
occupiedVertices = find(splattedData);
splattedData = splattedData(occupiedVertices);
splattedMask = splattedMask(occupiedVertices, :);

%% Build pairwise cost matrix
A = createAdjacencyMatrix(gridSize, occupiedVertices, double(splattedData), dimensionWeights);

%% Solve GraphCut
gch = GraphCut('open', splattedMask'*unaryWeight, [0,1;1,0]*pairwiseWeight, A);
[gch, L] = GraphCut('expand',gch);
[gch, smoothnessEnergy, dataEnergy] = GraphCut('energy', gch);
if debugPrintout
    disp(['smoothnessEnergy: ' num2str(smoothnessEnergy) ', dataEnergy: ' num2str(dataEnergy)]);
end
GraphCut('close', gch);

%% output
labels = zeros(prod(gridSize),1);
labels(occupiedVertices) = L;

%% helper function to make the adjacency matrix
function B = createAdjacencyMatrix( gridSize, occupiedVertices, occupiedVertexWeights, dimensionWeights )

minGraphWeight = 0.01;

%% for each nonzero dimension, add a weight for its two neighbors
for i=find(dimensionWeights)
    
    %% find the index offset
    if i==1
        offset = 1;
    else
        offset = prod(gridSize(1:i-1));
    end
    
    %% compute neighbor indices in the graph vertex space
    leftIndices = occupiedVertices - offset;
    rightIndices = occupiedVertices + offset;
    
    %% project onto the front dimension plane
    maxidx = prod(gridSize(1:i));
    centerModulo = floor((occupiedVertices-1) / maxidx) * maxidx;
    
    %% check if out of bounds
    invalidLeft = (leftIndices - centerModulo) < 1;
    invalidRight = (rightIndices - centerModulo) > maxidx;    
    leftIndices(invalidLeft) = 0;
    rightIndices(invalidRight) = 0;
    
    %% Convert the indices into the occupied Vertex space
    [~, leftIndices, leftCenterIndices] = intersect(leftIndices, occupiedVertices);
    [~, rightIndices, rightCenterIndices] = intersect(rightIndices, occupiedVertices);
    
    %% weight for an edge is the product of the vertex weights
    wLeft = occupiedVertexWeights(leftCenterIndices) .* occupiedVertexWeights(leftIndices);
    wRight = occupiedVertexWeights(rightCenterIndices) .* occupiedVertexWeights(rightIndices);
    
    %% disable the pairwise weights (S# in Eq. 8). 
    % With these off pre-splatting the entire video is not necessary, and you can just splat the mask
    % wLeft = 1;
    % wRight = 1;
    
    %% Construct sparse matrix
    sp_i = [leftCenterIndices; rightCenterIndices];
    sp_j = [leftIndices; rightIndices];
    sp_v = [wLeft.*(dimensionWeights(i)*ones(size(leftCenterIndices,1),1)); ...
        wRight.*(dimensionWeights(i)*ones(size(rightCenterIndices,1),1))];
    
    %% regularization
    sp_v = max(sp_v, minGraphWeight);
    
    %% construct sparse matrix
    Bd = sparse(sp_i, sp_j, sp_v, size(occupiedVertices,1), size(occupiedVertices,1));
    if i==1
        B = Bd;
    else
        B = Bd + B;
    end
end
