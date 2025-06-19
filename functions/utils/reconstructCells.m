% functions/reconstructCells.m
function M = reconstructCells(cellArr, indices, delay)
%RECONSTRUCTCELLS   Assemble regressor samples from split cell arrays.
%   M = reconstructCells(cellArr, indices, delay) takes:
%     - cellArr: 1×F cell array, each cell is D×N_flight (training or validation splits)
%     - indices: 1×K vector of sample indices as produced by extractRegressors
%     - delay:   scalar number of delays used in extractRegressors
%   and returns M of size D×K containing the corresponding columns from
%   the concatenated data, time–aligned by the delay offset.

    % 1) Concatenate all flights into one large matrix
    bigMat = horzcat(cellArr{:});   % size: D × N_total

    % 2) Compute the absolute column positions in bigMat
    %    Each sample k in X was built from bigMat columns k:(k+delay-1),
    %    so to align we shift by 'delay'
    cols = indices + delay;

    % 3) Validate column indices
    if any(cols > size(bigMat,2)) || any(cols < 1)
        error('reconstructCells: index out of range. Check delay and indices.');
    end

    % 4) Extract and return the selected columns
    M = bigMat(:, cols);  % size D×K
end