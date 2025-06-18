% BLOCK 0: Generate quadrotorData from WaveLab AscTec Pelican raw dataset
%
% Description:
%   Loads the AscTec Pelican flight dataset, extracts motor commands (U),
%   position (Pos), and Euler angles, aligns and concatenates them into a
%   single .mat file 'quadrotorData.mat' containing variables U and Y.
%
% Dataset source:
%   WaveLab AscTec Pelican Flight Dataset
%   http://wavelab.uwaterloo.ca/index3390.html?page_id=705
%
% Arguments:
%   None
%
% Returns:
%   Saves 'quadrotorData.mat' with:
%     U (4×N double): Motor command matrix [commands × time].
%     Y (6×N double): Concatenated [pos; euler] matrix.
% -----------------------------------------------------------------------------
function crear_quadrotorData()
    %% Load raw dataset
    raw = load('AscTec_Pelican_Flight_Dataset.mat');
    if ~isfield(raw, 'flights')
        error('Raw file must contain ''flights'' field.');
    end
    flight = raw.flights{1,1};

    %% Verify required fields
    if ~isfield(flight, 'Motors_CMD') || ~isfield(flight, 'Pos') || ~isfield(flight, 'Euler')
        error('Flight data missing required fields: Motors_CMD, Pos, Euler.');
    end

    %% Extract and validate numeric data
    U_raw   = flight.Motors_CMD;    % [N × 4]
    Pos     = flight.Pos;           % [M × 3]
    Euler   = flight.Euler;         % [M × 3]
    if ~isnumeric(U_raw) || ~isnumeric(Pos) || ~isnumeric(Euler)
        error('Data fields must be numeric arrays.');
    end

    %% Align lengths of Pos and Euler
    M = min(size(Pos,1), size(Euler,1));
    Pos   = Pos(1:M, :);
    Euler = Euler(1:M, :);

    %% Align with motor commands
    N = min(size(U_raw,1), M);
    U = U_raw(1:N, :)';               % [4 × N]
    Y = [Pos(1:N, :)'; Euler(1:N, :)']; % [6 × N]

    %% Save the synchronized dataset
    outFile = fullfile('data','processed','quadrotorData.mat');
    save(outFile, 'U', 'Y');
    fprintf('✔ Saved ''quadrotorData.mat'' with U(4×%d) and Y(6×%d)\n', N, N);
end
