% BLOCK 5: Closed-loop simulation with MRAC and NARX feedback estimation
%
% Description:
%   Runs a closed-loop simulation using the closed-loop NARX network for
%   feedback estimation and a Model Reference Adaptive Controller (MRAC) with
%   MIT Rule updates. Stores predicted outputs, applied inputs, errors,
%   and weight evolution over time.
%
% Arguments:
%   narxCL   (network)    : Closed-loop NARX network for feedback estimation.
%   mrac     (struct)     : Adaptive controller with fields W, eta,
%                           compute_u, update_W.
%   yRef     (6×T double) : Reference trajectory [x; y; z; roll; pitch; yaw].
%   delay    (integer)    : Number of delays used in the NARX network.
%
% Returns:
%   Y_hat  (6×T double)      : Predicted outputs from the NARX model.
%   U_hist (4×T double)      : Control inputs applied by MRAC.
%   E_hist (6×T double)      : Tracking errors yRef - Y_hat.
%   W_hist (4×6×T double)    : Evolution of the MRAC weight matrix W over time.
% -----------------------------------------------------------------------------

function [Y_hat, U_hist, E_hist, W_hist] = bloque5_simulacion_lazo_cerrado(narxCL, mrac, yRef, delay)
    %% Initialize dimensions and history buffers
    T     = size(yRef, 2);          % total time steps
    nOut  = size(yRef, 1);          % number of output channels
    nIn   = size(mrac.W, 1);        % number of input channels

    Y_hat  = zeros(nOut, T);
    U_hist = zeros(nIn,  T);
    E_hist = zeros(nOut, T);
    W_hist = zeros(nIn, nOut, T);

    %% Initialize input/output delay buffers
    uHist = zeros(nIn, delay);
    yHist = zeros(nOut, delay);

    %% Prepare initial NARX state
    [~, Xi, Ai] = preparets(narxCL, con2seq(uHist), {}, con2seq(yHist));

    %% Main simulation loop
    for t = delay+1:T
        % Previous estimated output
        if t == delay+1
            yPrev = yHist(:, end);
        else
            yPrev = Y_hat(:, t-1);
        end

        % Compute previous error and normalize angles
        ePrev = yRef(:, t-1) - yPrev;
        ePrev(4:6) = wrapToPi(ePrev(4:6));

        % MRAC control input and weight update
        u_t = mrac.compute_u(ePrev);
        mrac.W = mrac.update_W(mrac.W, u_t, ePrev, mrac.eta);

        % Update input history buffer
        uHist = [uHist(:, 2:end), u_t];

        % NARX prediction for current step
        [ySeq, Xi, Ai] = narxCL(con2seq(uHist), Xi, Ai);
        y_t = cell2mat(ySeq(end));

        % Update output history buffer
        yHist = [yHist(:, 2:end), y_t];

        % Current error and normalization
        e_t = yRef(:, t) - y_t;
        e_t(4:6) = wrapToPi(e_t(4:6));

        % Store histories
        Y_hat(:,  t)   = y_t;
        U_hist(:, t)   = u_t;
        E_hist(:, t)   = e_t;
        W_hist(:, :, t) = mrac.W;
    end
end
