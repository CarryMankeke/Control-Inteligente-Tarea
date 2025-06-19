% run_train_narx.m
%
% Purpose:
%   Carga los splits por vuelo, hace grid-search validando en cada uno,
%   luego retrena en conjunto y guarda el mejor modelo y sus métricas.
%
% Usage:
%   Llamado por main.m tras run_preprocess.
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function run_train_narx(cfg)
    %% Paths
    splitsFile = fullfile(cfg.paths.proc, 'perFlightSplits.mat');
    outFile    = fullfile(cfg.paths.proc, 'best_narx_gridsearch.mat');

    %% 0) Si ya existe el modelo, lo carga y sale
    if isfile(outFile)
        S = load(outFile, 'd_opt','H_opt','trainMSE','valMSE');
        fprintf('Train NARX: Modelo ya existente → d=%d, H=%d, trainMSE=%.6f, valMSE=%.6f\n', ...
                S.d_opt, S.H_opt, S.trainMSE, S.valMSE);
        return
    end

    %% 1) Cargar splits por vuelo
    if ~isfile(splitsFile)
        error('No existe perFlightSplits.mat: %s', splitsFile);
    end
    S = load(splitsFile, 'u_train','y_train','u_val','y_val');
    flights = cfg.sim.trainFlights;
    fprintf('Train NARX: Splits cargados para vuelos %s\n', mat2str(flights));

    %% 2) Grid-search validando en cada vuelo
    bestValMSE = inf;
    d_opt      = NaN;
    H_opt      = NaN;

    fprintf('Train NARX: Iniciando grid search...\n');
    for dTry = cfg.narx.delays
        for Htry = cfg.narx.hiddenUnits
            valErrors = zeros(numel(flights),1);
            for k = 1:numel(flights)
                f = flights(k);
                % entrenar con split del vuelo f
                [~, ~, ~, valMSE] = train_narx_network( ...
                    S.u_train{f}, S.y_train{f}, ...
                    S.u_val{f},   S.y_val{f}, ...
                    dTry, Htry, tempname );
                valErrors(k) = valMSE;
            end
            avgValMSE = mean(valErrors);
            fprintf('  d=%d, H=%d → avg val MSE = %.6f\n', dTry, Htry, avgValMSE);
            if avgValMSE < bestValMSE
                bestValMSE = avgValMSE;
                d_opt      = dTry;
                H_opt      = Htry;
            end
        end
    end

 %% 3) Retrain óptimo sobre todos los vuelos concatenados (pre–alocado)
    fprintf('Train NARX: Reentrenando modelo final con d=%d, H=%d\n', d_opt, H_opt);

    % Calcular número total de muestras para pre–alocar
    totalTrain = 0;
    totalVal   = 0;
    for k = 1:numel(flights)
        f = flights(k);
        totalTrain = totalTrain + size(S.u_train{f}, 2);
        totalVal   = totalVal   + size(S.u_val{f},   2);
    end

    % Pre–alocar matrices
    U_dim = size(S.u_train{flights(1)},1);
    Y_dim = size(S.y_train{flights(1)},1);
    U_all  = zeros(U_dim, totalTrain);
    Y_all  = zeros(Y_dim, totalTrain);
    Uv_all = zeros(U_dim, totalVal);
    Yv_all = zeros(Y_dim, totalVal);

    % Rellenar los datos concatenados
    idxT = 1;
    idxV = 1;
    for k = 1:numel(flights)
        f = flights(k);
        nT = size(S.u_train{f},2);
        U_all(:, idxT:idxT+nT-1)  = S.u_train{f};
        Y_all(:, idxT:idxT+nT-1)  = S.y_train{f};
        idxT = idxT + nT;

        nV = size(S.u_val{f},2);
        Uv_all(:, idxV:idxV+nV-1) = S.u_val{f};
        Yv_all(:, idxV:idxV+nV-1) = S.y_val{f};
        idxV = idxV + nV;
    end

    % Entrenar la red final con los datos completos
    [netSP, netCL, trainMSE, valMSE] = train_narx_network( ...
        U_all, Y_all, Uv_all, Yv_all, ...
        d_opt, H_opt, outFile);

    %% 4) Guardar resultados finales
    fprintf('Train NARX: Guardando modelo y métricas en %s\n', outFile);
    save(outFile, 'netSP','netCL','d_opt','H_opt','trainMSE','valMSE');

    %% 5) Reporte
    fprintf('\n✅ Grid search completado.\n');
    fprintf('   Mejor d = %d, H = %d\n', d_opt, H_opt);
    fprintf('   Training MSE = %.6f, Validation MSE = %.6f\n', trainMSE, valMSE);
end