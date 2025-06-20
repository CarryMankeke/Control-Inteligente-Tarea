% loadAllLogs.m
%
% Purpose:
%   Convenience function to load all relevant simulation logs and metrics
%   from the results/log directory.
%
% Usage:
%   logs = loadAllLogs(logDir);
%
% Inputs:
%   logDir — path to the 'log' directory containing .mat files
%
% Outputs:
%   logs — struct with fields:
%       U_hist        — control inputs history
%       E_hist        — tracking error history
%       W_hist        — weight evolution history
%       metrics_cl    — closed-loop metrics struct
%       y_test_aligned        — test outputs
%       y_pred_open   — open-loop predictions
%       metrics_open  — open-loop metrics struct
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function logs = loadAllLogs(logDir)
    % Closed-loop
    CL = load(fullfile(logDir, 'simulation_metrics.mat'), 'U_hist', 'E_hist', 'W_hist');
    MC = load(fullfile(logDir, 'metrics_summary.mat'), 'metrics');
    logs.U_hist       = CL.U_hist;
    logs.E_hist       = CL.E_hist;
    logs.W_hist       = CL.W_hist;
    logs.metrics_cl   = MC.metrics;

    % Open-loop
    OL = load(fullfile(logDir, 'narx_openloop.mat'), 'y_test_aligned', 'y_pred_open');
    MO = load(fullfile(logDir, 'metrics_openloop.mat'), 'metrics_open');
    logs.y_test       = OL.y_test_aligned;
    logs.y_pred_open  = OL.y_pred_open;
    logs.metrics_open = MO.metrics_open;
end
