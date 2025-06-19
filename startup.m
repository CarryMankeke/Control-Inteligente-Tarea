% startup.m
%
% Purpose:
%   Initialize MATLAB paths for the PP2 project so that only the relevant
%   scripts and functions (incluyendo utils y plots) puedan ser llamados.
%
% Usage:
%   Placed in the project root (main/).  
%   MATLAB automatically runs this when you open the PP2 project.
%
% Author: Camilo Andrés Soto Villegas
% Date:   2025-06-18

% Determine project root (folder containing this file)
projectRoot = fileparts(mfilename('fullpath'));

% 1) Add project root (only that folder)
addpath(projectRoot);

% 2) Add all runners
addpath(fullfile(projectRoot, 'scripts'));

% 3) Add functions and subfolders (utils, plots, etc.)
addpath(genpath(fullfile(projectRoot, 'functions')));

fprintf('Startup complete: MATLAB paths set for PP2 project.\n');