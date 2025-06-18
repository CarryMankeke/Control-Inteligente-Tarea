% GRID SEARCH FOR NARX MIMO HYPERPARAMETERS
%
% Description:
%   Evaluates combinations of input/output delays (d) and hidden-layer sizes (H)
%   for a NARX MIMO network on a held-out validation set. Selects and saves the
%   network with the lowest validation mean squared error (MSE).
%
% Prerequisites:
%   - Workspace variables: u_train, y_train, u_val, y_val
%   - Function on path: bloque2_narx_train
%
% Usage:
%   Run this script immediately after data preprocessing. It will:
%     1) Test delays d = [2,3,4,5] and hidden units H = [10,20].
%     2) Choose the (d,H) pair with lowest val MSE.
%     3) Save the optimal network and parameters in 'best_narx_gridsearch.mat'.
%
% Outputs (saved to .mat):
%   narx_net_opt (network) : Optimal closed-loop NARX network.
%   d_opt        (integer) : Optimal number of delays.
%   H_opt        (integer) : Optimal number of hidden neurons.
%   bestValMSE   (double)  : Validation MSE for the optimal network.
% -----------------------------------------------------------------------------

clc; clear; close all;
%% Hyperparameter ranges
delayList  = [2, 3, 4, 5];   % input/output delays to try
hiddenList = [10, 20];       % hidden-layer sizes to try

bestValMSE   = inf;          % initialize best validation error
d_opt        = NaN;          % best delay
H_opt        = NaN;          % best hidden layer size
narx_net_opt = [];           % best network

%% Grid search loop
fprintf('🔍 Performing grid search over NARX hyperparameters...\n');
for dTry = delayList
    for HTry = hiddenList
        fprintf('  Testing d = %d, H = %d … ', dTry, HTry);

        % Train and return validation MSE
        [netSP, netCL, trainMSE, valMSE] = ...
            bloque2_narx_train(u_train, y_train, u_val, y_val, dTry, HTry);

        fprintf('val MSE = %.6f\n', valMSE);

        % Update best if improved
        if valMSE < bestValMSE
            bestValMSE   = valMSE;
            d_opt        = dTry;
            H_opt        = HTry;
            narx_net_opt = netCL;  % closed-loop version for simulation
        end
    end
end

%% Save optimal model and parameters
save('best_narx_gridsearch.mat', 'narx_net_opt', 'd_opt', 'H_opt', 'bestValMSE');

%% Report results
fprintf('\n✅ Grid search complete.\n');
fprintf('   Optimal NARX: d = %d, H = %d → validation MSE = %.6f\n', ...
        d_opt, H_opt, bestValMSE);
