% FUNCTION load_sdir - Reads in data about a varian study, given the 
%                      path to an 's' directory (ex: s_20090622_01)
%
%
% Samuel A. Hurley
% University of Wisconsin
% v1.3 26-Mar-2010
%
% Changelog:
%         v1.1 Removed opts output - only outputs to the terminal  (Jun-09)
%              Added output to a text file _series.txt  If this file
%              Already exists, it reads this file instead of the slower
%              Operation of going into each diretory and parseing procpar
%         v1.2 Fixed exist() statements for r2009b (Feb-2010)
%         v1.3 Use try/catch/end for TE, in case SPULS is in list (no TE)   (Mar-2010)


function load_sdir(dirname)

if ~exist('dirname', 'var')
  dirname = '.';  % User current dir if none specified
end

% Check if _series.txt already exists.  If so, use that
if exist('_series.txt', 'file')
  % Load the file for reading
  txtfid = fopen('_series.txt', 'r');
  
  % For each line, display the information
  while 1
    txt = fgetl(txtfid);
    
    % If we hit the last line, end the loop
    if txt == -1
      break;
    end
    
    % Display the text
    disp(txt);

  end
  
  
else % ------ Otherwise, go into each dir and read procpar ----------
  

  % Get a list of directories ending in .fid (or .img, either will work)
  series = dir(fullfile(dirname, '*.fid'));

  series_name = cell(0);
  
  % If there are no series found
  if length(series) == 0 %#ok<ISMT>
    disp('WARNING: No Varian series found in this directory, running ls instead.');
    disp('----------------------------------------------------------------------');
    ls
    return;
  end
  
  for ii = 1:length(series)
    series_name{ii} = series(ii).name;
  end

  % Create an array of structs to hold info
  opts = struct();

  % Also create a text field to output formatted text data
  opts_txt =                   '|--------|-----------------|----------------|---------|---------|--------|';
  opts_txt = strvcat(opts_txt, '| Series | Sequence        | Comment        | TR      | TE      | Flip   |'); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, '|--------|-----------------|----------------|---------|---------|--------|'); %#ok<VCAT>

  % CD into each series and grab info from procpar
  fprintf('Reading series:');
  for ii = 1:length(series)
    progressbar(ii/length(series));
    
    % Load Procpar Info
    info = load_procpar(fullfile(dirname, series_name{ii}, 'procpar'));

    % Fill out opts structure
    %   opts(ii).series  = series_name{ii};
    %   opts(ii).seqfil  = info.seqfil;
    %   opts(ii).comment = info.comment;

    % Fill out opts text
    seqname = info.seqfil;
    if length(seqname) < 15
      % Pad with spaces for better alignment
      seqname = [seqname repmat(' ', [1 15-length(info.seqfil)])]; %#ok<AGROW>
    end
    
    comment = info.comment;
    if length(comment) < 14
      % Pad with spaces for better alignment
      comment = [comment repmat(' ', [1 14-length(info.comment)])]; %#ok<AGROW>
    end
    
    try
      
      if length(info.te) > 1
        testr = 'mtpl';
      else
        testr = num2str(info.te*1000, '% 4.0f');
      end
      
    catch
      testr = 'N/A ';
    end
    
    try
      flipstr = num2str(info.flip1);
    catch
      flipstr = 'N/A';
    end
    
    opts_txt = strvcat(opts_txt, ['| ' series_name{ii} ' | ' seqname ' | ' comment ' | ' num2str(info.tr*1000, '% 4.0f') ...
      ' ms | ' testr ' ms | ' flipstr ' dgr |']); %#ok<VCAT>
  end
  
  opts_txt = strvcat(opts_txt, '|--------|-----------------|----------------|---------|---------|--------|'); %#ok<VCAT>

  % Display opts text
  disp(opts_txt);

  % Write to a new text file
  txtfid = fopen('_series.txt', 'w');
  for ii = 1:size(opts_txt, 1);
    fprintf(txtfid, [opts_txt(ii,:) '\n']);
  end
  fclose(txtfid);

end

