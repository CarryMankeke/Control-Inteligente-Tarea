% preprocess_data_fromXY.m
%
% Purpose:
%   Like preprocess_quadrotor_data, but operates directly on loaded U,Y matrices
%   rather than reading from a file.
%
% Usage:
%   [u_train, y_train, u_val, y_val, u_test, y_test] = ...
%       preprocess_data_fromXY(U, Y, trainRatio, valRatio);
%
% Inputs:
%   U           — (nIn×N) raw input matrix for a single flight
%   Y           — (nOut×N) raw output matrix [position; orientation] for that flight
%   trainRatio  — fraction of data for training (e.g., 0.7)
%   valRatio    — fraction of data for validation (e.g., 0.15)
%
% Outputs:
%   u_train, y_train — training subsets
%   u_val,   y_val   — validation subsets
%   u_test,  y_test  — test subsets
%
function [u_train, y_train, u_val, y_val, u_test, y_test] = ...
    preprocess_data_fromXY(U, Y, trainRatio, valRatio)

    %% Validate dimensions
    if size(U,2) ~= size(Y,2)
        error('U and Y must have the same number of columns.');
    end

    %% Smooth outputs (5-sample moving average)
    Y = movmean(Y, 5, 2);

    %% Normalize outputs:
    %   - Position channels to [-1,1]
    %   - Orientation channels to [-1,1] via wrapToPi / pi
    Y_pos = mapminmax(Y(1:3,:), -1, 1);
    Y_ori = wrapToPi(Y(4:6,:)) / pi;
    Y     = [Y_pos; Y_ori];

    %% Normalize inputs to [-1,1]
    U = mapminmax(U, -1, 1);

    %% Split data sequentially into train/val/test
    N       = size(U,2);
    N_train = floor(trainRatio * N);
    N_val   = floor(valRatio   * N);

    u_train = U(:,       1:N_train);
    y_train = Y(:,       1:N_train);

    u_val   = U(:, N_train+1 : N_train+N_val);
    y_val   = Y(:, N_train+1 : N_train+N_val);

    u_test  = U(:, N_train+N_val+1 : end);
    y_test  = Y(:, N_train+N_val+1 : end);
end