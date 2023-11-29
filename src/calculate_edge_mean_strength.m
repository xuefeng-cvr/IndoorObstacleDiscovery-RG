function [edge_mean_strenth_map]=calculate_edge_mean_strength(ucm,edges_num,edges)
%%calculate edge mean strength

edge_mean_strenth_map=zeros(edges_num,1);
for index=1:edges_num
    for i=1:edges{index,1}
        edge_mean_strenth_map(index,1)=edge_mean_strenth_map(index,1)+ucm(edges{index,2}(i));
    end
    edge_mean_strenth_map(index,1)= edge_mean_strenth_map(index,1)/edges{index,1};
end
end