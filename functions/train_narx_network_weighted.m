function [netSP, netCL, trainMSE, valMSE] = ...
    train_narx_network_weighted(uTrain, yTrain, uVal, yVal, delay, hiddenUnits, weights, outputPath)
%TRAIN_NARX_NETWORK_WEIGHTED  Train a NARX with sample weights.
    net = narxnet(1:delay,1:delay,hiddenUnits);
    net.trainFcn            = 'trainlm';
    net.divideFcn           = 'divideblock';
    net.trainParam.showWindow = false;

    % Prepare sequences
    [Xtr,XiTr,AiTr,Ttr] = preparets(net, con2seq(uTrain), {}, con2seq(yTrain));
    [Xvl,XiVl,AiVl,Tvl] = preparets(net, con2seq(uVal),   {}, con2seq(yVal));

    % Train using MATLAB’s Weights argument
    [net, tr] = train(net, Xtr, Ttr, XiTr, AiTr, ...
                      'Weights', weights(tr.trainInd));

    % Performance metrics
    Ytr      = net(Xtr, XiTr, AiTr);
    trainMSE = perform(net, Ttr, Ytr);
    Yvl      = net(Xvl, XiVl, AiVl);
    valMSE   = perform(net, Tvl, Yvl);

    % Closed-loop version
    netSP = net;
    netCL = closeloop(netSP);
    netCL.name = 'Weighted FCM NARX CL';

    % Save
    outDir = fileparts(outputPath);
    if ~exist(outDir,'dir'), mkdir(outDir); end
    save(outputPath, 'netSP','netCL','trainMSE','valMSE');
end