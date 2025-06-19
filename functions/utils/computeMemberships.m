function Unew = computeMemberships(centers, X, m)
% Recalcula miembros TS-Sugeno con fórmula clásica
    D = pdist2(X', centers);
    tmp = (D.^(-2/(m-1)));
    Unew = tmp ./ sum(tmp,2);
    Unew = Unew';  % tamaño C×N
end