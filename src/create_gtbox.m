function [gt_b] = create_gtbox(gt, inst_id)

[y,x] = find(gt == inst_id);

%% Construct a ground truth bounding box for training
maxX_s = max(x)+1;
if maxX_s > size(gt,2) + size(gt,4), maxX_s = size(gt,2) + size(gt,4); end
maxY_s = max(y)+1;
if maxY_s > size(gt,1) + size(gt,3), maxY_s = size(gt,1) + size(gt,3); end
minX_s = min(x)-1;
if minX_s < 1, minX_s = 1; end
minY_s = min(y)-1;
if minY_s <1, minY_s = 1; end
h = maxY_s - minY_s;
w = maxX_s - minX_s;

gt_b = [minX_s,minY_s,w,h];

end

