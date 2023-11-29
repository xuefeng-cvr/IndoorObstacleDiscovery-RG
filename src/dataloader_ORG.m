function [vars,datalists] = dataloader_ORG(vars)

vars.relpath_IMG   = 'image/';
vars.relpath_GT    = 'gtCoarse_Segmentation/';
vars.relpath_ODOM  = 'odometry/';
vars.relpath_TS    = 'timestamp/';
vars.relpath_TRAIN = 'train/';
vars.relpath_TEST  = 'test/';
vars.suffix_gtLabel= '_gtCoarse_labelIds.png';
vars.suffix_odom   = '_odom.txt';
vars.suffix_ts     = '_ts.txt';
vars.suffix_out    = 'proposal.png';


SceneName = dir(fullfile(vars.abspath_ORG,vars.relpath_IMG,vars.subdir));
SceneName(1:2)=[];
fname = fieldnames(SceneName);
hasFolder = 0;
for i = 1:size(fname,1)
    if isequal(fname{i},'folder')
        hasFolder = 1;
    end
end

imgs_list = cell(length(SceneName),1);
odom_list = cell(length(SceneName),1);
timestamp_list = cell(length(SceneName),1);
gtlabel_list = cell(length(SceneName),1);

for i=1:size(SceneName,1)
    imgs_list{i}        = dir(fullfile(vars.abspath_ORG,vars.relpath_IMG,vars.subdir,SceneName(i).name,'/0*'));
    odom_list{i}        = dir(fullfile(vars.abspath_ORG,vars.relpath_ODOM,vars.subdir,SceneName(i).name,['/*',vars.suffix_odom]));
    timestamp_list{i}   = dir(fullfile(vars.abspath_ORG,vars.relpath_TS,vars.subdir,SceneName(i).name,['/*',vars.suffix_ts]));
    gtlabel_list{i}     = dir(fullfile(vars.abspath_ORG,vars.relpath_GT,vars.subdir,SceneName(i).name,['/*',vars.suffix_gtLabel]));

    if ~hasFolder
        for j = 1:size(timestamp_list{i},1)
            imgs_list{i}(j).folder      = fullfile(vars.abspath_ORG,vars.relpath_IMG,vars.subdir,SceneName(i).name,'/');
            odom_list{i}(j).folder      = fullfile(vars.abspath_ORG,vars.relpath_ODOM,vars.subdir,SceneName(i).name,'/');
            timestamp_list{i}(j).folder = fullfile(vars.abspath_ORG,vars.relpath_TS,vars.subdir,SceneName(i).name,'/');
            gtlabel_list{i}(j).folder   = fullfile(vars.abspath_ORG,vars.relpath_GT,vars.subdir,SceneName(i).name,'/');
        end
    end

end
datalists.imgs_list = imgs_list;
datalists.odom_list = odom_list;
datalists.timestamp_list = timestamp_list;
datalists.gtlabel_list = gtlabel_list;
end

