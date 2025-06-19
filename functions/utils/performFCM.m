function [centers, U] = performFCM(X, C, m)
% Wrapper a la toolbox de Fuzzy Logic
    [centers, U] = fcm(X', C, [m,100,1e-6,0]);
    % fcm devuelve centros en filas de X', y U como membership C×N
end