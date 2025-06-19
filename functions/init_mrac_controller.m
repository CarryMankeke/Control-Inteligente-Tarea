% init_mrac_controller.m
%
% Purpose:
%   Initialize a Model Reference Adaptive Controller (MRAC) struct for MIMO
%   systems, with per-channel learning rates and selectable MIT Rule variant.
%
% Usage:
%   controller = init_mrac_controller(nOut, nIn, etaVect, variant);
%
% Inputs:
%   nOut    — number of output channels (e.g., 6)
%   nIn     — number of input channels (e.g., 4)
%   etaVect — 1×nOut vector of learning rates per channel
%   variant — string: 'normal' | 'normalized1' | 'normalized2' | 'constant'
%
% Output:
%   controller — struct with fields:
%       W           (nIn×nOut) initial weights
%       eta         (1×nOut)  learning rates
%       compute_u   (@(e))    function to compute control input
%       update_W    (@(W,u,e,eta)) weight-update function
%
% Notes:
%   • W initialized small random to avoid symmetry issues.
%   • Original MIT Rule variants:
%       - "normal":     Standard MIT Rule update (ΔW = η * u * e^T)
%       - "normalized1": Divide by |e^T * e| to mitigate large errors
%       - "normalized2": Divide by (1 + ‖e‖^2) for numerical stability
%       - "constant":   Fixed divisor (0.1) to cap update magnitude
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function controller = init_mrac_controller(nOut, nIn, etaVect, variant)
    %% Input validation
    if nargin < 4
        variant = 'normal';
    end
    if numel(etaVect) ~= nOut
        error('etaVect must be a 1×%d vector.', nOut);
    end

    %% Initialize controller struct
    controller.W   = 0.01 * randn(nIn, nOut);
    controller.eta = etaVect(:)';  % ensure row vector

    %% Control law: u = W * e
    controller.compute_u = @(e) controller.W * e;

    %% Select weight-update rule based on variant
    switch lower(variant)
        case 'normal'  % "normal": Standard MIT Rule update (ΔW = η * u * e^T)
            controller.update_W = @(W, u, e, eta) W + u * ((eta(:) .* e(:))');
        case 'normalized1'  % "normalized1": MIT Rule normalized by |e^T * e|
            controller.update_W = @(W, u, e, eta) ...
                W + (u * ((eta(:) .* e(:))')) / (1e-6 + abs(e' * e));
        case 'normalized2'  % "normalized2": MIT Rule normalized by (1 + ‖e‖^2)
            controller.update_W = @(W, u, e, eta) ...
                W + (u * ((eta(:) .* e(:))')) / (1 + norm(e)^2);
        case 'constant'  % "constant": MIT Rule with fixed divisor (0.1)
            controller.update_W = @(W, u, e, eta) ...
                W + (u * ((eta(:) .* e(:))')) / 0.1;
        otherwise
            error('Unknown variant: %s', variant);
    end
end