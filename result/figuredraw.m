%% ROC ##################################################################
roc_1 = load('ROC_OD_rfmodel_AGFM.mat');

color=[1 0 0; 0 1 0; 0 0 1; 0.5 1 1;...
         1 1 0.5; 1 0.5 1; 0 0 0.5; 0.5 0 0;...
          0 0.5 0; 1 0.5 0.5; 0.5 1 0.5; 0.5 0.5 1;...
           1 1 0; 0 1 1; 1 0 1];

figure;
show_ROC(roc_1,3,1,'-',color(1,:)); hold on;

xlabel('False Positive Rate(FPR)');
ylabel('True Positive Rate(TPR)');
title('50% top draw on the map');  
legend('STR+SR',...
    'Location','southeast');
axis([0 0.04 0 1]);
grid on;
set(gca,'FontSize',15);
set(gcf, 'position', [0 0 600 550]);
set(gca,'FontName','times new roman');

[~,idx] = min(abs(roc_1.FPR - 0.02));
disp(['TPR:',num2str(roc_1.TPR(idx)),...
    '  FPR:',num2str(roc_1.FPR(idx)),...
    '  ITPR:',num2str(roc_1.IDR(idx)),...
    '  IFPR:',num2str(roc_1.IFP(idx))]);
