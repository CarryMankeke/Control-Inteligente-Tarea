% BLOCK 4: Initialize MRAC controller with per-channel learning rates
%
% Description:
%   Constructs a Model Reference Adaptive Controller (MRAC) for a MIMO system,
%   using independent learning rates for each output channel. The 'variant'
%   argument selects one of four normalization strategies for the MIT Rule
%   weight update, as follows:
%     • 'normal'      : Standard MIT Rule update (ΔW = u·e^T).
%     • 'normalized1' : MIT Rule normalized by |e^T·e| to mitigate large errors.
%     • 'normalized2' : MIT Rule normalized by (1 + ‖e‖^2) for numerical stability.
%     • 'constant'    : MIT Rule with fixed divisor (e.g., 0.1) to limit update size.
%
%   These variants are derived from classical adaptive control theory
%   (Åström & Wittenmark, _Adaptive Control_, 2nd Edition).
%
% Arguments:
%   nOut    (integer)    : Number of output channels (e.g. 6).
%   nIn     (integer)    : Number of input channels (e.g. 4).
%   etaVect (1×6 double) : Learning rates [eta_x, eta_y, eta_z,
%                          eta_roll, eta_pitch, eta_yaw].
%   variant (string)     : 'normal', 'normalized1', 'normalized2', or 'constant'.
%
% Returns:
%   controlador (struct): Adaptive controller with fields:
%     W           (nIn×nOut double)    : Initial weight matrix.
%     eta         (1×6 double)         : Learning rates per channel.
%     compute_u   (function_handle)    : Function to compute u = W * e.
%     update_W    (function_handle)    : Function to update W based on error.
% -----------------------------------------------------------------------------

function controlador = bloque4_init_mrac_eta_por_canal(nOut, nIn, etaVect, variant)
    %% Validate inputs
    if nargin < 4
        variant = 'normal';
    end
    if numel(etaVect) ~= 6
        error('etaVect must be a 1×6 vector: [eta_x, eta_y, eta_z, eta_roll, eta_pitch, eta_yaw].');
    end

    %% Initialize controller struct
    controlador.W   = 0.01 * randn(nIn, nOut);
    controlador.eta = etaVect;

    % Compute control input: u = W * e
    controlador.compute_u = @(e) controlador.W * e;

    %% Define weight update function based on variant
    switch variant
        case 'normal'
            % Standard MIT Rule update: ΔW = u·e^T
            controlador.update_W = @(W, u, e, eta) ...
                W + u * (eta(:) .* e(:))';

        case 'normalized1'
            % MIT Rule normalized by |e^T·e|
            controlador.update_W = @(W, u, e, eta) ...
                W + (u * (eta(:) .* e(:))') / (1e-6 + abs(e' * e));

        case 'normalized2'
            % MIT Rule normalized by (1 + ‖e‖^2)
            controlador.update_W = @(W, u, e, eta) ...
                W + (u * (eta(:) .* e(:))') / (1 + norm(e)^2);

        case 'constant'
            % MIT Rule with fixed divisor to limit update size
            controlador.update_W = @(W, u, e, eta) ...
                W + (u * (eta(:) .* e(:))') / 0.1;

        otherwise
            error('Unknown variant. Use: normal | normalized1 | normalized2 | constant.');
    end
end
