% SCRIPT: Automatic MRAC Learning-Rate Tuning via fminsearch
%
% Description:
%   Uses MATLAB's fminsearch to optimize the six per-channel MRAC learning rates
%   (eta_x, eta_y, eta_z, eta_roll, eta_pitch, eta_yaw) by minimizing the
%   closed-loop mean squared error (MSE) over a reference trajectory.
%
% Prerequisites:
%   - 'narx_mimo_nets.mat' containing trained closed-loop NARX network (netCL)
%   - 'quadrotorData.mat' containing U, Y (for reference generation only)
%   - Functions on path:
%       * bloque3_generar_referencia
%       * bloque4_init_mrac_eta_por_canal
%       * bloque5_simulacion_lazo_cerrado
%
% Usage:
%   Run this script to find the optimal eta vector. Results are printed to
%   the console. To reuse the objective, consider moving simula_y_retorna_mse
%   into its own file.
%
% Outputs:
%   mejor_eta (1×6 double): Optimal learning rates for each channel.
%   mejor_mse (double)    : Corresponding closed-loop MSE.
% -----------------------------------------------------------------------------

clc; clear; close all;

%% Load trained NARX and data for reference generation
load('narx_mimo_nets.mat', 'netCL');  % closed-loop NARX network
load('quadrotorData.mat', 'U', 'Y');  % original dataset (U not used here)

%% MRAC tuning parameters
delay       = 3;             % number of delays used in NARX
duration    = 20;            % reference duration (s)
dt          = 0.05;          % reference time step (s)
freq        = 1 / dt;        % reference sampling frequency (Hz)

%% Generate and normalize reference trajectory
[y_ref, ~, ~] = bloque3_generar_referencia(duration, freq);
y_ref(1:3, :) = mapminmax(y_ref(1:3, :), -1, 1);
y_ref(4:6, :) = wrapToPi(y_ref(4:6, :)) / pi;

%% fminsearch options
etainit = [0.05, 0.05, 0.05, 0.07, 0.07, 0.10];  % initial eta guess
opts = optimset('Display','iter', ...
                'TolFun',1e-5, 'TolX',1e-5, ...
                'MaxIter',200,  'MaxFunEvals',300);

%% Run optimization
disp('🔧 Tuning MRAC learning rates with fminsearch...');
[mejor_eta, mejor_mse] = fminsearch(@(eta) simula_y_retorna_mse(netCL, y_ref, delay, eta), etainit, opts);

%% Display results
fprintf('\n🌟 Optimal MRAC etas found: [%s]\n', num2str(mejor_eta));
fprintf('   Closed-loop MSE = %.6f\n', mejor_mse);

%% Objective function: closed-loop MSE for a given eta vector
function mse_total = simula_y_retorna_mse(narxCL, y_ref, delay, eta_vect)
    % Initialize MRAC with per-channel etas
    mrac = bloque4_init_mrac_eta_por_canal(6, 4, eta_vect, 'normalized2');
    % Simulate closed-loop
    [~, ~, E_hist, ~] = bloque5_simulacion_lazo_cerrado(narxCL, mrac, y_ref, delay);
    % Compute global MSE
    mse_total = mean(E_hist(:).^2);
    % Penalize if unstable or error
    if ~isfinite(mse_total)
        mse_total = 1e6;
    end
end
