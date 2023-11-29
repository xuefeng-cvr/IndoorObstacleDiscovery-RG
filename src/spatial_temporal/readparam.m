function [content,data] = readparam(filepath,format)
file = fopen(filepath,'r');
content = textscan(file,format,10000,'HeaderLines',0);
data = cell2mat(content(2:end));
fclose(file);
end

