% FUNCTION fnames = dirf(suffix)
%
% Unlike the dir() function, which returns an array of structs,
% dirf() returns a cell array of the files within the dir
% which match the filter/suffix provided
%
% Inputs:
%     suffix - a filter for files (such as *.dcm)
%
% Outputs:
%     fnames - a cell array of file names matching the filter
%
% Samuel A. Hurley
% University of Wisconsin
% v1.0 11-Mar-2011
%
% Changelog:
%     v1.0 - Based on previous (unversioned) dirf.  Changed from a matrix
%     of chars to a cell array for better memory management, and removes
%     the need to use strtrim() if the size of the file names are
%     different. (Mar-2011)

function fnames = dirf(suffix)

dirnames = dir(suffix);
fnames   = cell(0);

jj = 1;
 
for ii = 1:size(dirnames)
  if ~strcmp(strtrim(dirnames(ii).name), '.') && ~strcmp(strtrim(dirnames(ii).name), '..')
    fnames{jj} = dirnames(ii).name;
    jj = jj + 1;
  end
end