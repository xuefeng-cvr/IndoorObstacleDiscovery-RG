function [junctions_num,junctions,junction_map]=get_info_of_junctions(image)
% get the information of junctions
% INPUT:
% image ---- region_map
% OUTPUT:
% junctions_num ---- the number of junctions
% junction_map ---- the index map of junctions
% junctions ----- A matrix structure which records the coordinates of all the junctions

[x,y,z]=size(image);
junctions_num=0;
junctions=zeros(1000,2);%%coordinates
junction_map=zeros(x,y);%%index map

for i=1:x
    for j=1:y
        if ((i==1&&j==1)||(i==x&&j==1)||(i==x&&j==y)||(i==1&&j==y))%%four corner points
            if image(i,j)==0%%edge points
                junctions_num=junctions_num+1;
                junctions(junctions_num,:)=[i,j];
                junction_map(i,j)=junctions_num;
            end
            continue;
        end
        
        if image(i,j)==0%%edge points
        %%non-boundary (T-junctions with over 3 edge connection)
            if i-1>=1&&i+1<=x&&j-1>=1&&j+1<=y&&((image(i-1,j)==0)+(image(i+1,j)==0)+(image(i,j-1)==0)+(image(i,j+1)==0))>=3
                junctions_num=junctions_num+1;
                junctions(junctions_num,:)=[i,j];
                junction_map(i,j)=junctions_num;
            end
         %%boundary  
            if i==1||i==x||j==1||j==y
                if i==1&&((image(i+1,j)==0)+(image(i,j-1)==0)+(image(i,j+1)==0))==1
                    junctions_num=junctions_num+1;
                    junctions(junctions_num,:)=[i,j];
                    junction_map(i,j)=junctions_num;
                end
                if i==x&&((image(i-1,j)==0)+(image(i,j-1)==0)+(image(i,j+1)==0))==1
                    junctions_num=junctions_num+1;
                    junctions(junctions_num,:)=[i,j];
                    junction_map(i,j)=junctions_num;
                end
                if j==1&&((image(i,j+1)==0)+(image(i-1,j)==0)+(image(i+1,j)==0))==1
                    junctions_num=junctions_num+1;
                    junctions(junctions_num,:)=[i,j];
                    junction_map(i,j)=junctions_num;
                end
                if j==y&&((image(i,j-1)==0)+(image(i-1,j)==0)+(image(i+1,j)==0))==1
                    junctions_num=junctions_num+1;
                    junctions(junctions_num,:)=[i,j];
                    junction_map(i,j)=junctions_num;
                end
            end
        end
    end
end

    