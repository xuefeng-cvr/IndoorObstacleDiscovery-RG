function [bbox,O] = get_proposal(E)

alpha       = 0.65;
kappa       = 1.7;
minScore    = 0.01;
maxNum      = 10000;
maxRatio    = 6;
minArea     = 600;

E=E./max(max(E)); 
E=single(E); %normalization
O=calO(E); 
O=single(O); %orientation

bbox=scorebox(E,O,alpha,kappa,minScore,maxNum,maxRatio,minArea); %proposal with norm input

end