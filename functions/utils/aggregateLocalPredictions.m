function y_pred = aggregateLocalPredictions(nets, U, xk, delay)
% nets: cell array de entrenados net_j
% U(:,k): vector de membresías en el paso k
    C = numel(nets);
    y_pred = 0;
    for j = 1:C
        net = nets{j};
        % preparar regresor en serie–paralelo
        x_seq = con2seq(xk(:,end-delay+1:end));
        yj_seq = net(x_seq);
        yj = cell2mat(yj_seq(end));
        y_pred = y_pred + U(j,end) * yj;
    end
end