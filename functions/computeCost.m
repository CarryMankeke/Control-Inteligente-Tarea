% computeCost.m
%
% Purpose:
%   Compute performance metrics for a given control/modeling method.
%
% Usage:
%   metrics = computeCost(E_hist, U_hist, W_hist);
%
% Inputs:
%   E_hist  — 6×T tracking error history (y_ref – Y_hat)
%   U_hist  — 4×T control inputs applied
%   W_hist  — 4×6×T history of controller weight matrix
%
% Outputs (in struct metrics):
%   mse_total       — overall mean squared error
%   mse_by_channel  — 6×1 vector of MSE per channel [X,Y,Z,Roll,Pitch,Yaw]
%   max_input       — maximum absolute control input value
%   delta_W_vec     — 4×6 matrix of total weight change (final minus initial)
%
function metrics = computeCost(E_hist, U_hist, W_hist)
    % Overall mean squared error
    metrics.mse_total      = mean(E_hist(:).^2);

    % Mean squared error per output channel
    metrics.mse_by_channel = mean(E_hist.^2, 2);

    % Maximum absolute value of control inputs
    metrics.max_input      = max(abs(U_hist(:)));

    % Total change in weights: final minus initial
    initialW = W_hist(:,:,1);
    finalW   = W_hist(:,:,end);
    metrics.delta_W_vec    = finalW - initialW;
end