% functions/plots/plotClosedLoopResults.m
%
% Purpose:
%   Visualize closed-loop simulation results and save each figure into the
%   specified figures directory.
%
% Usage:
%   plotClosedLoopResults(E_hist, U_hist, W_hist, figDir);
%
% Inputs:
%   E_hist — 6×T tracking error history
%   U_hist — 4×T control inputs applied
%   W_hist — 4×6×T history of controller weight matrix
%   figDir — path to directory where figures will be saved
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function plotClosedLoopResults(E_hist, U_hist, W_hist, figDir)
    % Ensure output folder exists
    if ~exist(figDir, 'dir')
        mkdir(figDir);
    end

    T = size(E_hist, 2);
    t = 0:(T-1);

    %% 1) 3D trajectory omitted (external reference used instead)
    % This function focuses on errors, inputs, and weight evolution.

    %% 1) Tracking error per channel
    channels = {'X','Y','Z','Roll','Pitch','Yaw'};
    fig1 = figure('Visible','off');
    for i = 1:6
        subplot(3,2,i);
        plot(t, E_hist(i,:), 'r');
        title(sprintf('Error in %s', channels{i}));
        xlabel('Time step'); ylabel('Error'); grid on;
    end
    sgtitle('Tracking Error per Channel');
    saveas(fig1, fullfile(figDir, 'closedloop_tracking_errors.png'));
    close(fig1);

    %% 2) Control inputs
    fig2 = figure('Visible','off');
    for i = 1:4
        subplot(4,1,i);
        plot(t, U_hist(i,:), 'k');
        title(sprintf('Control Input u%d', i)); ylabel('Magnitude'); grid on;
    end
    xlabel('Time step');
    saveas(fig2, fullfile(figDir, 'closedloop_control_inputs.png'));
    close(fig2);

    %% 3) MRAC weight evolution
    fig3 = figure('Visible','off');
    for i = 1:4
        for j = 1:6
            subplot(4,6,(i-1)*6 + j);
            plot(squeeze(W_hist(i,j,:)));
            title(sprintf('W(%d,%d)', i, j)); grid on;
        end
    end
    sgtitle('Evolution of Controller Weights');
    saveas(fig3, fullfile(figDir, 'closedloop_weight_evolution.png'));
    close(fig3);
end
