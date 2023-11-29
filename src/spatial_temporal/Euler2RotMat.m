function [R] = Euler2RotMat(e)
Rz = [...
    1,0,0;...
    0,cos(e(1)),-sin(e(1));...
    0,sin(e(1)),cos(e(1))];

Ry = [...
    cos(e(2)),0,sin(e(2));...
    0,1,0;...
    -sin(e(2)),0,cos(e(2))];

Rx = [...
    cos(e(3)),-sin(e(3)),0;...
    sin(e(3)),cos(e(3)),0;...
    0,0,1];

R = Rz*Ry*Rx;

end