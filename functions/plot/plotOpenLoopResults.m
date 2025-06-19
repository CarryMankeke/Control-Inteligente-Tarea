% plotOpenLoopResults.m
%
% Purpose:
%   Visualize open-loop model prediction vs. real data for each output channel
%   and save the figure into the specified figures directory.
%
% Usage:
%   plotOpenLoopResults(y_true, y_pred, figDir, method);
%
% Inputs:
%   y_true — 6×T matrix of real outputs
%   y_pred — 6×T matrix of predicted outputs
%   figDir — path to directory where the figure will be saved
%   method — string label for the method (e.g., 'narx')
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function plotOpenLoopResults(y_true, y_pred, figDir, method)
    % Ensure output folder exists
    if ~exist(figDir, 'dir')
        mkdir(figDir);
    end

    channels = {'X','Y','Z','Roll','Pitch','Yaw'};
    fig = figure('Visible','off');
    for i = 1:6
        subplot(3,2,i);
        plot(y_true(i,:), 'k--'); hold on;
        plot(y_pred(i,:), 'b');
        title(sprintf('%s Open-Loop – %s', upper(method), channels{i}));
        legend('Real','Predicted');
        xlabel('Time step'); ylabel('Normalized output');
        grid on;
    end
    saveas(fig, fullfile(figDir, sprintf('%s_openloop_all.png', method)));
    close(fig);
end
