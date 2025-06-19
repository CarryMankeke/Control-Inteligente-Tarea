% run_simulation.m
%
% Purpose:
%   Load the final NARX model and tuned MRAC parameters, generate the real-flight
%   reference trajectory, run the closed-loop simulation with MRAC + NARX,
%   compute and save performance metrics, evaluate NARX in open-loop on test data,
%   and write all raw logs (no plotting here).
%
% Usage:
%   Called by main.m after run_tune_mrac.
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

% run_simulation.m
function run_simulation(cfg)
    %% --- 1) Get test data for the specified flight ---
    rawFile = fullfile(cfg.paths.raw, 'AscTec_Pelican_Flight_Dataset.mat');
    if ~isfile(rawFile)
        error('Raw dataset not found: %s', rawFile);
    end
    raw = load(rawFile,'flights');
    idx = cfg.sim.flightIdx;
    if idx<1 || idx>numel(raw.flights)
        error('flightIdx %d out of range', idx);
    end
    fl     = raw.flights{idx};
    U_full = fl.Motors_CMD';    % 4×N
    Y_full = [fl.Pos'; fl.Euler']; % 6×N

    % Preprocess & split: we only need the test portion for simulation
    [~, ~, ~, ~, u_test, y_test] = ...
        preprocess_data_fromXY(U_full, Y_full, ...
                              cfg.dataSplit.trainRatio, ...
                              cfg.dataSplit.valRatio);

    %% --- 2) Load NARX closed-loop model and delay ---
    narxFile  = fullfile(cfg.paths.proc, 'best_narx_gridsearch.mat');
    S2        = load(narxFile, 'netCL', 'd_opt');
    netCL     = S2.netCL;
    narxDelay = S2.d_opt;

    %% --- 3) Load MRAC tuning results ---
    etaFile = fullfile(cfg.paths.log, 'optimals_etas.mat');
    S3      = load(etaFile, 'bestEtas');
    etas    = S3.bestEtas;

    %% --- 4) Build real-flight reference trajectory ---
    y_ref = get_flight_reference(rawFile, idx);

    %% --- 5) Initialize controller & simulate ---
    controller = init_mrac_controller(size(y_ref,1), size(u_test,1), ...
                                      etas, cfg.mrac.variant);
    [Y_hat, U_hist, E_hist, W_hist] = ...
        simulate_closed_loop(netCL, controller, y_ref, narxDelay);

    %% --- 6) Save logs & compute metrics ---
    if ~exist(cfg.paths.log,'dir'), mkdir(cfg.paths.log); end
    save(fullfile(cfg.paths.log,'simulation_metrics.mat'), ...
         'U_hist','E_hist','W_hist');
    metrics = computeCost(E_hist, U_hist, W_hist);
    save(fullfile(cfg.paths.log,'metrics_summary.mat'),'metrics');

%% --- 7) Open-loop NARX on test data ---
netOpen = load(narxFile,'netSP').netSP;
[Xt,Xi,Ai,~] = preparets(netOpen, ...
    con2seq(u_test), {}, con2seq(y_test));
Yt = netOpen(Xt,Xi,Ai);
y_pred_open = cell2mat(Yt);

% --- Alineación por retraso ---
delay = narxDelay;  % el mismo d_opt que usaste para entrenar
y_test_aligned = y_test(:, delay+1 : end);

% Verificación de tamaños
assert( size(y_pred_open,2) == size(y_test_aligned,2), ...
    'Dimensiones tras recorte no coinciden.' );

% Cálculo del error en abierto
E_open = y_test_aligned - y_pred_open;

metrics_open = computeCost(E_open, [], []);
save(fullfile(cfg.paths.log,'metrics_openloop.mat'),'metrics_open');
end