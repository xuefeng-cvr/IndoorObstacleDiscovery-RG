function [vars] = training_preparing(vars)
    
%% training path setup
mkDirs(vars.abspath_train);

vars.relpath_out_preprocess    = 'preproc/';
mkDirs(fullfile(vars.abspath_train,vars.relpath_out_preprocess));

vars.relpath_out_trData = 'trainsample/';
mkDirs(fullfile(vars.abspath_train,vars.relpath_out_trData));

vars.relpath_train_edge = 'ucms/';
mkDirs(fullfile(vars.abspath_train,vars.relpath_train_edge));

end

