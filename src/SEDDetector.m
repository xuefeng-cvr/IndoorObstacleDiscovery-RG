function [ucm] = SEDDetector( I,model)
%COMPUTE_OBSEDGE Summary of this function goes here
%   Detailed explanation goes here

model.opts.nms=-1; model.opts.nThreads=4;
model.opts.multiscale=0; model.opts.sharpen=2;
opts = spDetect;    %% set up opts
opts.nThreads = 4;  % number of computation threads
opts.k = 1024;      % controls scale of superpixels (big k -> big sp)
opts.alpha = .6;    % relative importance of regularity versus data terms
opts.beta = .9;     % relative importance of edge versus color terms
opts.merge = 0;     % set to small value to merge nearby superpixels at end

[E,~,~,segs]=edgesDetect(I,model);

[sp,~] = spDetect(I,E,opts);

[~,~,edgeo]=spAffinities(sp,E,segs,opts.nThreads);

ucm = single(edgeo);

end

