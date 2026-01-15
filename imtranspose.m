function imout = imtranspose(imin)

% Preallocate, but only for a square image
dims = size(imin);
if dims(1) == dims(2)
  imout = zeros(size(imin));
end

if ndims(imin) == 2
  imout = imin';

% 3-D Image Matrix
elseif ndims(imin) == 3
  zdim = size(imin, 3);

  if zdim == 1
    imout = imin';
  else
    for j = 1:zdim
      imout(:,:,j) = imin(:,:,j)';
    end
  end

% 4-D Image
elseif ndims(imin) == 4
  % Do some recursive magic!
  for ii = 1:size(imin, 4)
    imout(:,:,:,ii) = imtranspose(imin(:,:,:,ii));
  end

% Will we ever do a 5-D image?
else
  error('Does not support 5-D image');
end
  