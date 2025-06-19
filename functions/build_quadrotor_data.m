% build_quadrotor_data.m
%
% Purpose:
%   Build the synchronized quadrotor dataset by loading the raw AscTec Pelican
%   flight data, extracting motor commands (U), positions and Euler angles (Y),
%   aligning their lengths, and saving the result to processed data folder.
%
% Usage:
%   build_quadrotor_data(rawInputPath, outputPath);
%
% Inputs:
%   rawInputPath  — full path to 'AscTec_Pelican_Flight_Dataset.mat'
%   outputPath    — full path where 'quadrotorData.mat' will be saved
%
% Outputs:
%   Saves a MAT-file containing:
%     U (4×N double): Motor command matrix [commands × time]
%     Y (6×N double): Concatenated [position; euler] matrix
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

function build_quadrotor_data(rawInputPath, outputPath)
    %% Validate raw file
    if ~isfile(rawInputPath)
        error('Raw dataset not found: %s', rawInputPath);
    end

    %% Load raw dataset
    dataRaw = load(rawInputPath);
    if ~isfield(dataRaw, 'flights')
        error('Invalid dataset: missing ''flights'' field.');
    end
    flight = dataRaw.flights{1};

    %% Extract fields
    if ~isfield(flight, 'Motors_CMD') || ~isfield(flight, 'Pos') || ~isfield(flight, 'Euler')
        error('Flight data missing required fields: Motors_CMD, Pos, Euler.');
    end
    U_raw   = flight.Motors_CMD;  % [N × 4]
    Pos     = flight.Pos;         % [M × 3]
    Euler   = flight.Euler;       % [M × 3]

    %% Align and synchronize lengths
    M = min(size(Pos,1), size(Euler,1));
    Pos   = Pos(1:M, :);
    Euler = Euler(1:M, :);

    N = min(size(U_raw,1), M);
    U = U_raw(1:N, :)';               % [4 × N]
    Y = [Pos(1:N, :)'; Euler(1:N, :)']; % [6 × N]

    %% Ensure output directory exists
    outDir = fileparts(outputPath);
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    %% Save processed dataset
    save(outputPath, 'U', 'Y');
    fprintf('✔ Saved ''%s'' with U(4×%d) and Y(6×%d)\n', outputPath, N, N);
end
