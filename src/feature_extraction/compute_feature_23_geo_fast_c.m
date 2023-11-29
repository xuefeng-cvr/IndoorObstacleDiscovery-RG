function [feat] = compute_feature_23_geo_fast_c(bbox,img,ucm,im_size,integralhsv,edge_geo,dist)

param.im_size = im_size;
hsv = rgb2hsv(img);
[H,W] = size(ucm);
bbox(bbox(:,1) < 1,1) = 1;
bbox(bbox(:,2) < 1,2) = 1;
bbox(bbox(:,3) > W,3) = W;
bbox(bbox(:,4) > H,4) = H;
windows = bbox;
windows(:,1:2) = windows(:,1:2) + windows(:,3:4)./2;
pb_feat = calMaxPb(windows,ucm);
bb_feat = calBBFeat(windows,param);
hsistd_feat = calHsiStdFeat(windows,hsv);
hsi_feat = calHSVdist(bbox,integralhsv);
geo_feat = calGeoFeat(bbox,edge_geo,dist);
feat = [pb_feat bb_feat hsistd_feat hsi_feat geo_feat];

end

function hsv_dist = calHSVdist(bbox,integralhsv) %bbox [ x y w h ] / the indexes of pixels in integralhsv are plused by 1
w = size(integralhsv,2) - 1;
h = size(integralhsv,1) - 1;
b_bbox = zeros(size(bbox));
f_bbox = bbox;
f_bbox(:,3) = f_bbox(:,1) + f_bbox(:,3) - 1;
f_bbox(:,4) = f_bbox(:,2) + f_bbox(:,4) - 1;
b_bbox(:,1) = bbox(:,1) - bbox(:,3)/2;
b_bbox(:,2) = bbox(:,2) - bbox(:,4)/2;
b_bbox(:,3) = bbox(:,1) + bbox(:,3) + bbox(:,3)/2;
b_bbox(:,4) = bbox(:,2) + bbox(:,4) + bbox(:,4)/2;
b_bbox(b_bbox(:,1)<1,1) = 1;
b_bbox(b_bbox(:,2)<1,2) = 1;
b_bbox(b_bbox(:,3)>w,3) = w;
b_bbox(b_bbox(:,4)>h,4) = h;
b_bbox = int32(b_bbox);
f_bbox = int32(f_bbox);
hsv_dist = mex_HSVdist(f_bbox,b_bbox,integralhsv);
end

function hsiStd_feat = calHsiStdFeat(windows,HSV)
windows(:,1:2) = windows(:,1:2) - windows(:,3:4)./2;
hsiStd_feat = hsiStd_fast_c(windows,HSV);
end

function pb_feat = calMaxPb(windows,ucm)
r = windows(:,1:4); % original window
r(:,1:2) = r(:,1:2) - r(:,3:4) / 2;
r(:,3:4) = r(:,1:2) + r(:,3:4) - 1;
r = int32(r);
r(r(:,3) > size(ucm,2),3) = size(ucm,2);
r(r(:,4) > size(ucm,1),4) = size(ucm,1);
r_c = windows(:,1:4); % center window
r_c(:,3:4) = r_c(:,3:4) / 2;
r_c(:,1:2) = r_c(:,1:2) - r_c(:,3:4) / 2;
r_c(:,3:4) = r_c(:,1:2) + r_c(:,3:4) - 1;
r_c = int32(r_c);
edge_map = single(ucm > 0);
skip = [0.01, 0.0114, 0.0155, 0.024, 0.043, 0.08, 0.154, 0.27, 0.38, 0.55, 1]; 
pb_feat = mex_MaxPb(ucm,edge_map,windows,r,r_c,skip);
for i = 1:size(windows,1)
    ucmPatch = ucm(r(i,2):r(i,4),r(i,1):r(i,3));
    pb_feat(i,1) = max(ucmPatch(:));
end
pb_feat(isnan(pb_feat(:,3)),3) = 0;
pb_feat(isnan(pb_feat(:,2)),2) = 0;
pb_feat(isnan(pb_feat(:,1)),1) = 0;

end

function bb_feat = calBBFeat(windows,param)
im_size = param.im_size;
bb_feat = zeros(size(windows,1),7);
bb_feat(:,1) = windows(:,3).*windows(:,4) / (im_size(1)*im_size(2)); % normalized pixel area
bb_feat(:,2) = windows(:,3)./windows(:,4);    % aspect ratio
bb_feat(:,3) = windows(:,5);    % Occlusion score
bb_feat(:,4) = windows(:,1)./ im_size(1);% x
bb_feat(:,5) = windows(:,2)./ im_size(2);% y
bb_feat(:,6) = windows(:,3)./ im_size(1);% w
bb_feat(:,7) = windows(:,4)./ im_size(2);% h
end

function geo_feat = calGeoFeat(bbox,edge_geo,forward)
bbox(:,3) = bbox(:,1) + bbox(:,3) - 1;
bbox(:,4) = bbox(:,2) + bbox(:,4) - 1;
bbox(bbox(:,1)<1,1) = 1;
bbox(bbox(:,2)<1,2) = 1;
bbox(bbox(:,3)>1920,3) = 1920;
bbox(bbox(:,4)>1080,4) = 1080;
bbox = int32(bbox);
edge_geo = double(edge_geo);
forward = double(forward);
geo_feat = mex_GeoFeat_all_for_test(bbox,edge_geo,forward);
end
