% FUNCTION img = load_fdf_all(dirname)
% Load all FDF in a directory, in linear order
% Works on 2-d scans, loads magnitude data
% 
% Inputs:
%    dirname - the name of the directory containing fdf files (xx.img)
%
% Outputs:
%    img     - a 3D, 4D, or 5D image (depending on the number of phases and
%              echoes in the scan)
%
% Samuel A. Hurley
% University of Wisconsin - Madsion
% v1.6 27-Aug-2010
%
% Changelog: 
%       1.1 -Fixed multi-image & multi-echo load order
%       1.2 -Automatically load necho nimage & nslice from procpar,
%            if not specified
%       1.3 -spelling errors(Jul-2009)
%       1.4 -can now recon a non-compressed phase encode (seqcon='ccsnn') (Mar-2010)
%       1.5 -preallocates output array for much faster performance     (Jul-2010)
%       1.6 -fixed bug causing it not to work in if dirname ~= '.'     (Aug-2010)


function img = load_fdf_all(dirname)

% O. Check input arguments
if ~exist('dirname', 'var')
  dirname = '.';
end

% Read header data
info   = load_procpar(fullfile(dirname,'procpar'));
nslice = info.ns;
nimage = info.arraydim;
necho  = info.ne;

% FIX: Check for EPI pulse sequence, remove 1 image for ref scan
if strcmp(info.seqfil, 'epip') || strcmp(info.seqfil,'epi_dti_2.2C') || strcmp(info.seqfil, 'epi_dwi')
  nimage = nimage - 1;
end

% FIX: Non-compressed phase encodes problem
if strcmp(info.seqcon(3), 's')
  nimage = nimage / info.nv;
end

% Grab a list of all fdf files
fnames = dirf(fullfile(dirname, '*.fdf'));

% Read matrix size
[x M] = load_fdf(fullfile(dirname, fnames{1}), 1); %#ok<ASGLU>

disp(['Matrix: ' num2str(M(1)) 'x' num2str(M(2)) ' Slices: ' num2str(nslice) ' Images: ' num2str(nimage) ' Echoes: ' num2str(necho)]);

if size(fnames, 2) ~= (nslice*nimage*necho)
  error('You didn''t specify the correct # of images');
end

if nimage == 1 && necho == 1
  % Single-phase, set of slices
  for ii = 1:size(fnames, 2)
    img(:,:,ii) = load_fdf(fullfile(dirname, fnames{ii}), 1); %#ok<AGROW>
  end
  
elseif nimage == 1
  % 4th dimension is multi-echo
  
  % Preallocate
  img = zeros([M(1) M(2) nslice necho]);
  
  img_num = 1;
  
  for ii = 1:nslice
    for jj = 1:necho
      img(:,:,ii,jj) = load_fdf(fullfile(dirname, fnames{img_num}), 1);
      img_num = img_num + 1;  % Load Next image
    end
  end
 
elseif necho == 1
  % 4th dimension is multi-phase (multi-image/timeseries)
  
  % Preallocate
  img = zeros([M(1) M(2) nslice nimage]);
  
  img_num = 1;
  
  for ii = 1:nslice
    for jj = 1:nimage
      progressbar(((ii-1)*nimage+jj)/(nimage*nslice));
      img(:,:,ii,jj) = load_fdf(fullfile(dirname, fnames{img_num}), 1);
      img_num = img_num + 1;  % Load Next image
    end
  end
  
  
else
  % 5-D data, arranged as echo then image
  % warning: may blow your mind
  
  % Preallocate
  img = zeros([M(1) M(2) nslice nimage necho]);
  
  img_num = 1;
  
  for ii = 1:nslice
    for jj = 1:nimage
      for kk = 1:echo
        img(:,:,ii,jj,kk) = load_fdf(fullfile(dirname, fnames{img_num}), 1);
        img_num = img_num + 1;
      end
    end
  end
  
end

% Done