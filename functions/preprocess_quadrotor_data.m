% preprocess_quadrotor_data.m
%
% Purpose:
%   Load a synchronized quadrotor dataset, normalize inputs/outputs, apply 
%   optional smoothing, and split into training, validation, and test sets.
%
% Usage:
%   [u_train, y_train, u_val, y_val, u_test, y_test] = ...
%       preprocess_quadrotor_data(inputPath, trainRatio, valRatio);
%
% Inputs:
%   inputPath  — full path to the MAT-file containing variables U and Y
%   trainRatio — fraction of data to use for training (e.g., 0.7)
%   valRatio   — fraction of data to use for validation (e.g., 0.15)
%
% Outputs:
%   u_train, y_train — normalized inputs/outputs for training
%   u_val,   y_val   — normalized inputs/outputs for validation
%   u_test,  y_test  — normalized inputs/outputs for testing
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function [u_train, y_train, u_val, y_val, u_test, y_test] = ...
    preprocess_quadrotor_data(inputPath, trainRatio, valRatio)

    %% Load data
    data = load(inputPath);
    if ~isfield(data, 'U') || ~isfield(data, 'Y')
        error('Input file must contain variables U and Y.');
    end
    U = data.U;  % 4×N
    Y = data.Y;  % 6×N

    %% Validate matching lengths
    if size(U,2) ~= size(Y,2)
        error('U and Y must have same number of columns (time steps).');
    end

    %% Optional smoothing on outputs
    windowSize = 5;
    Y = movmean(Y, windowSize, 2);

    %% Split position and orientation channels
    Y_pos = Y(1:3, :);   % X, Y, Z
    Y_ori = Y(4:6, :);   % Roll, Pitch, Yaw

    %% Normalize outputs to [-1,1]
    [Y_pos, ~] = mapminmax(Y_pos, -1, 1);
    Y_ori     = wrapToPi(Y_ori) / pi;
    Y = [Y_pos; Y_ori];

    %% Normalize inputs to [-1,1]
    [U, ~] = mapminmax(U, -1, 1);

    %% Determine split indices
    N       = size(U,2);
    N_train = floor(trainRatio * N);
    N_val   = floor(valRatio   * N);

    %% Partition data
    u_train = U(:, 1:N_train);
    y_train = Y(:, 1:N_train);

    u_val   = U(:, N_train+1 : N_train+N_val);
    y_val   = Y(:, N_train+1 : N_train+N_val);

    u_test  = U(:, N_train+N_val+1 : end);
    y_test  = Y(:, N_train+N_val+1 : end);
end