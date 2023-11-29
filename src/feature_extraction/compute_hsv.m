function [ hsi_feat ] = compute_hsv( HSI )
%COMPUTE_HSV Summary of this function goes here
%   Detailed explanation goes here
H = HSI(:,1)*360;
S = HSI(:,2);
I = HSI(:,3);
edges_1 = [0 15 25 45 55 80 108 140 165 190 220 255 275 290 316 330 345 361];
edges_2 = [0 0.0625 0.1250 0.1875 0.2500 0.3125 0.3750 0.4375 0.5000 0.5625 0.6250 0.6875 0.7500 0.8125 0.8750 0.9375 1.1];
[range_1, ~] = histc(H(:), edges_1); range_1(1) = range_1(1) + range_1(17);
[range_2, ~] = histc(S(:), edges_2); range_2(1) = range_2(1) + range_2(17);
[range_3, ~] = histc(I(:), edges_2); range_3(1) = range_3(1) + range_3(17);

if iscolumn(range_1), range_1 = range_1';end
if iscolumn(range_2), range_2 = range_2';end
if iscolumn(range_3), range_3 = range_3';end

hsi_feat = [range_1(1:16),range_2(1:16),range_3(1:16)];

end

