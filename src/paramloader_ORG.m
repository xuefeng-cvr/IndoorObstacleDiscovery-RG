function [vars] = paramloader_ORG()

model=load('modelBsds.mat'); % Loading model for edge detection
vars.mod_sed = model.model;

cg=load('camera_ground.mat');   % Loading ground and camera parameter of ORG
vars.camera_ground.K = cg.K;
vars.camera_ground.d = cg.d;
vars.camera_ground.n = cg.n;

vars.trav_distance_thresh = 20; % Threshold for judging the movement of robot

end
