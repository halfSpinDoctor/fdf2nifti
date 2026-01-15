% FUNCTION img_vnmr_to_nifti(img, info, fname, concat)
%
% Converts a matlab image variable (3d or 4d) to a
% NIfTI-1.1 file.  Generates NIfTI header data from
% the procpar file.
%
% External Dependancies: SPM (Tested with SPM8)
% 
% Samuel A. Hurley
% University of Wisconsin
% v3.1 28-Feb-2018
%
% Changelog:
%    v1.0 - Initial version, based on fdf_to_nifti (Sept-2009)
%    v2.0 - Added concat option, as in img_2d_to_nifti (Oct-2010)
%    v2.1 - Fixed a problem which threw away the first volume in a merged
%           dataset (concat = 1 option) (Feb-2011)
%    v3.0 - Combined img_3d_to_nifti and img_2d_to_nifti into a single
%           command, img_vnmr_to_nifti (Feb-2011)
%    v3.1 - Fixes for oblique orientation, validation for marm. imaging project
%           (Feb-2018)

function img_vnmr_to_nifti(img, info, fname, concat)

if ndims(img) > 4
  error('Can only generate 2-D, 3-D, or 4-D NIfTI images');
end

if ~exist('concat', 'var')
  concat = 0;
end

% MATLAB uses matrix orientation, need to convert to normal indexing
% for use as NIFTI file.  Tested & produces correct L-R orientation
% (at least for a coronal acquisition it does).

% Flip Image up-down
img = imflipud(img);

% Transpose image
img = imtranspose(img);

% Generate an SPM struct for nifti header information
V = spm_vol;

% Generate an SPM matrix for orientation and fov
% theta - about x, pitch
% psi   - about y, roll
% phi   - about z, yaw

% NB: the angles specified by SPM are called psi-x, phi-y, theta-z
%     but the names in VnmrJ are theta-x, psi-y, phi-z

% axial    - 0 0 0
% coronal  - 0 0 90
% sagitaal - 0 90 90

DEG = pi./180;  % Convert degrees to radians

% Grab z-size (depends on if its PE2 in a 3d sequence, or multislice)
% SAH 2018-02-28: also add slice gap for 2D sequences into the spacing
if info.nv2 > 0
  thk  = info.lpe2*10/info.nv2;
else
  thk  = info.thk + info.gap*10;
end


% Generate orientation matrix
% SAH 2018-02-28: info.pss0 is the z-offset of the centre of the volume,
%                 while info.pss(1) is the z-offset of the 1st slice in the vol.
%                 Use info.pss(1)-thk, as the corner point of the slice is
%                 defined on the opposite edge of the slice (SAH: Or thk/2??)
%
% SAH 2018-03-01: Note that x-direction is PE and y-direction is RO
%
% SAH 2018-03-01: Use matrix size of image instead of np/nv (number of RO
% points, number of PE steps), since it is reconstructed image size that matters
%
voxDims      = [ info.lpe*10/size(img, 1)       info.lro*10/size(img, 2)     thk                 ];
cornerPoints = [-info.ppe*10/2 - info.lpe*10/2 -info.pro*10 - info.lro*10/2   info.pss(1)*10 - thk];

V(1).mat     = spm_matrix([cornerPoints(1), cornerPoints(2), cornerPoints(3), ...
                           info.theta(1)*DEG, info.psi(1)*DEG, info.phi(1)*DEG, ...
                           voxDims(1), voxDims(2), voxDims(3)], 'R*T*Z*S');

% Output voxel dimensions
disp(['Voxel Dimensions: ' num2str([info.lro*10/size(img, 1), info.lpe*10/size(img, 2), thk])]);

dim     = size(img);
V.dim   = dim(1:3);
V.dt    = [16 0];
V.pinfo = [1 0 2528]';

% If its only a 3-D image, write out a single image with one filename
if size(img, 4) == 1
  V.fname = [fname '.nii'];
  spm_write_vol(V, img);
  
  
% If it is a 3-plane image, write out each slice group with different
% geometry orientation information
elseif strcmp(info.orient, '3orthogonal')
  if size(img, 4) ~= 3
    error('3-plane scout should have exactly 3 volumes');
  end
  
  % Suffix to append to scout images
  fname_suffix = ['a' 'b' 'c'];
  
  for ii = 1:3
    
    V(1).mat = spm_matrix([cornerPoints(1), cornerPoints(2), cornerPoints(3), ...
                           info.theta(ii)*DEG, info.psi(ii)*DEG, info.phi(ii)*DEG, ...,
                           voxDims(1), voxDims(2), voxDims(3)], 'R*T*Z*S');
    
    V.fname = [fname '_' fname_suffix(ii) '.nii'];
    spm_write_vol(V, img(:,:,:,ii));
  end
  
% Otherwise, for 4D input, write out a separate file for each image volume
% Assume identical geomoetry for all 3D volumes in the series
else
  fprintf('Converting FDF->NIfTI...');

  for ii = 1:size(img, 4)
    if concat == 1
      V.fname = ['tmp1234_' num2str(ii, '%04.0f') '.nii'];
    else
      V.fname = [fname  '_' num2str(ii, '%04.0f') '.nii'];
    end
    V = spm_write_vol(V, img(:,:,:,ii));
    progressbar(ii/size(img,4));
  end
  
  if concat == 1
    !fslmerge -t tmp_merge tmp1234_*
    eval(['!mv tmp_merge.nii.gz ' fname '.nii.gz']);
    !rm -f tmp1234_*
  end

end

