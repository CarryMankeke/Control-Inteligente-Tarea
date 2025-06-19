% run_tune_mrac.m
%
% Purpose:
%   Load the optimal NARX closed-loop network and its selected delay (d_opt),
%   generate the real-flight reference trajectory, then optimize the MRAC
%   per‐channel learning rates (etas) using fminsearch. If tuning results
%   already exist, skip optimization. Saves the optimal etas and corresponding
%   MSE to disk.
%
% Usage:
%   Called by main.m after run_train_narx.
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function run_tune_mrac(cfg)
    %% Paths
    narxFile  = fullfile(cfg.paths.proc, 'best_narx_gridsearch.mat');
    etaFile   = fullfile(cfg.paths.log,  'optimals_etas.mat');

    %% 0) If tuning results already exist, load & skip
    if isfile(etaFile)
        S_prev = load(etaFile, 'bestEtas', 'bestMSE');
        fprintf('Tune MRAC: Found existing tuning results → bestMSE=%.6f\n', S_prev.bestMSE);
        return
    end

    %% 1) Load best NARX model and its optimal delay
    if ~isfile(narxFile)
        error('Best NARX model not found: %s', narxFile);
    end
    fprintf('Tune MRAC: Loading NARX model and d_opt from %s\n', narxFile);
    S      = load(narxFile, 'netCL', 'd_opt');
    netCL  = S.netCL;
    narxDelay = S.d_opt;  % use the delay found in grid search

    %% 2) Load real-flight reference trajectory
    fprintf('Tune MRAC: Loading real-flight reference (flight %d)\n', cfg.sim.flightIdx);
    rawFile = fullfile(cfg.paths.raw, 'AscTec_Pelican_Flight_Dataset.mat');
    y_ref   = get_flight_reference(rawFile, cfg.sim.flightIdx);

    %% 3) Optimize etas via fminsearch
    fprintf('Tune MRAC: Running fminsearch to optimize etas (using d = %d)\n', narxDelay);
    etaInit   = cfg.mrac.etaInit;
    opts      = cfg.tuning.opts;
    objective = @(etas) simula_y_retorna_mse(netCL, y_ref, narxDelay, etas);
    [bestEtas, bestMSE] = fminsearch(objective, etaInit, opts);

    %% 4) Save tuning results
    if ~exist(cfg.paths.log, 'dir')
        mkdir(cfg.paths.log);
    end
    fprintf('Tune MRAC: Saving optimal etas to %s\n', etaFile);
    save(etaFile, 'bestEtas', 'bestMSE');

    %% 5) Display summary
    fprintf('\n🌟 Optimal MRAC etas: [%s]\n', num2str(bestEtas));
    fprintf('   Achieved closed-loop MSE = %.6f\n', bestMSE);
end

%% Nested objective function
function mse_total = simula_y_retorna_mse(netCL, y_ref, delay, eta_vect)
    controller = init_mrac_controller(size(y_ref,1), size(y_ref,1)-2, eta_vect, 'normalized2');
    [~, ~, E_hist, ~] = simulate_closed_loop(netCL, controller, y_ref, delay);
    mse_total = mean(E_hist(:).^2);
    if ~isfinite(mse_total)
        mse_total = 1e6;
    end
end