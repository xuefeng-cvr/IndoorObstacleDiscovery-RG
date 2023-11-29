function show_PFP_IDR(roc,linewidth,isSmooth,LineStyle,color)
%COMPUTE_IOU_RECALL �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��

if nargin <= 3
    LineStyle = '-';
end

% tpr = roc.TPR;
% fpr = roc.FPR;

idr = roc.IDR;
fpr = roc.FPR;

if isSmooth
    values = spcrv([...
        [fpr(1) fpr fpr(end)];...
        [idr(1) idr idr(end)]],100);
    fpr = values(1,:); idr = values(2,:);
end

if nargin == 5
    plot(fpr(1:end),idr(1:end),'-','LineWidth',linewidth,'LineStyle',LineStyle,'Color',color);
else
    plot(fpr(1:end),idr(1:end),'-','LineWidth',linewidth,'LineStyle',LineStyle);
end
end