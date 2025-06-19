% plot_all_results.m
%
% Purpose:
%   Load all logged data and generate figures for closed-loop and open-loop
%   results, as well as summary comparison plots using modular plot functions.
%
% Usage:
%   plot_all_results(cfg);
%
% Inputs:
%   cfg — configuration struct with paths and settings
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function plot_all_results(cfg)
    %% Ensure figures directory exists
    if ~exist(cfg.paths.fig, 'dir')
        mkdir(cfg.paths.fig);
    end

    %% Load all logs
    logs = loadAllLogs(cfg.paths.log);

    %% Closed-loop results
    plotClosedLoopResults(logs.E_hist, logs.U_hist, logs.W_hist, cfg.paths.fig);

    %% Open-loop results
    plotOpenLoopResults(logs.y_test, logs.y_pred_open, cfg.paths.fig, 'narx');

    %% Summary bar charts
    plotSummaryBars(logs.metrics_cl, logs.metrics_open, cfg.paths.fig);

    fprintf('All result figures saved in %s\n', cfg.paths.fig);
end
