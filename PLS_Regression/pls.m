
function RESULTS_PLS = pls(X, Y, prepro, NumFact, NumIter, Tol)

% 
% 
% Usage: RESULTS = pls(X, Y, prepro, NumFact, NumIter, Tol)
% 
% X = data matrix
% Y = output data matrix
% prepro = type of matrix preprocessing (0,1 and 2 are: no prepro,
%                 column-centering and autoscaling, respectively)
% NumFact = number of factors to extract. Give the min(X_rows, X_cols)
% NumIter = maximum number of iterations for the PLS convergence
% Tol = tolerance (given as 1e-n) for PLS convergence
% 
% This function performs pls regression of X data on Y.
% The algorithm performs CrossValidation using 10% of all X rows.
% The cross-validation is repeated until all the X rows have been 
% used at least once.
% For each cross-validation iteration the value of RMSEP for each 
% PLS component is computed. The final RMSEP value is computed from the 
% average over all cross-validation iterations.
% 
% The optimal number of PLS components is determined from the minimum
% value of RMSEP.
% 
% The optimal number of PLS components is then used to build the final PLS
% model.

run('pls_conditions.m');

if size(X,1) ~= size(Y,1)
    disp('ERROR! Matrix dimensions must agree')
    return
end

ExistTable_A = istable(X);
ExistTable_B = istable(Y);

if ExistTable_A == 1 && ExistTable_B ==1
    
    Table_permuted_Index = randperm(size(X,1))';
    
        X_TABLE = X(Table_permuted_Index,:);
        Y_TABLE = Y(Table_permuted_Index,:);
else
    disp('ERROR! The data are not in TABLE form');
    RESULTS = [];
    return
end
    % PREPROCESSING WHOLE TABLES
        
    [X, Y] = pls_prepro(X, Y, prepro, X_TABLE, Y_TABLE);                    
    
    X_TABLE_Train_old = X;
    Y_TABLE_Train_old = Y;
    X_TABLE_CrossVal_old = X;
    Y_TABLE_CrossVal_old = Y;
    X = table2array(X);
    Y = table2array(Y);


    RowIndex = [1:1:size(X,1)]';       
    CV_ERROR_tot = zeros(NumFact, 2);
    
    %% 
    %   DATA SPLIT FOR Cross-Validation (15% each run)
   
    finish = false;
    iteration = 1;

while (~finish);  
    
    CrossValNum = round(0.10*size(X,1));
    CrossValIndex = randperm(size(X,1),CrossValNum)';
    RowIndex(CrossValIndex,1) = 0;
    
    X_TABLE_Train = X_TABLE_Train_old;
    Y_TABLE_Train = Y_TABLE_Train_old;
    
    X_TABLE_CrossVal = X_TABLE_CrossVal_old;
    Y_TABLE_CrossVal = Y_TABLE_CrossVal_old;

    
    X_TABLE_CrossVal = X_TABLE_CrossVal(CrossValIndex,:);                                  
    Y_TABLE_CrossVal = Y_TABLE_CrossVal_old(CrossValIndex,:);                                
    
    X_TABLE_Train(CrossValIndex,:) = [];                                    
    Y_TABLE_Train(CrossValIndex,:) = [];                                    

    X_Train = table2array(X_TABLE_Train);                                   
    Y_Train = table2array(Y_TABLE_Train); 

    X_CrossVal = table2array(X_TABLE_CrossVal);
    Y_CrossVal = table2array(Y_TABLE_CrossVal);

    EndCrossVal = any(RowIndex);

%%
%   SIZE OF DATA MATRICES

[X_rows, X_cols] = size(X);
[Y_rows, Y_cols] = size(Y);
[X_Train_rows, X_Train_cols] = size(X_Train);
[Y_Train_rows, Y_Train_cols] = size(Y_Train);
[X_CrossVal_rows, X_CrossVal_cols] = size(X_CrossVal);
[Y_CrossVal_rows, Y_CrossVal_cols] = size(Y_CrossVal);

%%
%   EXECUTION for the determination of PLS components

 CV_ERROR = zeros(NumFact, 2);

 for PLS_Comp = 1:NumFact 
 RESULTS_PLS.PLS_CrossVal = pls_regress(X, Y, ...
                       X_Train, Y_Train,...
                       PLS_Comp, NumIter, Tol, prepro, NumFact);
    
    Y_CrossVal_Hat = X_CrossVal*RESULTS_PLS.PLS_CrossVal.PLS_RegressCoeff;
    ressq = (Y_CrossVal-Y_CrossVal_Hat).^2;
    RMSPE_cv = sqrt(sum(ressq(:))/Y_CrossVal_rows);
    CV_ERROR(PLS_Comp,:) = [PLS_Comp, RMSPE_cv];
    PLS_Comp = PLS_Comp+1;
 end     
 
 CV_ERROR_tot =  (CV_ERROR_tot + CV_ERROR);
 
 
    if EndCrossVal == 0
        finish = true;
    end
    
iteration = iteration+1;
end % while cycle for CrossVal
 
iteration = iteration-1;

CV_ERROR_tot = CV_ERROR_tot./iteration;
RESULTS_PLS.PLS_CrossVal.CV_ERROR_tot = CV_ERROR_tot;
 figure
 plot(CV_ERROR_tot(:,1), CV_ERROR_tot(:,2), 'o-', ...
     'MarkerFaceColor', 'blue');
 title('Prediction Error - Average over all CrossVal iter.');
 xlabel('PLS component');
 ylabel('RMSEP');

[Min_RMSEP, PLS_NumComp] = min(CV_ERROR_tot(:,2));

%%
%       BUILDING FINAL PLS MODEL

X_Train = X;
Y_Train = Y;

RESULTS_PLS.PLS_Model = pls_regress(X, Y, ...
                       X_Train, Y_Train,...
                       PLS_NumComp, NumIter, Tol, prepro, NumFact);
    
RESULTS_PLS.PLS_Model.OUTCOME = table(iteration, Min_RMSEP, PLS_NumComp, ...
        'RowNames', {'PARAMETERS'}, ...
        'VariableNames', {'NumIter', 'Min_RMSEP', 'PLS_CompNum'});

 pls_figures(RESULTS_PLS.PLS_Model, PLS_NumComp,X_TABLE, Y_TABLE);
 
    



