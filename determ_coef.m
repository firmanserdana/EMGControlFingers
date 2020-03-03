function [R_square1, R_square2, R_square3, R_square4, Diff, R_square5, R_square6, R_min6, R_max6] = determ_coef(Xv, Xr)
% Calculates the coefficient of determination between two signals. Each
% signal is a matrix of any size, but the two signals must have equal
% number of elements.

% 1 crosscoeff^2 of concatenated
% 2 r2 of concatenated
% 3 
% 4
% Diff
% 5 multivariate r2

if (size(Xv)~=size(Xr))
    error('Input signals must have the same size')
end

 Xv=sort(Xv);
 Xr=sort(Xr);

if (size(Xv,2)==1)
    c = corrcoef(Xv, Xr);
    R_square1 = c(1,2)^2;
    
    mv = mean(Xv);
    mr = mean(Xr);
    sse = (Xv-Xr).^2;
    sst = (Xv-mv).^2;
    ssr = (Xr-mr).^2;
    den = ssr+sse;
    R_square2 = 1 - sum(sse) / sum(sst);    
    R_square3 = sum(ssr) / sum(sst);
    R_square4 = sum(ssr) / sum(den);
    Diff = mean(abs(den-sst)) / mean([mean(den) mean(sst)]);

else

    n = numel(Xv);
    
    %%%%%%%%%
    X1 = reshape(Xv,1,n);
    X2 = reshape(Xr,1,n);
    c = corrcoef(X1, X2);
    R_square1 = c(1,2)^2;

    %%%%%%%%%
    m = mean(X1);
    sst = (X1-m).^2;  %% n - > a
    sse = (X1-X2).^2;
    
    R_square2 = 1 - sum(sse) / sum(sst);
    
    %%%%%%%%%
    mv = mean(Xv,2)*ones(1,size(Xv,2));
    mr = mean(Xr,2)*ones(1,size(Xr,2));
    sse = (Xv-Xr).^2;
    sst = (Xv-mv).^2;
    ssr = (Xr-mr).^2;
    den = ssr + sse;
    R_square3 = sum(sum(ssr)) / sum(sum(sst));
    R_square4 = sum(sum(ssr)) / sum(sum(den));
    Diff = mean(mean(abs(den-sst))) / mean([mean(mean(den)) mean(mean(sst))]);
    R_square5 = 1 - sum(sum(sse)) / sum(sum(sst));
    
    %%%%%%%%%
    temp_mean = [];
    for row_nb = 1:size(Xv,1)
        c = corrcoef(Xv(row_nb,:), Xr(row_nb,:));
        temp_mean = [temp_mean c(1,2)^2];
    end
    
    R_square6 = mean(temp_mean);
    R_min6 = min(temp_mean);
    R_max6 = max(temp_mean);
    
    %%%%%%%%%
    matrix = zeros(size(Xv,1));
    for i = 1:size(Xv,1)
        for j = 1:size(Xv,1)
            c = corrcoef(Xv(i,:), Xr(j,:));
            matrix(i,j) = c(1,2)^2;
        end
    end
   
    %[R7, R7m, R7d, R7o] = is_diagonal(matrix);  
    
        
end