function [img M] = load_fdf(fname, zdim)
% m-file that can open Varian FDF imaging files in Matlab.
% Usage: img = fdf;
% Your image data will be loaded into img
%
% Shanrong Zhang
% Department of Radiology
% University of Washington
% 
% email: zhangs@u.washington.edu
% Date: 12/19/2004
% 
% Fix Issue so it is able to open both old Unix-based and new Linux-based FDF
% Date: 11/22/2007
%

warning off MATLAB:divideByZero;

[fid] = fopen(fname,'r');

num = 0;
done = false;
machineformat = 'ieee-be'; % Old Unix-based  
line = fgetl(fid);
while (~isempty(line) && ~done)
    line = fgetl(fid);
    % disp(line)
    if strmatch('int    bigendian', line)
        machineformat = 'ieee-le'; % New Linux-based    
    end
    
    if strmatch('float  matrix[] = ', line)
        [token, rem] = strtok(line,'float  matrix[] = { , };');
        M(1) = str2double(token);
        M(2) = str2double(strtok(rem,', };'));
    end
    if strmatch('float  bits = ', line)
        token = strtok(line,'float  bits = { , };');
        bits = str2double(token);
    end

    num = num + 1;
    
    if num > 41
        done = true;
    end
end

skip = fseek(fid, -M(1)*M(2)*zdim*bits/8, 'eof');

% Preallocate
img = zeros([M(1) M(2) zdim]);

for ii = 1:zdim
  img(:,:,ii) = fread(fid, [M(2), M(1)], 'float32', machineformat)';
end
fclose(fid);

% end of m-code
