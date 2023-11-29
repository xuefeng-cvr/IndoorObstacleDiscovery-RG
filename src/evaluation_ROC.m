function evaluation_ROC(topsdir,probsdir,savepath,datalist,vars)

top_list = dir([topsdir,'*tops.mat']);
img_count = size(top_list,1);

threshs = 0:0.005:1;
idx = 1:size(threshs,2);
thr2idx = containers.Map(threshs, idx);

%% Calculate TPR and FPR
TP = zeros(img_count,length(threshs));
FP = zeros(img_count,length(threshs));
GT_Obstacle = zeros(img_count,length(threshs));
GT_FreeSpace = zeros(img_count,length(threshs));
probmaplist = dir(fullfile(probsdir,'*_probmap.mat'));

for i = 1:length(probmaplist)
    tic;
    % load data
    name = probmaplist(i).name;
    sID = str2double(name(1:2));
    vID = str2double(name(4:6));
    fID = str2double(name(8:14));
    frames_list  = dir(fullfile(datalist.imgs_list{sID}(vID).folder,datalist.imgs_list{sID}(vID).name,'*.png'));
    gt = imread(fullfile(datalist.gtlabel_list{sID}(vID).folder,[frames_list(fID).name(1:end-10),vars.suffix_gtLabel]));

    gt_free     = gt == 1;
    gt_obs      = gt >  1;
    probmap = load([probsdir,name]);
    probmap = probmap.prob_map;
    
    % set thresholds to segment the obstacles
    for j = 1:length(threshs)
        idx = thr2idx(threshs(j));
        res_obs = probmap > threshs(j);
        TP(i,idx) = sum((res_obs(:) + gt_obs(:)) == 2);
        FP(i,idx) = sum((res_obs(:) + gt_free(:)) == 2);
        GT_Obstacle(i,idx) = sum(gt_obs(:) == 1);
        GT_FreeSpace(i,idx) = sum(gt_free(:) == 1);
    end
    t = toc;
    disp([num2str(i),':',num2str(t)]);
end
TPR = sum(TP,1) ./ sum(GT_Obstacle,1);
FPR = sum(FP,1) ./ sum(GT_FreeSpace,1);


%% Calculate ITPR and IFPR
TP_i = zeros(img_count,length(threshs));
FP_i = zeros(img_count,length(threshs));
obs_count = 0;
probmaplist = dir([probsdir,'*_probmap.mat']);
for i = 1:length(probmaplist)
    tic;
    % load data
    name = probmaplist(i).name;
    sID = str2double(name(1:2));
    vID = str2double(name(4:6));
    fID = str2double(name(8:14));
    frames_list = dir(fullfile(datalist.imgs_list{sID}(vID).folder,datalist.imgs_list{sID}(vID).name,'*.png'));
    gt = imread(fullfile(datalist.gtlabel_list{sID}(vID).folder,[frames_list(fID).name(1:end-10),vars.suffix_gtLabel]));

    gt_obs = gt > 1;
    probmap = load([probsdir,name]);
    probmap = probmap.prob_map;
    ground = bwlabel(gt_obs,8);
    obs_count = obs_count + max(max(ground));
    
    % set thresholds to segment the obstacles
    for j = 1:length(threshs)
        cdi = 0;
        idi = 0;
        idx = thr2idx(threshs(j));
        res_obs = probmap > threshs(j);
        res_obs(gt==0) = 0;
        predict = bwlabel(res_obs,8);
        inter = ground.*(predict~=0);
        for k = 1:max(max(ground))
            inter_rate = sum(sum(inter==k)) / sum(sum(ground==k));
            if inter_rate > 0.5
                cdi = cdi + 1;
            end
        end
        inter = predict.*(ground~=0);
        for k = 1:max(max(predict))
            inter_rate = sum(inter==k) / sum(sum(predict==k));
            if inter_rate < 0.5
                idi = idi + 1;
            end
        end
        TP_i(i,idx) = cdi;
        FP_i(i,idx) = idi;
    end
    t = toc;
    disp([num2str(i),':',num2str(t)]);
end
IDR = sum(TP_i,1) ./ obs_count;
IFP = sum(FP_i,1) ./ length(probmaplist);

%% Output
[~,idx] = min(abs(FPR - 0.02));
disp(['TPR:',num2str(TPR(idx)),...
    '  FPR:',num2str(FPR(idx)),...
    '  ITPR:',num2str(IDR(idx)),...
    '  IFPR:',num2str(IFP(idx))]);

parsave(savepath,TPR,'TPR',FPR,'FPR',IDR,'IDR',IFP,'IFP');

end
