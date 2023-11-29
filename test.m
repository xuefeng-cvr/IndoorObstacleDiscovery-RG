clc; clear; close all; warning('off');
addpath(genpath(pwd));

filename = mfilename;
disp(filename(7:end));

[vars]                  = paramloader_ORG();
vars.abspath_ORG        = '<Please enter the path to the ORG dataset>';
vars.abspath_test       = '<Please enter the path to the test folder (used to save results)>';
vars.model_path         = './model/OD_rfmodel_AGFM.mat';
vars.subdir             = 'test';
vars.savefv             = true;
vars.low_score_thresh   = 0.25;
vars.resolution         = [1920,1080];
[~,name,~]              = fileparts(vars.model_path);
vars.roc_mat            = ['./result/ROC_indoor/ROC_',name,'.mat'];
vars                    = testing_preparing(vars);
[vars,datalist]         = dataloader_ORG(vars);

%% model
load(vars.model_path);
vars.rf_str = rf_str;
vars.rf_sr  = rf_sr;

for i=1:length(datalist.imgs_list)
    for j=1:length(datalist.imgs_list{i})
        frames_list     = dir(fullfile(datalist.imgs_list{i}(j).folder, datalist.imgs_list{i}(j).name,'*.png'));
        [odom_ct,odom]  = readparam(fullfile(datalist.odom_list{i}(j).folder, datalist.odom_list{i}(j).name),['%s ', repmat('%f ',1,14)]);
        [ts_ct,ts]      = readparam(fullfile(datalist.timestamp_list{i}(j).folder, datalist.timestamp_list{i}(j).name),'%s %f %f ');
        for k = 1:size(frames_list,1)
            t = tic;
            t_all = tic;
            fileprefix  = sprintf('%02d_%03d_%07d', i, j, k);
            top_file    = fullfile(vars.abspath_test, vars.relpath_test_tops, [fileprefix,'_tops.mat']);
            feat_file   = fullfile(vars.abspath_test, vars.relpath_test_featvec, [fileprefix,'_featvecs.mat']);
            prob_file   = fullfile(vars.abspath_test, vars.relpath_test_probmaps, [fileprefix,'_probmap.mat']);
            vis_file    = fullfile(vars.abspath_test, vars.relpath_test_result,[fileprefix,'_result.png']);
            
            if ~exist(prob_file,'file')
                if vars.savefv == 1 && exist(feat_file,'file')
                    fv = load(feat_file);
                    bbox_edgebox    = fv.bbox_all;
                    feat        = fv.feat_all;
                    move        = fv.move;
                    fv          = [];
                    img_b = imread(fullfile(frames_list(k).folder, frames_list(k).name));
                else
                    %% Search an appropriate previous image for current image
                    if k == 1           % Current image is the first frame of a video
                        move    = 0;
                        frame_b = k;
                    else
                        frame_a = k-1;
                        frame_b = k;
                        dist    = 0;
                        % Find a previous image
                        while dist < vars.trav_distance_thresh && frame_a > 0
                            robot_pos_ab = odom([frame_a,frame_b], 2:4) * 1000;
                            dist = robot_pos_ab(2,:) - robot_pos_ab(1,:);
                            dist = sqrt(dist(1)^2 + dist(2)^2);
                            if dist < vars.trav_distance_thresh
                                frame_a = frame_a - 1;
                            else
                                robot_que_ab = odom([frame_a,frame_b],5:8);
                                move = 1;
                                break
                            end
                        end
                        % Robot does not move
                        if dist < vars.trav_distance_thresh
                            move = 0;
                        end
                    end
                    
                    if move == 1
                        img_a = imread(fullfile(frames_list(frame_a).folder, frames_list(frame_a).name));
                    end
                    img_b = imread(fullfile(frames_list(frame_b).folder, frames_list(frame_b).name));
                    %% Edge Detection
                    t_edge = tic;
                    if ~exist(fullfile(vars.abspath_test,vars.relpath_test_edge,[fileprefix,'_ucms.mat']),'file')
                        [ucms] = SEDDetector(img_b, vars.mod_sed);
                        parsave(fullfile(vars.abspath_test,vars.relpath_test_edge,[fileprefix,'_ucms.mat']),ucms,'ucms');
                    else
                        ucms = load(fullfile(vars.abspath_test,vars.relpath_test_edge,[fileprefix,'_ucms.mat']));
                        ucms = ucms.ucms;
                    end
                    time_edge = toc(t_edge);
                 
                    %% Proposal Extraction
                    t_eb = tic;
                    [bbox_edgebox,O] = get_proposal(ucms);
                    time_eb = toc(t_eb);

                    %% Feature
                    t_f = tic;
                    [integral_hsv] = compute_feathsv_intgeral_c(img_b);
                    if move == 1
                        [edge_info,~,~] = compute_of_homo(robot_pos_ab,robot_que_ab,img_b,img_a,ucms,vars.camera_ground);
                        feat            = compute_feature_23_geo_fast_c(bbox_edgebox,img_b,ucms,vars.resolution,integral_hsv,edge_info,dist);
                    else
                        feat            = compute_feature_20_v2_fast_c(bbox_edgebox,img_b,ucms,vars.resolution,integral_hsv);
                    end 
                    
                    time_f = toc(t_f);
                    disp(['picture ',sprintf('%04d_%04d: %02d --> ',i,j,k), 'olp ',...
                        num2str(time_eb),   ' s ; edge ',...
                        num2str(time_edge), ' s ; feature ',...
                        num2str(time_f),    ' s ; AllBox ',...
                        num2str(size(bbox_edgebox,1))]);
                    
                    if vars.savefv == true
                        parsave(feat_file,...
                            bbox_edgebox,'bbox_all',...
                            feat,'feat_all',...
                            move,'move');
                    end
                end
                %% Prediction
                t_pre = tic;
                class_scores = [];
                if move == 1
                    ids_mod2    = find(feat(:,25) < 0.1 | isnan(feat(:,22)) | isnan(feat(:,23))); % Boxes with low confidence.
                    ids_mod1    = setdiff((1:size(feat,1))',ids_mod2); % Boxes with high confidence.
                    feat_mod_str= feat(ids_mod1,:);
                    feat_mod_sr = feat(ids_mod2,:);
                    class_scores(ids_mod1)  = regRF_predict(feat_mod_str(:,[1,3:4,6,8:20,22,23]),vars.rf_str);
                    class_scores(ids_mod2)  = regRF_predict(feat_mod_sr(:,[1,3:4,6,8:20]),vars.rf_sr);
                else
                    class_scores            = regRF_predict(feat(:,[1,3:4,6,8:20]),vars.rf_sr);
                end
                
                [scores, ids] = sort(class_scores,'descend');
                time_pre = toc(t_pre);
                
                %% Generate probability map
                if isrow(scores), scores = scores'; end
                bbox_desc   = bbox_edgebox(ids,:);
                bbox_desc   = [bbox_desc,scores];
                bbtop       = bbox_desc(scores > vars.low_score_thresh,:);
                feat_desc   = feat(ids,:);
                feattop     = feat_desc(scores > vars.low_score_thresh,:);
                parsave(top_file,bbtop,'bbtop');
                top_nms = bbsnms(bbtop(:,[1 2 3 4 6]), 0.7, 1000);

                [prob_map]  = get_probmap(top_nms,vars.resolution);
                parsave(prob_file, prob_map,'prob_map');

                %% Draw bounding boxes on the image
                prob_map = load(prob_file);
                prob_map = prob_map.prob_map;
                img = imread(fullfile(frames_list(k).folder, frames_list(k).name));
                seg_pred = prob_map > 0.515;
                img_obs = vis_obs(img,uint8(seg_pred));
                imwrite(img_obs, vis_file);
            end
            
            close all;
            time_all = toc(t_all);
            disp([fileprefix,' : ', num2str(time_all),' s']);
        end
    end
end


evaluation_ROC(...
    fullfile(vars.abspath_test, vars.relpath_test_tops),...
    fullfile(vars.abspath_test, vars.relpath_test_probmaps),...
    vars.roc_mat,...
    datalist,...
    vars);

