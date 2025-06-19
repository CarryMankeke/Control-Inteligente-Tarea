% scripts/run_simulation_fcm.m
function run_simulation_fcm(cfg)
    % Paths
    logDir  = fullfile(cfg.paths.log, 'fcm');
    outFile = fullfile(logDir,  'metrics_fcm.mat');

    % 0) Skip if already done
    if isfile(outFile)
        fprintf('run_simulation_fcm: already computed, skipping (%s)\n', outFile);
        return
    end

    % 1) Load MRAC etas & reference trajectory
    load(fullfile(cfg.paths.log,'optimals_etas.mat'),'bestEtas');
    rawPath = fullfile(cfg.paths.raw,'AscTec_Pelican_Flight_Dataset.mat');
    y_ref   = get_flight_reference(rawPath, cfg.sim.flightIdx);

    % 2) Infer dimensions from splits
    Ssplit = load(fullfile(cfg.paths.proc,'perFlightSplits.mat'),'u_train');
    nIn     = size(Ssplit.u_train{1},1);
    nOut    = size(y_ref,1);

    % 3) Load FCM–NARX models
    fcmFile = fullfile(cfg.paths.proc,'fcm','fcm_narx.mat');
    load(fcmFile,'nets','centers','U');
    C = numel(nets);

    % 4) Initialize MRAC controller
    controller = init_mrac_controller(nOut, nIn, bestEtas, cfg.mrac.variant);

    % 5) Preallocate logs
    T      = size(y_ref,2);
    Y_hat  = zeros(nOut, T);
    U_hist = zeros(nIn,  T);
    E_hist = zeros(nOut, T);
    W_hist = zeros(nIn, nOut, T);

    % 6) Initialize history buffers
    delay = cfg.narx.delays(end);
    uHist = zeros(nIn,  delay);
    yHist = zeros(nOut, delay);

    % 7) Prepare each net's internal states for closed-loop
    Xi = cell(C,1);
    Ai = cell(C,1);
    u0seq = con2seq(uHist);
    y0seq = con2seq(yHist);
    for j = 1:C
        if ~isempty(nets{j})
            [~, Xi{j}, Ai{j}] = preparets(nets{j}, u0seq, {}, y0seq);
        end
    end

    % 8) Closed-loop simulation with FCM–NARX predictions
    for t = delay+1 : T
        % (a) Build regressor for fuzzy membership
        xk = [uHist(:); yHist(:)];
        mu = computeMemberships(centers, xk, cfg.fcm.fuzzyExponent);

        % (b) Fuse per-cluster predictions
        y_t = zeros(nOut,1);
        for j = 1:C
            if isempty(nets{j}) || mu(j)==0
                continue
            end
            [yjSeq, Xi{j}, Ai{j}] = nets{j}(con2seq(uHist), Xi{j}, Ai{j});
            yj = cell2mat(yjSeq(end));
            y_t = y_t + mu(j)*yj;
        end

        % (c) MRAC control law and weight update
        e       = y_ref(:,t) - y_t;
        e(4:6)  = wrapToPi(e(4:6));
        u_t     = controller.compute_u(e);
        controller.W = controller.update_W(controller.W, u_t, e, controller.eta);

        % (d) Shift history buffers
        uHist = [uHist(:,2:end), u_t];
        yHist = [yHist(:,2:end), y_t];

        % (e) Log data
        Y_hat(:,t)    = y_t;
        U_hist(:,t)   = u_t;
        E_hist(:,t)   = e;
        W_hist(:,:,t) = controller.W;
    end

    % 9) Save metrics + full weight history
    if ~exist(logDir,'dir')
        mkdir(logDir);
    end
    metrics = computeCost(E_hist, U_hist, W_hist);
    save(outFile, 'metrics', 'W_hist');
    fprintf('run_simulation_fcm: saved metrics and W_hist to %s\n', outFile);
end