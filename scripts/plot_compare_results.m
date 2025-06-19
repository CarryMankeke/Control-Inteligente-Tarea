% scripts/plot_compare_results.m
function plot_compare_results(cfg)
    % Ensure figures directory exists
    if ~exist(cfg.paths.fig,'dir')
        mkdir(cfg.paths.fig);
    end

    %% 1) Total MSE comparison
    M1 = load(fullfile(cfg.paths.log,'metrics_summary.mat'),'metrics');
    M2 = load(fullfile(cfg.paths.log,'fcm','metrics_fcm.mat'),'metrics');
    fig1 = figure('Visible','off');
    bar([M1.metrics.mse_total, M2.metrics.mse_total]);
    set(gca,'XTickLabel',{'Global','FCM'});
    ylabel('Total MSE');
    title('Closed-Loop MSE Comparison');
    saveas(fig1, fullfile(cfg.paths.fig,'mse_comparison_fcm.png'));
    close(fig1);

    %% 2) Evolution of all MRAC weights over time
    % Load baseline and FCM weight histories
    baseLog = load(fullfile(cfg.paths.log,'simulation_metrics.mat'),'W_hist');
    fcmLog  = load(fullfile(cfg.paths.log,'fcm','metrics_fcm.mat'),'W_hist');
    Wb = baseLog.W_hist;   % size [nIn × nOut × T]
    Wf = fcmLog.W_hist;

    [nIn, nOut, T] = size(Wb);
    t = 1:T;

    fig2 = figure('Visible','off','Position',[100 100 1600 800]);
    for i = 1:nIn
        for j = 1:nOut
            idx = (i-1)*nOut + j;
            subplot(nIn, nOut, idx);
            plot(t, squeeze(Wb(i,j,:)), '-'); hold on;
            plot(t, squeeze(Wf(i,j,:)), '--');
            title(sprintf('W(%d,%d)', i, j));
            if i == nIn
                xlabel('Time Step');
            end
            if j == 1
                ylabel('Gain');
            end
            if i==1 && j==nOut
                legend('Global','FCM','Location','northeast');
            end
            grid on;
        end
    end
    sgtitle('Evolution of All MRAC Weights Over Time');
    saveas(fig2, fullfile(cfg.paths.fig,'all_weights_evolution.png'));
    close(fig2);
end
