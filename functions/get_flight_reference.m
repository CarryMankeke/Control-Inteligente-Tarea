% get_flight_reference.m
%
% Purpose:
%   Extract a real flight trajectory (position + orientation) from the
%   AscTec Pelican dataset and normalize it for use as y_ref.
%
% Usage:
%   y_ref = get_flight_reference
%   Note: A 5-sample moving average is applied to reduce sensor noise and outliers.(rawInputPath, flightIdx);
%
% Inputs:
%   rawInputPath — full path to 'AscTec_Pelican_Flight_Dataset.mat'
%   flightIdx    — index of the flight to use (1…54)
%
% Output:
%   y_ref        — 6×N normalized trajectory [pos; euler]
%
function y_ref = get_flight_reference(rawInputPath, flightIdx)
    %% Validate file exists
    if ~isfile(rawInputPath)
        error('Dataset file not found: %s', rawInputPath);
    end

    %% Load dataset
    raw = load(rawInputPath);
    if ~isfield(raw, 'flights')
        error('Invalid dataset: missing ''flights'' field.');
    end
    nFlights = numel(raw.flights);
    if flightIdx < 1 || flightIdx > nFlights
        error('flightIdx must be between 1 and %d', nFlights);
    end

    %% Extract raw trajectory
    fl    = raw.flights{flightIdx};
    Pos   = fl.Pos';    % 3×len
    Euler = fl.Euler';  % 3×len

    %% Smooth signals (5-sample moving average)
    windowSize = 5;
    Pos   = movmean(Pos,   windowSize, 2);
    Euler = movmean(Euler, windowSize, 2);

    %% Normalize to [-1,1] and wrap angles
    Pos   = mapminmax(Pos,   -1, 1);
    Euler = wrapToPi(Euler) / pi;

    %% Compose output
    y_ref = [Pos; Euler];
end