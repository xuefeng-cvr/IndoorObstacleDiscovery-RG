function [regions_num,regions,region_map]=get_info_of_regions(label_num,label_image)
% get the information of regions
% INPUT:
% label_num ---- the number of superpixels which are segmented by structured edge detector from "Fast Edge Detection Using Structured Forests"
% label_image ---- label image
% OUTPUT:
% regions_num ---- label_num
% region_map ---- label image
% regions ----- A cell structure which records the number of points in each sp and the coordinates's index of all the points in the sp

regions_num=label_num;%region number
region_map=label_image;%index map

regions=cell(regions_num,2);
[idx,~] = find(label_image(:)); %remove the points which are not in any superpixel
label_image = label_image(idx);
rowvec = (1:length(label_image))';
% group the location indexs which are in different superpixel blocks, that is, you can directly get the index of all pixels in different superpixel blocks
groups = accumarray(label_image, rowvec, [], @(x){x}); 
regions(:,2) = groups; %record the coordinates's index of all the points in the superpixel
regions(:,1) = cellfun(@(x) size(x,1),groups,'uniformoutput',false); %record the number of points in each sp 

end

