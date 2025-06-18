% Simulation of Adaptive Control NARX + MRAC for a Quadcopter
%
% Dataset source:
%   WaveLab AscTec Pelican Flight Dataset
%   http://wavelab.uwaterloo.ca/index3390.html?page_id=705
%
% Author:       Camilo Andrés Soto Villegas
% ID:           21.010.277-9
% Program:      Civil Mechatronic Engineering
% University:   University of Santiago de Chile
% Department:   Mechanical Engineering
% Email:        camilo.soto.v@usach.cl
%
% Course:       Intelligent Control
% Professor:    Mohammad Hosein Sabzalian
% Prof. Email:  mohammadhosein.sabzalian@usach.cl
%
% Description:
%   Loads the flight dataset, trains a NARX MIMO network, creates a sine-wave
%   reference trajectory, initializes a MRAC controller with per-channel
%   learning rates (etas), performs closed-loop simulation, and visualizes
%   results.
% -----------------------------------------------------------------------------

clc; clear; close all;
rng(42);   % ensure full-pipeline reproducibility


%% STEP 0: Generate 'quadrotorData.mat' if missing

fprintf("Simulation of Adaptive Control NARX + MRAC for Quadcopter\n\n");
if ~isfile('quadrotorData.mat')
    fprintf("  Generating 'quadrotorData.mat' from original dataset...\n");
    crear_quadrotorData();  % Extracts U,Y from AscTec_Pelican dataset
else
    fprintf("  'quadrotorData.mat' already exists. Continuing...\n");
end


%% BLOCK 1: Load and preprocess data

fprintf("Loading and preprocessing data...\n");
[u_train, y_train, u_val, y_val, u_test, y_test] = ...
    bloque1_preproceso('quadrotorData.mat', 0.7, 0.15);  % 70% train, 15% val, 15% test

%% Hyperparameters (tuned offline)
%   • NARX grid-search:
%       delays tested = [2,3,4,5]
%       hidden units tested = [10,20]
%       ⇒ Best NARX: d = 3, H = 10  (val MSE = 0.0000)

%   • MRAC fminsearch:
%       eta = [eta_x, eta_y, eta_z, eta_roll, eta_pitch, eta_yaw]
%           = [0.051115, 0.050507, 0.051101, 0.071395, 0.071540, 0.099160]
%       ⇒ Closed-loop MSE = 0.790417



%% BLOCK 2: Train NARX MIMO network

fprintf("Training NARX MIMO network...\n");
d = 3;    % Number of delays
H = 10;   % Hidden neurons
[netOpen, narx_net, mse_train, mse_val] = ...
    bloque2_narx_train(u_train, y_train, u_val, y_val, d, H);


%% BLOCK 3: Generate and normalize reference trajectory (100 Hz)

duration = 20;       % Duration in seconds
dt       = 0.01;     % Time step in seconds (100 Hz)
freq     = 1 / dt;   % Sampling frequency in Hz

% Now Ts will be 0.01 and T = duration/dt + 1 = 2001
[y_ref, T, Ts] = bloque3_generar_referencia(duration, freq);

% Normalize position channels to [-1,1]
y_ref(1:3, :) = mapminmax(y_ref(1:3, :), -1, 1);

% Normalize orientation channels to [-1,1]
y_ref(4:6, :) = wrapToPi(y_ref(4:6, :)) / pi;


%% BLOCK 4: Initialize MRAC controller with per-channel learning rates

fprintf("Initializing MRAC controller...\n");
n_out    = size(y_ref, 1);   % Number of outputs (6)
n_in     = size(u_train, 1); % Number of inputs (4)
eta_vect = [0.051115, 0.050507, 0.051101, ...  % [X, Y, Z, Roll, Pitch, Yaw]
            0.071395, 0.071540, 0.099160];
mrac = bloque4_init_mrac_eta_por_canal(n_out, n_in, eta_vect, 'normalized2');


%% BLOCK 5: Closed-loop simulation with MRAC + NARX

fprintf("Running closed-loop simulation (estimated feedback)...\n");
narx_net_cl = closeloop(narx_net);
[Y_hat, U_hist, E_hist, W_hist] = ...
    bloque5_simulacion_lazo_cerrado(narx_net_cl, mrac, y_ref, d);


%% RESULTS: Numeric outputs

fprintf(" ΔW(1,1): %.8f\n", W_hist(1,1,end) - W_hist(1,1,1));
fprintf(" ΔW(2,2): %.8f\n", W_hist(2,2,end) - W_hist(2,2,1));
max_u = max(abs(U_hist(:)));
fprintf(" Max |u(t)|: %.6f\n", max_u);


%% BLOCK 6: Plot simulation results

fprintf("Displaying simulation results...\n");
bloque6_plot_resultados(y_ref, Y_hat, E_hist, U_hist, W_hist);


%% STEP A: Evaluate NARX open-loop on real test data

fprintf("Evaluating NARX open-loop on real test data...\n");
uTestSeq = con2seq(u_test);
yTestSeq = con2seq(y_test);
[Xt, Xit, Ait, Tt] = preparets(netOpen, uTestSeq, {}, yTestSeq);
Yt = netOpen(Xt, Xit, Ait);
mse_narx = perform(netOpen, Tt, Yt);
fprintf(" MSE NARX open-loop on test: %.6f\n\n", mse_narx);


%% STEP B: Evaluate MRAC closed-loop on reference trajectory

fprintf("Evaluating MRAC closed-loop on reference...\n");
mse_mrac = mean(E_hist(:).^2);
fprintf(" MSE MRAC closed-loop: %.6f\n\n", mse_mrac);

% Per-channel MSE
channels = {'X','Y','Z','Roll','Pitch','Yaw'};
mse_by_channel = mean(E_hist.^2, 2);
fprintf(" MSE per channel:\n");
for i = 1:6
    fprintf("   %s: %.6f\n", channels{i}, mse_by_channel(i));
end


%% OPTIONAL: Plot NARX open-loop performance on test data

y_pred_real = cell2mat(Yt);

figure;
for i = 1:6
    subplot(3,2,i);
    plot(y_test(i,:),     'k--'); hold on;
    plot(y_pred_real(i,:), 'b');        % <-- numeric row indexing, no error
    title(sprintf("Real vs Predicted – %s", channels{i}));
    legend("Real","Predicted","Location","best");
    grid on;
end
sgtitle("NARX Open-Loop Performance on Test Data");
