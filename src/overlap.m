function [iou] = overlap(A,B)
%OVERLAP 此处显示有关此函数的摘要
%   此处显示详细说明
C=[A;B];
C = unique(C);
D = intersect(A,B);

iou = numel(D)/numel(C);
end

