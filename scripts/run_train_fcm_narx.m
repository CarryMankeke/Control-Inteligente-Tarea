% scripts/run_train_fcm_narx.m
function run_train_fcm_narx(cfg)
    % Paths
    outDir  = fullfile(cfg.paths.proc, 'fcm');
    outFile = fullfile(outDir, 'fcm_narx.mat');

    % 0) Skip if already done
    if isfile(outFile)
        fprintf('run_train_fcm_narx: already processed, skipping (%s)\n', outFile);
        return
    end

    % 1) Load splits
    S = load(fullfile(cfg.paths.proc, 'perFlightSplits.mat'), 'u_train', 'y_train');
    u_train = S.u_train;
    y_train = S.y_train;

    % 2) Build regressor matrix
    delay = cfg.narx.delays(end);
    X     = extractRegressors(u_train, y_train, delay);

    % 3) FCM clustering
    [centers, U] = performFCM(X, cfg.fcm.numClusters, cfg.fcm.fuzzyExponent);

    % 4) Train one NARX per cluster
    nets = cell(cfg.fcm.numClusters,1);
    for j = 1:cfg.fcm.numClusters
        idx = find(U(j,:) > cfg.fcm.memThreshold);
        if numel(idx) < 50
            warning('Cluster %d has %d samples. Skipping.', j, numel(idx));
            continue;
        end
        u_j = reconstructCells(u_train, idx, delay);
        y_j = reconstructCells(y_train, idx, delay);
        [~, netCL, ~, ~] = train_narx_network(...
            u_j, y_j, u_j, y_j, ...
            delay, cfg.narx.hiddenUnits(end), tempname);
        nets{j} = netCL;
    end

    % 5) Save
    if ~exist(outDir,'dir'), mkdir(outDir); end
    save(outFile,'nets','centers','U');
    fprintf('run_train_fcm_narx: saved to %s\n', outFile);
end