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

    % 1) Load per-flight splits
    S = load(fullfile(cfg.paths.proc, 'perFlightSplits.mat'), ...
             'u_train', 'y_train');
    u_train = S.u_train;   % 1×F cell array of 4×N_f matrices
    y_train = S.y_train;   % 1×F cell array of 6×N_f matrices

    % 2) Build global regressor matrix X for FCM
    delay = cfg.narx.delays(end);
    X     = extractRegressors(u_train, y_train, delay);  % D*d × N_total

    % 3) Perform FCM clustering
    [centers, U] = performFCM(X, cfg.fcm.numClusters, cfg.fcm.fuzzyExponent);
    % centers: C×D*d, U: C×N_total

    % 4) Concatenate all data for weighted training
    bigU = horzcat(u_train{:});  % 4×N_total
    bigY = horzcat(y_train{:});  % 6×N_total

    % 5) Train one weighted NARX per fuzzy cluster
    nets    = cell(cfg.fcm.numClusters,1);
    metrics = struct('trainMSE',[],'valMSE',[]);
    for j = 1:cfg.fcm.numClusters
        % normalize membership weights for this cluster
        w = U(j,:) / sum(U(j,:));  % 1×N_total

        % train with sample weights
        tempFile = fullfile(outDir, sprintf('narx_net_cl_%d.mat', j));
        [~, netCL, trMSE, valMSE] = train_narx_network_weighted( ...
            bigU, bigY, bigU, bigY, ...
            delay, cfg.narx.hiddenUnits(end), ...
            w, tempFile);

        nets{j}          = netCL;
        metrics(j).trainMSE = trMSE;
        metrics(j).valMSE   = valMSE;
        fprintf(' Trained weighted NARX for cluster %d → trainMSE=%.6f, valMSE=%.6f\n', ...
                j, trMSE, valMSE);
    end

    % 6) Save everything
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    save(outFile, 'nets', 'centers', 'U', 'metrics');
    fprintf('run_train_fcm_narx: saved weighted FCM-NARX models to %s\n', outFile);
end