function [cluster] = ucm2cluster(ucm,percent)

overseg_image = (ucm < 0.01);
[region_map,regions_num] = bwlabel(overseg_image);

[regions] = get_info_of_regions(regions_num,region_map);
[junctions_num,junctions,junction_map] = get_info_of_junctions(region_map);
[edges_num,edges,~,~,~,~]=get_info_of_edges(int32(region_map),junctions_num,junctions,junction_map);
edge_mean_strength_map=calculate_edge_mean_strength(ucm,edges_num,edges);

[~,Estrength_idx] = sort(edge_mean_strength_map);
keyidx = Estrength_idx(end-floor(size(edge_mean_strength_map,1)*percent):end);
thresh = edge_mean_strength_map(keyidx(1));
ucm(ucm<thresh)=0;
cluster = edges(keyidx,:);

end

