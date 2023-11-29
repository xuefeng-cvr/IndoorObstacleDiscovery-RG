function [edges_num,edges,edge_map,junction_edge_map,edge_junction_map,edge_region_map]=get_info_of_edges(region_map,junctions_num,junctions,junction_map)
% get the information of edges
% INPUT:
% region_map ---- label image
% junctions_num ---- the number of junctions
% junctions ---- A matrix structure which records the coordinates of all the junctions
% junction_map ---- the index map of junctions
% OUTPUT:
% edges_num ---- the number of edges
% edges ---- A matrix structure which records the pixel count of every edge and the coordinates's index of all the points on the edge
% edge_map ----- the index map of edges
% junction_edge_map ---- Record the indexs of edges which are related to every junciton
% edge_junction_map ---- Record the indexs of junctions which are related to every edge
% edge_region_map ---- Record the relationship between the edge and the region

[h,w] = size(region_map);
region_map_cpy = int32(region_map);
junction_map = int32(junction_map);
region_map_cpy = ~(region_map_cpy+junction_map);
% After the above process, in region_map_cpy, the points on edges are 1,the other points are 0.
[edge_map,edges_num]=bwlabel(region_map_cpy,4);

% Record the index of pixels which compose every edge
edges=cell(edges_num,2);
for i=1:edges_num
    edges{i,1}=0;%count edge pixels
    edges{i,2}=zeros(500,1);%coordinates' index 
end

edge_map_tmp = edge_map(:);
rowvec = (1:length(edge_map_tmp))';
edge_map_tmp = edge_map_tmp+1;
groups = accumarray(edge_map_tmp, rowvec, [], @(x){x}); 
groups = groups(2:end);
edges(:,2) = groups;
edges(:,1) = cellfun(@(x) size(x,1),groups,'uniformoutput',false);

%*******************************Record the indexs of edges which are related to every junciton �������� Record the indexs of junctions which are related to every edge******************************* 
%Record the indexs of edges which are related to every junciton
%the mapping between junction and connected edges
junction_edge_map=cell(junctions_num,2);
for i=1:junctions_num
    junction_edge_map{i,1}=0;%Record the number of edges which are related to every junciton 
    junction_edge_map{i,2}=zeros(4,1);%Record the indexs of edges which are related to every junciton 
end
%Record the indexs of junctions which are related to every edge
%the mapping between edge and two end junctions
edge_junction_map=zeros(edges_num,2);%Record the indexs of junctions

%direction matrix
direction=zeros(8,2);
direction(1,:)=[-1,0];
direction(2,:)=[1,0];
direction(3,:)=[0,-1];
direction(4,:)=[0,1];
direction(5,:)=[-1,-1];
direction(6,:)=[-1,1];
direction(7,:)=[1,-1];
direction(8,:)=[1,1];

for i=1:junctions_num
    %coordinates
    a=junctions(i,1); b=junctions(i,2);
    for j=1:4
         if a+direction(j,1)>=1&&a+direction(j,1)<=h&&b+direction(j,2)>=1&&b+direction(j,2)<=w&&edge_map(a+direction(j,1),b+direction(j,2))~=0
          %If the junction is not on the image's border and is actually on the edge after it has been moved
            a_=a+direction(j,1);
            b_=b+direction(j,2);
            junction_edge_map{i,1}=junction_edge_map{i,1}+1;
            junction_edge_map{i,2}(junction_edge_map{i,1},1)=edge_map(a_,b_);
            if edge_junction_map(edge_map(a_,b_),1)==0&&edge_junction_map(edge_map(a_,b_),2)==0
                edge_junction_map(edge_map(a_,b_),1)=i;
            else if edge_junction_map(edge_map(a_,b_),2)~=1
                    edge_junction_map(edge_map(a_,b_),2)=i;
                 end 
            end
         end
    end
end

edge_region_map=zeros(edges_num,2);

for i=1:edges_num
    for j=1:edges{i,1}
        [a,b] = ind2sub([h,w],edges{i,2}(j));     
        if a-1>=1&&a+1<=h&&edge_map(a-1,b)==0&&edge_map(a+1,b)==0&&junction_map(a-1,b)==0&&junction_map(a+1,b)==0
           edge_region_map(i,:)=[region_map(a-1,b),region_map(a+1,b)];
           break;
        end
        if b-1>=1&&b+1<=w&&edge_map(a,b-1)==0&&edge_map(a,b+1)==0&&junction_map(a,b-1)==0&&junction_map(a,b+1)==0
           edge_region_map(i,:)=[region_map(a,b-1),region_map(a,b+1)];
           break;
        end     
        if a-1>=1&&b-1>=1&&a+1<=h&&b+1<=w&&edge_map(a-1,b-1)==0&&edge_map(a+1,b+1)==0&&junction_map(a-1,b-1)==0&&junction_map(a+1,b+1)==0
           edge_region_map(i,:)=[region_map(a-1,b-1),region_map(a+1,b+1)];
           break;
        end 
         if a-1>=1&&b+1<=w&&a+1<=h&&b-1>=1&&edge_map(a-1,b+1)==0&&edge_map(a+1,b-1)==0&&junction_map(a-1,b+1)==0&&junction_map(a+1,b-1)==0
           edge_region_map(i,:)=[region_map(a-1,b+1),region_map(a+1,b-1)];
           break;
         end        
    end    
end

for i=1:edges_num
    if edge_region_map(i,1)==0&&edge_region_map(i,2)==0
        flag=false;
        for j=1:edges{i,1}
            if ~flag
                [a,b] = ind2sub([h,w],edges{i,2}(j));
                for k=1:4
                    if ~flag
                        if a+direction(k,1)>=1&&a+direction(k,1)<=h&&b+direction(k,2)>=1&&b+direction(k,2)<=w&&region_map(a+direction(k,1),b+direction(k,2))~=0
                            flag=true;
                            edge_region_map(i,:)=[region_map(a+direction(k,1),b+direction(k,2)),region_map(a+direction(k,1),b+direction(k,2))];
                        end
                    end
                end
            end
        end
    end
end

end