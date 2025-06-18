% BLOCK 3: Generate reference trajectory within safe flight envelope
%
% Description:
%   Creates a smooth sine-based reference trajectory for position (X,Y,Z)
%   and gentle orientation (roll, pitch, yaw) within predefined safe ranges.
%
% Arguments:
%   durationSec (double): Total trajectory duration in seconds.
%   sampleFreq  (double): Sampling frequency in Hz.
%
% Returns:
%   y_ref (6×T double): Reference trajectory [x; y; z; roll; pitch; yaw].
%   T     (integer)   : Number of time steps.
%   Ts    (double)    : Sampling period in seconds.
% -----------------------------------------------------------------------------

function [y_ref, T, Ts] = bloque3_generar_referencia(durationSec, sampleFreq)
    %% Time vector
    Ts = 1 / sampleFreq;
    t  = 0:Ts:durationSec;
    T  = numel(t);

    %% Safe flight domain amplitudes
    x_amp   = 1.5;    % position X amplitude
    y_amp   = 1.5;    % position Y amplitude
    z_base  = 1.5;    % position Z base
    z_amp   = 0.3;    % position Z amplitude
    ori_amp = 0.1;    % orientation amplitude (radians)

    %% Generate sine-based trajectories
    f_base = 0.05;    % base frequency
    x   = x_amp   * sin(2*pi*f_base*t);
    y   = y_amp   * sin(2*pi*f_base*t + pi/2);
    z   = z_base + z_amp   * cos(2*pi*f_base*t);

    roll  = ori_amp * sin(2*pi*f_base*t);
    pitch = ori_amp * cos(2*pi*f_base*t);
    yaw   = ori_amp * sin(2*pi*f_base*t/2);

    %% Compose reference matrix
    y_ref = [x; y; z; roll; pitch; yaw];

    %% Final smoothing
    y_ref = movmean(y_ref, 5, 2);
end
