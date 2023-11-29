clc; clear; close all; warning('off');
addpath(genpath(pwd));

filename = mfilename;
disp(filename(7:end));

[vars] = paramloader_ORG();
vars.abspath_ORG    = '<Please enter the path to the ORG dataset>';
vars.abspath_train  = '<Please enter the path to the training folder (used to save by-products file)>';
vars.model_path     = '/model/OD_rfmodel_AGFM.mat';
vars.subdir         = 'train';
vars.num_trainingsamples    = 20;
vars.num_tpsamples          = 5;
vars.ratio_highscorebox     = 0.2;
vars.thresh_highscorebox    = 0.2;
vars.resolution             = [1920,1080];
vars = training_preparing(vars);
[vars,datalist] = dataloader_ORG(vars);

%% Preprocessing: Edge Detection & Proposal Extraction
for i=1:length(datalist.imgs_list) % Processing all scenes
    for j=1:length(datalist.imgs_list{i}) % Processing all image sequences
        frames_list     = dir(fullfile([datalist.imgs_list{i}(j).folder,'/',datalist.imgs_list{i}(j).name,'/*.png']));
        [odom_ct,odom]  = readparam(fullfile([datalist.odom_list{i}(j).folder,'/',datalist.odom_list{i}(j).name]),['%s ', repmat('%f ',1,14)]);
        [ts_ct,ts]      = readparam(fullfile([datalist.timestamp_list{i}(j).folder,'/',datalist.timestamp_list{i}(j).name]),'%s %f %f ');

        for k = 2:size(frames_list,1) % Processing all images
            t = tic;
            frame_a = k-1;  % Previous frame
            frame_b = k;    % Current frame
            dist = 0;
            while dist < vars.trav_distance_thresh && frame_a > 0
                robot_pos_ab    = odom([frame_a,frame_b], 2:4) * 1000;
                dist            = robot_pos_ab(2,:) - robot_pos_ab(1,:);
                dist            = sqrt(dist(1)^2 + dist(2)^2);
                if dist < vars.trav_distance_thresh
                    frame_a = frame_a - 1;
                end
            end
            if dist < vars.trav_distance_thresh, continue; end

            robot_que_ab = odom([frame_a,frame_b], 5:8);

            pref = sprintf('%02d_%03d_%07d',i,j,k);
            preprocess_name = fullfile(vars.abspath_train,vars.relpath_out_preprocess,[pref,'_preprocess.mat']);

            if ~exist(preprocess_name,'file')
                % Read an image and ground truth
                img_a = imread(fullfile(frames_list(frame_a).folder,frames_list(frame_a).name));
                img_b = imread(fullfile(frames_list(frame_b).folder,frames_list(frame_b).name));

                % Calulate the Edge map
                if ~exist(fullfile(vars.abspath_train,vars.relpath_train_edge,[pref,'_ucm.mat']),'file')
                    [ucm] = SEDDetector(img_b, vars.mod_sed);
                    parsave(fullfile(vars.abspath_train,vars.relpath_train_edge,[pref,'_ucm.mat']),ucm,'ucm');
                else
                    ucm = load(fullfile(vars.abspath_train,vars.relpath_train_edge,[pref,'_ucm.mat']));
                    ucm = ucm.ucm;
                end

                % Optical-flow that converts points from img_a to img_b
                [edge_info,p_of,p_homo] = compute_of_homo(robot_pos_ab,robot_que_ab,img_b,img_a,ucm,vars.camera_ground);

                % Proposal Extraction through Edgeboxes
                [bbox_olp, ~] = get_proposal(single(ucm));
                bbox = bbox_olp;

                parsave(preprocess_name,bbox,'bbox',edge_info,'edge_info',p_of,'p_of',p_homo,'p_homo',dist,'dist');
            end
            disp(['Preprocess_',pref,' ---> ',num2str(toc(t)),' s']);
        end
    end
end

%% Feature extraction
prelist = dir(fullfile(vars.abspath_train,vars.relpath_out_preprocess,'*.mat'));

for i=1:size(prelist,1)

    tpfe = tic;
    pref = prelist(i).name(1:14);
    disp(pref);
    trainFile = fullfile(vars.abspath_train,vars.relpath_out_trData,[pref,'training_sample.mat']);

    if 1%~exist(trainFile,'file')
        %% Load data
        disp([num2str(i),' ',pref]);

        sID = str2double(pref(1:2));
        vID = str2double(pref(4:6));
        fID = str2double(pref(8:end));

        frames_list  = dir(fullfile(datalist.imgs_list{sID}(vID).folder, datalist.imgs_list{sID}(vID).name, '*.png'));
        I            = imread(fullfile(frames_list(fID).folder, frames_list(fID).name));
        gt           = imread(fullfile(datalist.gtlabel_list{sID}(vID).folder, [frames_list(fID).name(1:end-10),vars.suffix_gtLabel]));
        pdata        = load(fullfile(vars.abspath_train,vars.relpath_out_preprocess,prelist(i).name));
        ucm          = load(fullfile(vars.abspath_train,vars.relpath_train_edge,[pref,'_ucm.mat'])); ucm = ucm.ucm;
        bbox         = pdata.bbox;

        %% Training Sample selection
        [iou_fusion,overlap_freespace] = compute_iou(bbox,gt);
        idx_freespacebox = overlap_freespace > 0.4;
        bbox_fs = bbox(idx_freespacebox,:);
        iou_fs  = iou_fusion(:,idx_freespacebox);

        [iou_desc,index_iou] = sort(iou_fs,2,'descend');
        loverlap_idx = [];
        inst_id =unique(gt(gt>1));
        if isempty(inst_id) % If no obstacles appear in this image
            continue;
        end
        % Select true positive samples
        iou_Tsamples = [];
        bbox_Tsamples = [];
        O=single(calO(ucm));
        for j = 1:size(inst_id,1)
            %% Construct a ground truth bounding box for training
            [gt_b] = create_gtbox(gt, inst_id(j));
            b = scoreboxesMex_refine(ucm,O,0.65,0.75,0,1e3,0.1,0.5,0.5,6,1000,2,1.7,single(gt_b));
            if isnan(b(5)), b(5) = 0; end
            gt_b = [gt_b, b(5)];
            [iou_gt,~] = compute_iou(gt_b,gt);

            %% Select positive samples for each instance (highest overlap with ground truth)
            if size(iou_desc,2) < vars.num_tpsamples
                iou_Tsamples = [iou_Tsamples;...
                    iou_desc(j, 1:size(iou_desc,2))'; max(iou_gt)];
                bbox_Tsamples = [bbox_Tsamples;...
                    bbox_fs(index_iou(j, 1:size(iou_desc,2)),:); gt_b];
                loverlap_idx = [loverlap_idx,...
                    index_iou(j, 1:size(iou_desc,2))];
            else
                iou_Tsamples = [iou_Tsamples;...
                    iou_desc(j,1:vars.num_tpsamples)'; max(iou_gt)];
                bbox_Tsamples =[ bbox_Tsamples;...
                    bbox_fs(index_iou(j, 1:vars.num_tpsamples),:); gt_b];
                loverlap_idx = [loverlap_idx,...
                    index_iou(j, 1:vars.num_tpsamples)];
            end
        end
        bbox_fs(loverlap_idx,:) = [];
        iou_fs(loverlap_idx) = [];

        %% Randomly Select Negative Samples
        idx_fs_highscore = find(bbox_fs(:,end) > vars.thresh_highscorebox);
        idx_notobs = find(iou_fs(:) < 0.01);

        if ~isempty(idx_fs_highscore)
            idx_highSamp = intersect(idx_fs_highscore, idx_notobs, 'rows');
            if size(idx_highSamp,1) > vars.num_trainingsamples * vars.ratio_highscorebox
                idx_train_highSamp = idx_highSamp(randperm(length(idx_highSamp), vars.num_trainingsamples * vars.ratio_highscorebox));
            else
                idx_train_highSamp = idx_highSamp;
            end
        else
            idx_highSamp = [];
            idx_train_highSamp = [];
        end

        idx_lowSamp = setdiff((1:size(bbox_fs,1))', idx_highSamp);
        if length(idx_lowSamp) > vars.num_trainingsamples * (1 - vars.ratio_highscorebox)
            idx_train_lowSamp = idx_lowSamp(randperm(length(idx_lowSamp), vars.num_trainingsamples * (1 - vars.ratio_highscorebox)));
        else
            idx_train_lowSamp = idx_lowSamp;
        end
        iou_samples_mod = [...
            max(iou_fs(:,idx_train_highSamp),[],1)';...
            max(iou_fs(:,idx_train_lowSamp) ,[],1)'];
        bbox_samples_mod =[...
            bbox_fs(idx_train_highSamp,:);...
            bbox_fs(idx_train_lowSamp ,:)];

        iou_samples_mod  = [iou_samples_mod ;iou_Tsamples ];
        bbox_samples_mod = [bbox_samples_mod;bbox_Tsamples];

        if size(iou_samples_mod,1) ~= size(bbox_samples_mod,1)
            error('size error !!!')
        end

        %% Feature extraction
        tfeature = tic;
        [integral_cut] = compute_feathsv_intgeral_c(I);
        disp(['integral',num2str(i),' ---> ',num2str(toc(tfeature)),'s']);

        b=bbox_samples_mod;
        b(:,3:4) = b(:,3:4) + b(:,1:2) -1 ;
        assert(sum(b(:,3) > vars.resolution(1)|b(:,4) > vars.resolution(2)) == 0);
        idx = b(:,3) > vars.resolution(1)|b(:,4) > vars.resolution(2);
        bbox_samples_mod(idx,:) = [];
        iou_samples_mod(idx,:)  = [];
        assert(size(bbox_samples_mod,1) == size(iou_samples_mod,1));

        featvec_samples_mod = compute_feature_23_geo_fast_c(bbox_samples_mod,I,ucm,vars.resolution,integral_cut,pdata.edge_info,pdata.dist);
        featvec_samples_mod(featvec_samples_mod == inf|featvec_samples_mod == -inf) = 10;
        disp(['features',num2str(i),' ---> ',num2str(toc(tfeature)),'s']);
        parsave(trainFile,featvec_samples_mod,'feat',bbox_samples_mod,'bbox',iou_samples_mod,'iou_fusion');

    end
    disp(['Get No.',num2str(i),' training data ---> ',num2str(toc(tpfe)),'s']);
end


%% Training Random Forest for Obstacle Discovery
trainingSampleList = dir(fullfile(vars.abspath_train, vars.relpath_out_trData,'*training_sample.mat'));
features = [];
ious_temp = [];
preflist = [];
boxesSample = [];

for i=1:size(trainingSampleList,1)
    data        = load(fullfile(vars.abspath_train,vars.relpath_out_trData,trainingSampleList(i).name));
    assert(size(data.feat,1) == size(data.iou_fusion,1));
    pref        = trainingSampleList(i).name(1:14);
    features    = [features;data.feat];
    ious_temp   = [ious_temp;data.iou_fusion];
    preflist    = [preflist;repmat(pref,[size(data.feat,1),1])];
    boxesSample = [boxesSample;data.bbox];
    disp(['read data ',num2str(i),]);
end

[ious_desc,idx_ious] = sort(ious_temp,'descend');

% Remove unidentified samples
idx_temp = find(ious_temp > 0.2);
feat_temp = features(idx_temp,:);
count = uint8(feat_temp(:,1) < 0.15)  + ...
        uint8(feat_temp(:,10) < 0.01) + ...
        uint8(feat_temp(:,18) < 0.1)  + ...
        uint8(feat_temp(:,19) < 0.1)  + ...
        uint8(feat_temp(:,20) < 0.1);
idx_bad = idx_temp(count > 3);
features(idx_bad,:) = [];
ious_temp(idx_bad) = [];
idx = ious_temp > 0 & ious_temp< 0.01;
ious_temp(idx) = 0;

ids_mod2 = find(features(:,end) < 0.1 | isnan(features(:,end-2)) | isnan(features(:,end-1)));
ids_mod1 = setdiff((1:size(features,1))',ids_mod2);
features(isnan(features)) = 0;


rf_sr  = regRF_train(features(:,[1,3:4,6,8:20]),ious_temp,50);
rf_str = regRF_train(features(ids_mod1,[1,3:4,6,8:20,22,23]),ious_temp(ids_mod1),50);

parsave([pwd,vars.model_path],...
    rf_sr,'rf_sr',...
    rf_str,'rf_str');

disp('Training done');
