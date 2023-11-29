function [crop_im] = crop(im,crop_range)
%CROP 
% crop_range = [y0 x0 h w]
if length(size(im)) == 2
    crop_im = im(...
        crop_range(1) : (crop_range(3)+crop_range(1) - 1) ,...
        crop_range(2) : (crop_range(2)+crop_range(4) - 1));
else
    if length(size(im)) == 3
        crop_im = im(...
            crop_range(1) : (crop_range(3)+crop_range(1) - 1) ,...
            crop_range(2) : (crop_range(2)+crop_range(4) - 1),:);
    else
        error('Dimensions wrong');
    end
end
end

