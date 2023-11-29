function [edge_info, p_of, p_homo] = compute_of_homo(robot_pos_ab,robot_que_ab,img_a,img_b,ucm,camera_ground)
    
% p_of:     The position of img_a's edge point in img_b.
% p_homo:   The position of img_a's edge point transfomed by the ground homography
% edge_info:All information
%   diff_hn:    Difference between p_homo and p_of
%   homo_error: Homography error of points
%   devi_angle: Deviation angle of points
%   feat_error: Feature error indicating forward-backward error

gimg_a=rgb2gray(img_a);
gimg_b=rgb2gray(img_b);

% Cut the edges into sections
edge_clusters = ucm2cluster(ucm,0.8);

for j = 1:size(edge_clusters,1)
    [y,x]= ind2sub([size(img_a,1),size(img_a,2)],edge_clusters{j,2});
    edge_clusters{j,2} = [x,y];
end

edge_info = cat(1,edge_clusters{:,2});
[p_of,~,~,feat_error] = cal_opticalflow(gimg_a,gimg_b,edge_info(:,1:2));
[h,~,~] = getHomoMat(camera_ground,robot_pos_ab,robot_que_ab);

p_homo = h * [edge_info(:,1:2),ones(size(edge_info,1),1)]';
p_homo(1,:) = p_homo(1,:)./p_homo(3,:);
p_homo(2,:) = p_homo(2,:)./p_homo(3,:);
p_homo(3,:) = [];
p_homo = p_homo';

diff_hn = p_of-p_homo;
homo_error = sqrt(sum(diff_hn.^2,2));
devi_angle = asin(diff_hn(:,2)./homo_error(:)); %/pi*180;

count = 1;
for j = 1:length(edge_clusters)
    edge_info(count:count+edge_clusters{j,1}-1,3) = j;
    edge_info(count:count+edge_clusters{j,1}-1,4) = mean(feat_error(count:count+edge_clusters{j,1}-1));
    count = count + edge_clusters{j,1};
end

edge_info = [edge_info, diff_hn, homo_error, devi_angle, feat_error];
end

