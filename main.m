% main.m
%
% Purpose:
%   High-level orchestrator for the PP2 – Adaptive Control Quadcopter framework.
%   Executes preprocessing, NARX training, MRAC tuning, and simulation in order.
%
% Usage:
%   Simply run `main` in MATLAB Command Window after opening the PP2 project.
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function main()
    clc;         % clear command window
    clearvars;   % clear all variables in the base workspace
    close all;   % close any open figure windows
    %% Initialize environment
    startup;                % set up MATLAB paths
    cfg = config();         % load global configuration

    %% Set random seed for reproducibility
    rng(cfg.seed);

    %% 1) Preprocessing and data generation
    run_preprocess(cfg);

    %% 2) Train NARX model (with grid search)
    run_train_narx(cfg);

    %% 3) Optimize MRAC learning rates via fminsearch
    run_tune_mrac(cfg);

    %% 4) Perform closed-loop simulation and generate outputs
    run_simulation(cfg);
    %%
    run_train_fcm_narx(cfg);
    run_simulation_fcm(cfg);

    %% 5) Plot Results
    plot_all_results(cfg);
    plot_compare_results(cfg);

    fprintf('\nAll steps completed successfully.\n');
end