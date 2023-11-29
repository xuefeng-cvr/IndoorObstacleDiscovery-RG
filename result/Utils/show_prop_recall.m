function show_prop_recall(recalls,thresh_idx_iou,cnts,linewidth,ratio,LineStyle,color)
%COMPUTE_IOU_RECALL �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
if nargin <= 5
    LineStyle = '-';
end

[ncnts,~,ninsts] = size(recalls);
cnts_recalls1 = reshape(recalls(:,thresh_idx_iou,:),[ncnts,ninsts])';
plot1 = sum(cnts_recalls1)/size(cnts_recalls1,1)*ratio;
% plot(cnts,plot1,'LineWidth',linewidth,'LineStyle',LineStyle);

if nargin == 7
    plot(cnts,plot1,'LineWidth',linewidth,'LineStyle',LineStyle,'Color',color);
else
    plot(cnts,plot1,'LineWidth',linewidth,'LineStyle',LineStyle);
end
end

