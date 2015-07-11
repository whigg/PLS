function RESULTS = pls(X, Y, prepro, NumFact, NumIter, Tol)

set(0,'DefaultFigureWindowStyle','docked');

ExistTable_A = istable(X);
ExistTable_B = istable(Y);

if ExistTable_A == 1 && ExistTable_B ==1
    X_TABLE = X;
    Y_TABLE = Y;
    X = table2array(X);
    Y = table2array(Y);
end

[X_rows, X_cols] = size(X);
[Y_rows, Y_cols] = size(Y);

if X_rows ~= Y_rows
    disp('ERROR! Matrix dimensions must agree')
    return
end

run('pls_conditions.m');
run('pls_prepro.m');

RESULTS = pls_regress(X, Y, X_rows, X_cols, ...
        Y_rows, Y_cols, NumFact, NumIter, Tol, prepro)
    
run('pls_figures')
    
    

