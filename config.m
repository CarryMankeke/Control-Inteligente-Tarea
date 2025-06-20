% config.m
%
% Purpose:
%   Central configuration for the PP2 – Adaptive Control Quadcopter framework.
%   Defines file paths, data split ratios, hyperparameters, and simulation settings.
%
% Usage:
%   Call `cfg = config();` at the start of your scripts to retrieve all settings.
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function cfg = config()
    %% Project root
    cfg.root = fileparts(mfilename('fullpath'));

    %% Paths
    cfg.paths.raw    = fullfile(cfg.root, 'data', 'raw');
    cfg.paths.proc   = fullfile(cfg.root, 'data', 'processed');
    cfg.paths.log        = fullfile(cfg.root, 'results', 'log');
    cfg.paths.fig        = fullfile(cfg.root, 'results', 'figures');


    %% Data split ratios
    cfg.dataSplit.trainRatio = 0.70;
    cfg.dataSplit.valRatio   = 0.15;
    
    %cfg.sim.trainFlights = 1:20;
    %cfg.sim.trainFlights = 1:2;

    cfg.sim.trainFlights = 1;

    %% NARX grid-search hyperparameters
    cfg.narx.delays      = 3; %[2, 3, 4];
    cfg.narx.hiddenUnits = 10; %[10, 20]; 

    %% MRAC initial etas (for fminsearch) and variant
    cfg.mrac.etaInit = [0.0516829444444445,	0.0493846222222222, 0.0516687888888889,	0.0721882777777778,	0.0723348888888889,	0.102740777777778];
    cfg.mrac.variant = 'normalized2';

    %% Reference flight (use last flight by default)
    cfg.sim.flightIdx = 2;

    %% Reproducibility
    cfg.seed = 42;

    %% fminsearch options
    cfg.tuning.opts = optimset('Display','iter', ...
                               'TolFun',1e-5, 'TolX',1e-5, ...
                               'MaxIter',1,  'MaxFunEvals',1); % 10 , 30

%% FCM parameters
    cfg.fcm.numClusters    = 5;    % Fuzzy Clusters Number
    cfg.fcm.fuzzyExponent  = 2.0;  % m exponent in FCM
    cfg.fcm.repeatFactor  = 1;   % optional: max replicates per sample (10 usado)

end