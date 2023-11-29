function show_PR(PR,linewidth,ratio,LineStyle,color)

if nargin <= 3
    LineStyle = '-';
end

if nargin == 5
    plot(PR.recall, PR.precision * ratio,'LineWidth',linewidth,'LineStyle',LineStyle,'Color',color);
else
    plot(PR.recall, PR.precision * ratio,'LineWidth',linewidth,'LineStyle',LineStyle);
end

end