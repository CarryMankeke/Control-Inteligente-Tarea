% BLOCK 6: Plot simulation results for controlled quadcopter
%
% Description:
%   Visualizes the performance of the closed-loop system with MRAC and NARX:
%     1) 3D trajectory comparison (reference vs. estimated)
%     2) Tracking error per channel over time
%     3) Control inputs u(t) over time
%     4) Evolution of the MRAC weight matrix W over time
%
% Arguments:
%   y_ref  (6×T double): Desired reference trajectory [x; y; z; roll; pitch; yaw].
%   Y_hat  (6×T double): Predicted outputs from the NARX model.
%   E_hist (6×T double): Tracking error history (y_ref - Y_hat).
%   U_hist (4×T double): Control inputs applied by MRAC.
%   W_hist (4×6×T double): Evolution of the MRAC weight matrix W over time.
%
% Returns:
%   None (generates figures)
% -----------------------------------------------------------------------------
function bloque6_plot_resultados(y_ref, Y_hat, E_hist, U_hist, W_hist)
    %% Initialize time vector
    T = size(y_ref, 2);
    t = 0:(T-1);

    %% 1) 3D trajectory comparison
    figure;
    plot3(y_ref(1,:), y_ref(2,:), y_ref(3,:), 'g--', 'LineWidth', 1.5); hold on;
    plot3(Y_hat(1,:), Y_hat(2,:), Y_hat(3,:), 'b',  'LineWidth', 1.5);
    legend('Reference', 'Estimated', 'Location', 'best');
    xlabel('X'); ylabel('Y'); zlabel('Z');
    title('3D Trajectory');
    grid on; axis equal;

    %% 2) Tracking error per channel
    channels = {'X','Y','Z','Roll','Pitch','Yaw'};
    figure;
    for i = 1:6
        subplot(3, 2, i);
        plot(t, E_hist(i,:), 'r');
        title(sprintf('Error in %s', channels{i}));
        xlabel('Time step'); ylabel('Error');
        grid on;
    end
    sgtitle('Tracking Error per Channel');

    %% 3) Control inputs over time
    figure;
    for i = 1:4
        subplot(4, 1, i);
        plot(t, U_hist(i,:), 'k');
        title(sprintf('Control Input u%d', i));
        ylabel('Magnitude');
        grid on;
    end
    xlabel('Time step');

    %% 4) Evolution of MRAC weights
    figure;
    for i = 1:4
        for j = 1:6
            subplot(4, 6, (i-1)*6 + j);
            plot(squeeze(W_hist(i, j, :)));
            title(sprintf('W(%d,%d)', i, j));
            grid on;
        end
    end
    sgtitle('Evolution of Controller Weights W');
end
