% Function [] = load_binfo(dirname);
%
% Convert procpar file from DTI series into bvals and bvecs files
% for use with FSL analysis Output files exist in the current directory
%
% Inputs:
%    info - a varian header structure as read by load_procpar
%
% Outputs:
%    EXPLICIT: None
%    IMPLICIT: Saves two files called bvals and bvecs, which are compatible
%              with FSL analysis.
%
% Original: Beth Hutchinson 1/22/08.8
% Modified: Samuel A. Hurley
% University of Wisconsin
% v3.0 24-Jan-2020
% v2.2 5-Nov-2009
%
% Changelog:
%          v2.1 - Added cd capability so that dirname input works
%          v2.2 - Added seqfil argument, so that spin-echo based DTI works as well (Nov-2009)
%          v2.3 - Fixed it so seqfil is now read directly from procpar. Input is info instead of dirname
%          v3.0 - Fixed sign of DRO vectors resulting in A/P orientation flip in
%                 fitted tensor output
%
%**************************************************************************

function load_binfo(info)

% If info is not specified, try to load the procpar from the current folder
if ~exist('info', 'var')
  info = load_procpar;
end

% Grab the sequence type from the header
seqfil = info.seqfil;

% Number of b-values
nbv = length(info.bvalue);
disp(['Number of B-Values: ' num2str(nbv)]);

% Grab b-values, throw out 1st scan (reference) if EPI
if strcmp(seqfil, 'epi_dti_2.2C')
  bvalue = info.bvalue(2:nbv)';
else
  bvalue = info.bvalue';
end

% grab b-vectors
% bvecs = [PE(dpe) Readout(dro) Slice(dsl)
if strcmp(seqfil, 'epi_dti_2.2C')
  bvecs = [info.dpe(2:nbv); -info.dro(2:nbv); info.dsl(2:nbv)];
else
  bvecs = [info.dpe(1:nbv); -info.dro(1:nbv); info.dsl(1:nbv)];
end

% write out text files for bvalues and bvectors
dlmwrite('bvecs', bvecs, 'delimiter', ' ');
dlmwrite('bvals', bvalue', 'delimiter', ' ');

