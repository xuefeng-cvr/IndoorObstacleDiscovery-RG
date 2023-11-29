function show_iou_recall(recalls,thresh_idx_cnt,ious,linewidth,ratio,LineStyle,color)
%COMPUTE_IOU_RECALL �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
if nargin <= 5
    LineStyle = '-';
end

[~,nious,ninsts] = size(recalls);
iou_recalls1 = reshape(recalls(thresh_idx_cnt,:,:),[nious,ninsts])';
plot1 = sum(iou_recalls1)/size(iou_recalls1,1) * ratio;

if nargin == 7
    plot(ious,plot1,'LineWidth',linewidth,'LineStyle',LineStyle,'Color',color);
else
    plot(ious,plot1,'LineWidth',linewidth,'LineStyle',LineStyle);
end

end

