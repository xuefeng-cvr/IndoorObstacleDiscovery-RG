function mkDirs(path)
%MKDIRS 此处显示有关此函数的摘要
%   此处显示详细说明

S = regexp(path, '/', 'split');
if isempty(S{1})
    S(1) = [];
end
currDir = S{1};
if path(1) == '/'
    currDir = ['/',currDir];
end
for i = 2:length(S)
    currDir = [currDir '/' S{i}];
    if exist(currDir)==0
        mkdir(currDir);
    end
end

end

