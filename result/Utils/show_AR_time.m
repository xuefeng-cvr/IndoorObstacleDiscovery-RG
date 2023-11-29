function AR1_iou = show_AR_time(recalls,time,ratio,color)
%SHOW_AR_TIME 此处显示有关此函数的摘要
%   此处显示详细说明
[~,nious,ninsts] = size(recalls);
AR1_iou = 0;
for i = 1:nious
    cnts_AR1_iou = reshape(recalls(end,i,:),[1,ninsts])';
    AR1_iou = AR1_iou + sum(cnts_AR1_iou)/size(cnts_AR1_iou,1);
end
AR1_iou = AR1_iou / nious * ratio;


if nargin == 4
    gscatter(time,AR1_iou,0,color,'.',50)
else
    gscatter(time,AR1_iou,0,'.',50)
end

end

