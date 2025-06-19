% plotSummaryBars.m
%
% Purpose:
%   Generate summary bar charts for performance metrics, such as MSE by channel
%   and overall comparison between closed-loop and open-loop.
%
% Usage:
%   plotSummaryBars(metrics_cl, metrics_ol, figDir);
%
% Inputs:
%   metrics_cl — struct with fields 'mse_total' and 'mse_by_channel'
%   metrics_ol — struct with field 'mse_total'
%   figDir     — path to directory where the figures will be saved
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function plotSummaryBars(metrics_cl, metrics_ol, figDir)
    % Ensure output folder exists
    if ~exist(figDir, 'dir')
        mkdir(figDir);
    end

    % Bar chart: MSE per channel (closed-loop)
    fig1 = figure('Visible','off');
    bar(metrics_cl.mse_by_channel);
    xticklabels({'X','Y','Z','Roll','Pitch','Yaw'});
    ylabel('MSE'); title('Closed-Loop MSE by Channel');
    saveas(fig1, fullfile(figDir, 'bar_mse_closedloop.png'));
    close(fig1);

    % Bar chart: total MSE comparison
    fig2 = figure('Visible','off');
    bar([metrics_cl.mse_total, metrics_ol.mse_total]);
    set(gca, 'XTickLabel', {'Closed-loop','Open-loop'});
    ylabel('Total MSE'); title('Overall MSE Comparison');
    saveas(fig2, fullfile(figDir, 'bar_mse_comparison.png'));
    close(fig2);
end
