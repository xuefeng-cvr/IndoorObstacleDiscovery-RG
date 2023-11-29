function [vars] = testing_preparing(vars)

    mkDirs(vars.abspath_test);
    
    vars.relpath_test_result    = 'result/';
    mkDirs(fullfile(vars.abspath_test,vars.relpath_test_result));
    
    vars.relpath_test_edge   = 'ucms/';
    mkDirs(fullfile(vars.abspath_test,vars.relpath_test_edge));
    
    vars.relpath_test_probmaps  = 'probmaps/';
    mkDirs(fullfile(vars.abspath_test,vars.relpath_test_probmaps));
    
    vars.relpath_test_featvec   = 'featvecs/';
    mkDirs(fullfile(vars.abspath_test,vars.relpath_test_featvec));

    vars.relpath_test_tops      = 'topboxes/';
    mkDirs(fullfile(vars.abspath_test,vars.relpath_test_tops));
    
end

