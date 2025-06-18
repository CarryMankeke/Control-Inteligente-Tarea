% BLOCK 1: Load, normalize, and split the quadcopter dataset
%
% Dataset source:
%   WaveLab AscTec Pelican Flight Dataset
%   http://wavelab.uwaterloo.ca/index3390.html?page_id=705
%
% Description:
%   Loads the pre-saved quadrotor data, normalizes inputs and outputs,
%   and splits the dataset sequentially into training, validation, and
%   test sets.
%
% Arguments:
%   datasetPath (string): Path to the .mat file containing variables U and Y.
%   trainRatio  (double): Fraction of data for training (e.g., 0.7).
%   valRatio    (double): Fraction of data for validation (e.g., 0.15).
%
% Returns:
%   u_train (4×N_train double): Normalized input commands for training.
%   y_train (6×N_train double): Normalized outputs for training.
%   u_val   (4×N_val   double): Normalized input commands for validation.
%   y_val   (6×N_val   double): Normalized outputs for validation.
%   u_test  (4×N_test  double): Normalized input commands for testing.
%   y_test  (6×N_test  double): Normalized outputs for testing.
% -----------------------------------------------------------------------------

function [u_train, y_train, u_val, y_val, u_test, y_test] = bloque1_preproceso(datasetPath, trainRatio, valRatio)
    %% Load data
    data = load(datasetPath);
    if ~isfield(data, 'U') || ~isfield(data, 'Y')
        error('Input file must contain variables U and Y.');
    end
    U = data.U;  % [4 x N]
    Y = data.Y;  % [6 x N]

    %% Validate dimensions
    if size(U,2) ~= size(Y,2)
        error('U and Y must have the same number of time columns.');
    end

    %% Smooth outputs (optional)
    windowSize = 5;
    Y = movmean(Y, windowSize, 2);

    %% Separate position and orientation channels
    Y_pos = Y(1:3, :);  % X, Y, Z
    Y_ori = Y(4:6, :);  % Roll, Pitch, Yaw

    %% Normalize outputs to [-1, 1]
    [Y_pos, ~] = mapminmax(Y_pos, -1, 1);
    Y_ori = wrapToPi(Y_ori) / pi;
    Y = [Y_pos; Y_ori];

    %% Normalize inputs to [-1, 1]
    [U, ~] = mapminmax(U, -1, 1);

    %% Split data sequentially
    N       = size(U,2);
    N_train = floor(trainRatio * N);
    N_val   = floor(valRatio   * N);

    u_train = U(:, 1:N_train);
    y_train = Y(:, 1:N_train);

    u_val   = U(:, N_train+1 : N_train+N_val);
    y_val   = Y(:, N_train+1 : N_train+N_val);

    u_test  = U(:, N_train+N_val+1 : end);
    y_test  = Y(:, N_train+N_val+1 : end);
end
