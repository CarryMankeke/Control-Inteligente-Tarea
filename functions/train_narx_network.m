% train_narx_network.m
%
% Purpose:
%   Define, train, and save a NARX MIMO network in series–parallel (open-loop)
%   configuration, then convert to closed-loop for feedback estimation.
%
% Usage:
%   [netSP, netCL, trainMSE, valMSE] = ...
%       train_narx_network(uTrain, yTrain, uVal, yVal, delay, hiddenUnits, outputPath);
%
% Inputs:
%   uTrain      — 4×N_train matrix of normalized training inputs  
%   yTrain      — 6×N_train matrix of normalized training targets  
%   uVal        — 4×N_val   matrix of normalized validation inputs  
%   yVal        — 6×N_val   matrix of normalized validation targets  
%   delay       — integer number of input/output delays (e.g., 3)  
%   hiddenUnits — integer number of hidden neurons (e.g., 10)  
%   outputPath  — full path where to save the trained networks and metrics  
%
% Outputs:
%   netSP    — trained series–parallel (open-loop) NARX network  
%   netCL    — closed-loop version of netSP for simulation  
%   trainMSE — mean squared error on training data  
%   valMSE   — mean squared error on validation data  
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function [netSP, netCL, trainMSE, valMSE] = ...
    train_narx_network(uTrain, yTrain, uVal, yVal, delay, hiddenUnits, outputPath)

    %% Create NARX network (series–parallel)
    net = narxnet(1:delay, 1:delay, hiddenUnits);
    net.trainFcn            = 'trainlm';
    net.trainParam.showWindow = false;
    net.divideFcn           = 'divideblock';  % sequential division

    %% Prepare time series data
    uTrainSeq = con2seq(uTrain);
    yTrainSeq = con2seq(yTrain);
    uValSeq   = con2seq(uVal);
    yValSeq   = con2seq(yVal);

    [Xtr, XiTr, AiTr, Ttr] = preparets(net, uTrainSeq, {}, yTrainSeq);
    [Xvl, XiVl, AiVl, Tvl] = preparets(net, uValSeq,   {}, yValSeq);

    %% Train the network
    net = train(net, Xtr, Ttr, XiTr, AiTr);

    %% Compute open-loop performance
    Ytr      = net(Xtr, XiTr, AiTr);
    trainMSE = perform(net, Ttr, Ytr);

    Yvl    = net(Xvl, XiVl, AiVl);
    valMSE = perform(net, Tvl, Yvl);

    %% Return series–parallel network
    netSP = net;

    %% Create closed-loop version
    netCL = closeloop(netSP);
    netCL.name = 'NARX MIMO Closed-Loop';

    %% Ensure output directory exists
    outDir = fileparts(outputPath);
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end

    %% Save models and performance metrics
    save(outputPath, 'netSP', 'netCL', 'trainMSE', 'valMSE');

    %% Log summary
    fprintf('✔ Trained NARX: delay=%d, hidden=%d → trainMSE=%.6f, valMSE=%.6f\n', ...
            delay, hiddenUnits, trainMSE, valMSE);
end