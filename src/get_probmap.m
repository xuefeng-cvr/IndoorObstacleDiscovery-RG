function [prob_map] = get_probmap(top,resolution)

count = 0;
prob_map = zeros(resolution(2),resolution(1));
freq_map = zeros(resolution(2),resolution(1));

if size(top,1) > 50
    maxtop = 50;
else
    maxtop = size(top,1);
end
top_prob = top(1:maxtop,:);

for i = 1:size(top_prob,1)
    w = top_prob(i,:);
    weight = top_prob(i,5);
    count = count + 1;
    prob_map(w(2):w(2)+w(4)-1,w(1):w(1)+w(3)-1) = prob_map(w(2):w(2)+w(4)-1,w(1):w(1)+w(3)-1) + weight * (1./(freq_map(w(2):w(2)+w(4)-1,w(1):w(1)+w(3)-1)+1));
    freq_map(w(2):w(2)+w(4)-1,w(1):w(1)+w(3)-1) = freq_map(w(2):w(2)+w(4)-1,w(1):w(1)+w(3)-1) + 1;
end
prob_map = prob_map ./ max(prob_map(:));


end

