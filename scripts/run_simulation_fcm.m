% scripts/run_simulation_fcm.m
function run_simulation_fcm(cfg)
    % Paths
    logDir  = fullfile(cfg.paths.log, 'fcm');
    outFile = fullfile(logDir, 'metrics_fcm.mat');

    % 0) Skip if already done
    if isfile(outFile)
        fprintf('run_simulation_fcm: already computed, skipping (%s)\n', outFile);
        return
    end

    % 1) Load MRAC etas & reference
    load(fullfile(cfg.paths.log,'optimals_etas.mat'),'bestEtas');
    rawPath = fullfile(cfg.paths.raw,'AscTec_Pelican_Flight_Dataset.mat');
    y_ref   = get_flight_reference(rawPath, cfg.sim.flightIdx);

    % 2) Infer input dim from splits
    S    = load(fullfile(cfg.paths.proc,'perFlightSplits.mat'),'u_train');
    nIn  = size(S.u_train{1},1);
    nOut = size(y_ref,1);

    % 3) Load FCM-NARX
    fcmFile = fullfile(cfg.paths.proc,'fcm','fcm_narx.mat');
    load(fcmFile,'nets','centers','U');

    % 4) Init MRAC
    controller = init_mrac_controller(nOut, nIn, bestEtas, cfg.mrac.variant);

    % 5) Preallocate logs
    T      = size(y_ref,2);
    Y_hat  = zeros(nOut, T);
    U_hist = zeros(nIn,  T);
    E_hist = zeros(nOut, T);
    W_hist = zeros(nIn, nOut, T);

    % 6) Buffers
    delay = cfg.narx.delays(end);
    uHist = zeros(nIn, delay);
    yHist = zeros(nOut, delay);

    % 7) Simulation loop
    for t = delay+1:T
        xk = [uHist(:); yHist(:)];
        mu = computeMemberships(centers, xk, cfg.fcm.fuzzyExponent);

        % aggregate only non-empty clusters
        y_t = zeros(nOut,1);
        for j = 1:numel(nets)
            if isempty(nets{j}) || mu(j)==0
                continue
            end
            net = nets{j};
            x_seq = con2seq(xk(end-2*delay+1:end)); % adjust indices if needed
            yj_seq = net(x_seq);
            yj = cell2mat(yj_seq(end));
            y_t = y_t + mu(j)*yj;
        end

        % MRAC update
        e = y_ref(:,t) - y_t; e(4:6)=wrapToPi(e(4:6));
        u_t = controller.compute_u(e);
        controller.W = controller.update_W(controller.W, u_t, e, controller.eta);

        % update buffers
        uHist = [uHist(:,2:end), u_t];
        yHist = [yHist(:,2:end), y_t];

        % log
        Y_hat(:,t)     = y_t;
        U_hist(:,t)    = u_t;
        E_hist(:,t)    = e;
        W_hist(:,:,t)  = controller.W;
    end
    
    %% 8) Compute and save performance metrics + weight history
    if ~exist(logDir,'dir')
        mkdir(logDir);
    end
    metrics = computeCost(E_hist, U_hist, W_hist);
    save(outFile, 'metrics', 'W_hist');
    fprintf('run_simulation_fcm: saved metrics and W_hist to %s\n', outFile);
end