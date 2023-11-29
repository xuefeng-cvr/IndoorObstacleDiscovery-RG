function [nextPts,status,err,fb_error] = cal_opticalflow(gimg_a,gimg_b,points)

if nargout == 3
    [nextPts,status,err] = LKopticalflow(gimg_a,gimg_b,points);
else
    [nextPts,status,err,authPts] = LKopticalflow_fb(gimg_a,gimg_b,points);
    diff_na = points - authPts;
    fb_error = sqrt(diff_na(:,1).*diff_na(:,1) + diff_na(:,2).*diff_na(:,2));
end
end

