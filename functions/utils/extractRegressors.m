function X = extractRegressors(u_cells, y_cells, delay)
% Concatena todos los vuelos, forma vectores [u(k-1)…u(k-d); y(k-1)…y(k-d)]
    U = horzcat(u_cells{:});
    Y = horzcat(y_cells{:});
    N = size(U,2) - delay;
    X = zeros((size(U,1)+size(Y,1))*delay, N);
    for k = 1:N
        u_block = U(:, k: k+delay-1);
        y_block = Y(:, k: k+delay-1);
        X(:,k)  = [u_block(:); y_block(:)];
    end
end




