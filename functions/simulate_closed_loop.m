% simulate_closed_loop.m
%
% Purpose:
%   Run a closed-loop simulation using a closed-loop NARX network for
%   feedback estimation and an MRAC controller for control input.
%   Outputs predicted outputs, control inputs, errors, and weight evolution.
%
% Usage:
%   [Y_hat, U_hist, E_hist, W_hist] = simulate_closed_loop(netCL, controller, y_ref, delay);
%
% Inputs:
%   netCL      — closed-loop NARX network (series–parallel closed-loop)
%   controller — MRAC struct from init_mrac_controller
%   y_ref      — 6×T reference trajectory [pos; euler]
%   delay      — number of delays used in NARX model
%
% Outputs:
%   Y_hat  — 6×T predicted outputs
%   U_hist — 4×T control inputs applied
%   E_hist — 6×T tracking error history (y_ref – Y_hat)
%   W_hist — 4×6×T history of controller weights over time
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function [Y_hat, U_hist, E_hist, W_hist] = simulate_closed_loop(netCL, controller, y_ref, delay)
    %% Dimensions and preallocation
    nOut  = size(y_ref, 1);
    T     = size(y_ref, 2);
    nIn   = size(controller.W, 1);

    Y_hat  = zeros(nOut, T);
    U_hist = zeros(nIn, T);
    E_hist = zeros(nOut, T);
    W_hist = zeros(nIn, nOut, T);

    %% Initialize history buffers
    uHist = zeros(nIn, delay);
    yHist = zeros(nOut, delay);

    %% Prepare initial NARX state
    [~, Xi, Ai] = preparets(netCL, con2seq(uHist), {}, con2seq(yHist));

    %% Main simulation loop
    for t = delay+1:T
        % Previous estimated output
        if t == delay+1
            yPrev = yHist(:, end);
        else
            yPrev = Y_hat(:, t-1);
        end

        % Compute previous error and normalize angles
        ePrev = y_ref(:, t-1) - yPrev;
        ePrev(4:6) = wrapToPi(ePrev(4:6));

        % MRAC control input and weight update
        u_t = controller.compute_u(ePrev);
        controller.W = controller.update_W(controller.W, u_t, ePrev, controller.eta);

        % Update input history buffer
        uHist = [uHist(:, 2:end), u_t];

        % NARX prediction for current step
        [ySeq, Xi, Ai] = netCL(con2seq(uHist), Xi, Ai);
        y_t = cell2mat(ySeq(end));

        % Update output history buffer
        yHist = [yHist(:, 2:end), y_t];

        % Current error and normalization
        e_t = y_ref(:, t) - y_t;
        e_t(4:6) = wrapToPi(e_t(4:6));

        % Store histories
        Y_hat(:, t)    = y_t;
        U_hist(:, t)   = u_t;
        E_hist(:, t)   = e_t;
        W_hist(:, :, t) = controller.W;
    end
end