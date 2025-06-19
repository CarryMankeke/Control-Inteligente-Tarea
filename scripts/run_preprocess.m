% run_preprocess.m
%
% Purpose:
%   Check for existing processed data; if missing, generate it.
%   Then, for each flight in cfg.sim.trainFlights, load raw data,
%   preprocess it (normalize, smooth, split into train/val/test),
%   and save all per-flight splits to disk for downstream steps.
%   If splitting already exists, skip processing.
%
% Usage:
%   Called by main.m. Saves per-flight split data to disk.
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function run_preprocess(cfg)
    %% Paths
    rawFile   = fullfile(cfg.paths.raw,  'AscTec_Pelican_Flight_Dataset.mat');
    procFile  = fullfile(cfg.paths.proc, 'quadrotorData.mat');
    splitFile = fullfile(cfg.paths.proc, 'perFlightSplits.mat');

    %% Ensure processed-data folder exists
    if ~exist(cfg.paths.proc, 'dir')
        mkdir(cfg.paths.proc);
    end

    %% Step 0: Build 'quadrotorData.mat' if missing
    if ~isfile(procFile)
        fprintf('Preprocess: Building %s from raw dataset...\n', procFile);
        build_quadrotor_data(rawFile, procFile);
    else
        fprintf('Preprocess: Found existing %s, skipping build.\n', procFile);
    end

    %% Step 1: If per-flight splits already exist, skip
    if isfile(splitFile)
        fprintf('Preprocess: Found existing splits at %s, skipping per-flight processing.\n', splitFile);
        return
    end

    %% Step 2: Per-flight preprocessing and splits
    fprintf('Preprocess: Processing flights %s\n', mat2str(cfg.sim.trainFlights));
    clear u_train y_train u_val y_val u_test y_test

    rawData = load(rawFile, 'flights');  % load once
    for f = cfg.sim.trainFlights
        fprintf('  Flight %d: loading and splitting...\n', f);
        fl  = rawData.flights{f};

        U   = fl.Motors_CMD';    % 4×N
        Pos = fl.Pos';           % 3×N
        Eul = fl.Euler';         % 3×N

        Yraw = [Pos; Eul];

        [u_tr, y_tr, u_v, y_v, u_te, y_te] = ...
            preprocess_data_fromXY(U, Yraw, ...
                                  cfg.dataSplit.trainRatio, ...
                                  cfg.dataSplit.valRatio);

        u_train{f} = u_tr;   y_train{f} = y_tr;
        u_val{f}   = u_v;    y_val{f}   = y_v;
        u_test{f}  = u_te;   y_test{f}  = y_te;
    end

    %% Step 3: Save all per-flight splits
    save(splitFile, 'u_train', 'y_train', 'u_val', 'y_val', 'u_test', 'y_test');
    fprintf('Preprocess: Saved per-flight splits to %s\n', splitFile);
end