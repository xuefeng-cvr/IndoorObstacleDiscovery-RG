function show_IFP_IDR(roc,linewidth,isSmooth,LineStyle,color)
    %COMPUTE_IOU_RECALL �˴���ʾ�йش˺�����ժҪ
    %   �˴���ʾ��ϸ˵��
    
    if nargin <= 3
        LineStyle = '-';
    end
    
    idr = roc.IDR;
    ifp = roc.IFP;
    
    if isSmooth
        values = spcrv([...
            [ifp(1) ifp ifp(end)];...
            [idr(1) idr idr(end)]],100);
            ifp = values(1,:); idr = values(2,:);
    end
    
    if nargin == 5
        plot(ifp(1:end),idr(1:end),'-','LineWidth',linewidth,'LineStyle',LineStyle,'Color',color);
    else
        plot(ifp(1:end),idr(1:end),'-','LineWidth',linewidth,'LineStyle',LineStyle);
    end
    end