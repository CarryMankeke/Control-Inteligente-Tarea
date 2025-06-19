% scripts/run_train_fcm_narx.m
function run_train_fcm_narx(cfg)
    % Paths
    outDir  = fullfile(cfg.paths.proc, 'fcm');
    outFile = fullfile(outDir, 'fcm_narx_weighted.mat');

    % 0) Skip if already done
    if isfile(outFile)
        fprintf('run_train_fcm_narx: already processed, skipping (%s)\n', outFile);
        return
    end

    % 1) Load per‐flight splits
    S = load(fullfile(cfg.paths.proc, 'perFlightSplits.mat'), 'u_train', 'y_train');
    u_train = S.u_train;  % 1×F cell array of 4×N_f
    y_train = S.y_train;  % 1×F cell array of 6×N_f

    % 2) Build regressor matrix X for FCM
    delay = cfg.narx.delays(end);
    X     = extractRegressors(u_train, y_train, delay);  % (4+6)*delay × N_total

    % 3) Perform FCM
    [centers, U] = performFCM(X, cfg.fcm.numClusters, cfg.fcm.fuzzyExponent);
    % U is C×N_total

    % 4) Concatenate all data
    bigU = horzcat(u_train{:});  % 4×N_total
    bigY = horzcat(y_train{:});  % 6×N_total
    N    = size(bigU,2);

    % 5) Train one NARX per cluster via replication
    nets    = cell(cfg.fcm.numClusters,1);
    metrics = struct('trainMSE',{},'valMSE',{});
    factor  = cfg.fcm.repeatFactor;  % e.g. 10

    for j = 1:cfg.fcm.numClusters
        mu = U(j,:);                 % 1×N_total
        reps = max(1, round(factor * mu));  % 1×N_total
        % replicate each column k reps(k) times
        Ucells = arrayfun(@(k) repmat(bigU(:,k), 1, reps(k)), 1:N, 'uni',false);
        Ycells = arrayfun(@(k) repmat(bigY(:,k), 1, reps(k)), 1:N, 'uni',false);
        uRep   = [Ucells{:}];        % 4×sum(reps)
        yRep   = [Ycells{:}];        % 6×sum(reps)

        % Train NARX on replicated data
        tempFile = fullfile(outDir, sprintf('narx_net_cl_%d.mat', j));
        [~, netCL, trMSE, valMSE] = train_narx_network( ...
            uRep, yRep, uRep, yRep, ...
            delay, cfg.narx.hiddenUnits(end), tempFile);

        nets{j}            = netCL;
        metrics(j).trainMSE = trMSE;
        metrics(j).valMSE   = valMSE;
        fprintf('  Cluster %d: trainMSE=%.6f, valMSE=%.6f\n', j, trMSE, valMSE);
    end

    % 6) Save results
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end
    save(outFile, 'nets', 'centers', 'U', 'metrics');
    fprintf('run_train_fcm_narx: saved weighted FCM-NARX models to %s\n', outFile);
end