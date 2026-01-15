% Flips a 3-d array in the up/down direction

function flipped = imflipud(im)

flipped = zeros(size(im));

% 3-D
if ndims(im) == 2
  flipped = flipud(im);

elseif ndims(im) == 3
  for j = 1:size(im,3)
    flipped(:,:,j) = flipud(im(:,:,j));
  end
  
% 4-D

elseif ndims(im) == 4
  for ii = 1:size(im, 4)
    flipped(:,:,:,ii) = imflipud(im(:,:,:,ii));
  end
  
elseif ndims(im) == 5
    for jj = 1:size(im, 5)
        flipped(:,:,:,:,jj) = imflipud(im(:,:,:,:,jj));
    end
    
else
    error('Too many dims! (Max of 5)');
    
end