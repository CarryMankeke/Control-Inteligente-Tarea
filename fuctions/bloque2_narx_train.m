% BLOCK 2: Train a NARX MIMO network in series–parallel (open-loop) and create
%          its closed-loop version for feedback estimation.
%
% Description:
%   Defines and trains a NARX network with specified input and feedback delays
%   and hidden layer size. Returns both the open-loop (series–parallel) and
%   closed-loop versions, along with training and validation mean squared errors.
%
% Arguments:
%   uTrain         (4×N_train double): Training inputs.
%   yTrain         (6×N_train double): Training targets.
%   uVal           (4×N_val   double): Validation inputs.
%   yVal           (6×N_val   double): Validation targets.
%   delay          (integer)           : Number of input/output delays (e.g., 3).
%   hiddenNeurons  (integer)           : Number of hidden neurons.
%
% Returns:
%   netSP    (network) : Trained series–parallel NARX network (open-loop).
%   netCL    (network) : Closed-loop version of netSP for feedback estimation.
%   trainPerf (double) : Training mean squared error (open-loop).
%   valPerf   (double) : Validation mean squared error (open-loop).
% -----------------------------------------------------------------------------

function [netSP, netCL, trainPerf, valPerf] = bloque2_narx_train(uTrain, yTrain, uVal, yVal, delay, hiddenNeurons)
    %% Create NARX network (series–parallel)
    inputDelays    = 1:delay;
    feedbackDelays = 1:delay;
    net = narxnet(inputDelays, feedbackDelays, hiddenNeurons);
    net.trainFcn = 'trainlm';
    net.trainParam.showWindow = false;
    net.divideFcn = 'divideblock';  % sequential division

    %% Prepare time series data
    uTrainSeq = con2seq(uTrain);
    yTrainSeq = con2seq(yTrain);
    uValSeq   = con2seq(uVal);
    yValSeq   = con2seq(yVal);

    [Xtr, XiTr, AiTr, Ttr] = preparets(net, uTrainSeq, {}, yTrainSeq);
    [Xvl, XiVl, AiVl, Tvl] = preparets(net, uValSeq,   {}, yValSeq);

    %% Train the series–parallel network
    net = train(net, Xtr, Ttr, XiTr, AiTr);

    %% Compute open-loop performance
    Ytr = net(Xtr, XiTr, AiTr);
    trainPerf = perform(net, Ttr, Ytr);

    Yvl = net(Xvl, XiVl, AiVl);
    valPerf = perform(net, Tvl, Yvl);

    %% Return series–parallel network
    netSP = net;

    %% Create closed-loop version for simulation
    netCL = closeloop(netSP);
    netCL.name = 'NARX MIMO Closed-Loop';

    %% Save models and performance metrics
    save('narx_mimo_nets.mat', 'netSP', 'netCL', 'trainPerf', 'valPerf');
end
