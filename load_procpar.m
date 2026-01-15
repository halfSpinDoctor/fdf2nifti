% FUNCTION info = load_procpar(fname)
%
% Function to load procpar settings from a Varian scanner into a matlab struct
%
% Inputs:
%   fname = the file name of the procpar file
%
% Outputs:
%   info  = a Matlab structure containg the pulse sequence options
%           outputs consist of strings or arrays of doubles
%
% Samuel A. Hurley
% University of Wisconsin
% v1.2 31-Oct-2012
%
% Changelog:
% v1.1 - Changed str2double to sscanf to save time
%        Disabled check on 84 (correct # of array elem)
%        Modified strsplit to always return cell array (Jun-2009)
% v1.2 - Added fix to rename com$string so that the field will not throw an
%        error (Oct-2012)

function info = load_procpar(fname)

% I. Check if path was specified
if ~exist('fname', 'var')                    
  fname = 'procpar';
end

% II. Create output structure
info = struct();

% Load in procpar as a text file
fid = fopen(fname, 'r');  % For READ

% Readout each line in the txt file
while 1
  % Get the next line
  currLine = fgetl(fid);
  
  % If we reached the end, exit
  if isempty(currLine)
    break;
  end
  
 if currLine == -1
   break;
 end
  
  % Split line by spaces
  currLine = strsplit(currLine, ' ');
  
  % There should be 11 parts, or this is not a valid parameter line
  if length(currLine) ~= 11
    error('Invalid parameter line.  Procpar may be corrupt or invalid');
  end
  
  % Grab parameter name
  field = currLine{1};
  
  % Grab parameter values
  currLine = fgetl(fid);
   
  % Error check
  if isempty(currLine)
    error('File ended unexpectedly.  Procpar may be corrupt or invalid');
  end

  splitLine = strsplit(currLine, ' ');
  
  % Must be at least two fields
  if length(splitLine) < 2
    error('Data line does not contain enough values.  Procpar may be corrupt or invalid');
  end
  
  % Check if we are dealing with a string field
  split = splitLine{2};
  if strcmp(split(1), '"')
    % Get ths string data from the first line
    strLine = strsplit(currLine, '"');
    value = strLine{2};
    
    % Determine the number of strings to read out
    nString = sscanf(splitLine{1}, '%f');
    
    for ii = 2:nString
      currLine = fgetl(fid);
      strLine = strsplit(currLine, '"');
      value = strvcat(value, strLine{2});      %#ok<VCAT>
    end
    
  else
    % Otherwise, this is just numerical data
    
    % Remove empty cells
    splitLine(cellfun(@isempty, splitLine)) = [];
    
    % DISABLED - TIME HIT
    % Check for correct number of elements
    % if str2num(splitLine{1}) ~= (length(splitLine) - 1)
    %   error('Line contains incorrect number of values.  Invalid or corrupt procpar file');
    % end
    
    % Preallocate values
    value = zeros([1 length(splitLine)-1]);
    
    for ii = 2:length(splitLine)
      % Exclude first value
      value(ii-1) = sscanf(splitLine{ii}, '%f');
    end
    
  end % /* End str vs number */
  
  % Create a new field and put in the value
  
  % Fix for field with $ in it in new versions of VnmrJ SAH v1.2
  if strcmp(field, 'com$string')
    field = 'com_string';
  end
  
  try
    info.(field) = value;
  catch
    disp(['Error reading field ' field]);
  end
    
  % Read out last line, no useful info there (just options for a drop-down menu)
  currLine = fgetl(fid);
  
  if isempty(currLine)
    break;
  end
  
end

% Close the procpar file
fclose(fid);



% /********* Helper Functions Below **************/
function splittedstring = strsplit(inpstr,delimiter)
% FUNCTION strsplit
%
%-USE:
%
% This function should be used to split a string of delimiter separated
% values.  If all values are numerical values the returned matrix is a
% double array but if there is one non numerical value a cell array is
% returned.  You can check this with the iscell() function.
%
%-SYNTAX
% output = strsplit(inpstr[,delimiter])
% 
% inpstr:    string containing delimiter separatede numerical values, eg
%            3498,48869,23908,34.67
% delimiter: optional, if omitted the delimiter is , (comma)
%
%-OUTPUT
%
% An x by 1 matrix containing the splitted values
%
%-INFO
%
% mailto:    gie.spaepen@ua.ac.be
%
%--------------------------------------------------------------------------


%Check input arguments
if(nargin < 1)
  error('There is no argument defined');
else
  if(nargin == 1)
    strdelim = ',';
    %Verbose off!! disp 'Delimiter set to ,';
  else
    strdelim = delimiter;
  end
end

%deblank string
deblank(inpstr);

%Get number of substrings
idx  = findstr(inpstr,strdelim);

%Define size of the indices
sz = size(idx,2);

% Preallocate cell array //SAH 1.1
tempsplit = cell([1 sz+1]);
%Loop through string and itinerate from delimiter to delimiter
for i = 1:sz
  %Define standard start and stop positions for the start position,
  %choose 1 as startup position because otherwise you get an array
  %overflow, for the endposition you can detemine it from the
  %delimiter position

  %If i is not the beginning of the string get it from the delimiter
  %position
  
  if i == 1
    strtpos = 1;
  else
    strtpos = idx(i-1)+1;
  end
  
  endpos = idx(i)-1;
  
  %If i is equal to the number of delimiters get the last element
  %first by determining the lengt of the string and then replace the
  %endpos back to a standard position
  if i == sz
    endpos = size(inpstr,2);
    tempsplit(i+1) = {inpstr(idx(i)+1 : endpos)};
    endpos = idx(i)-1;
  end
  %Add substring to output: splittedstring a cell array
  tempsplit(i) = {inpstr(strtpos : endpos)};
end

splittedstring = tempsplit;