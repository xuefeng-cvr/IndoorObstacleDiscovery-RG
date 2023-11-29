function [imageWithOverlay] = vis_obs(img,mask)

color = [2 0.5 0.5];
for c = 1:3
    imageWithoutOverlay(:, :, c) = img(:, :, c) .* (1 - mask);
    imageWithOverlay(:, :, c) = img(:, :, c) .* mask * color(c);
end
imageWithOverlay = imageWithoutOverlay + imageWithOverlay;
end

