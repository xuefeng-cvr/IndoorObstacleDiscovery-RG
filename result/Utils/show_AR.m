function show_AR(recalls,cnts,linewidth,ratio,LineStyle,color)
%COMPUTE_IOU_RECALL �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
if nargin <= 4
    LineStyle = '-';
end


[ncnts,nious,ninsts] = size(recalls);
AR1_iou = zeros(1,ncnts);
for i = 1:nious
    cnts_AR1_iou = reshape(recalls(:,i,:),[ncnts,ninsts])';
    AR1_iou = AR1_iou + sum(cnts_AR1_iou)/size(cnts_AR1_iou,1);
end
AR1_iou = AR1_iou / nious * ratio;
if nargin == 6
    plot(cnts,AR1_iou,'LineWidth',linewidth,'LineStyle',LineStyle,'Color',color);
else
    plot(cnts,AR1_iou,'LineWidth',linewidth,'LineStyle',LineStyle);
end
end

