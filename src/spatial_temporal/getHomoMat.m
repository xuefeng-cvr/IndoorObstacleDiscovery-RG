function [h,R,t] = getHomoMat(cg,rpos,rque)

r1= Quat2RotMat(rque(1,:));
r2= Quat2RotMat(rque(2,:));
R = r1*(r2^-1);
R_rc = Euler2RotMat([-1.513175  -0.058063  -1.591760]);
t_rc2 = [-89.661;5.842;0];

t_c1 = R_rc*(rpos(1,:)' + r1 * t_rc2);
t_c2 = R_rc*(rpos(2,:)' + r2 * t_rc2);
t = (t_c2 - t_c1);

h = cg.K*(R-t*cg.n'/cg.d)*inv(cg.K);
end