function [XX,Header]= OpenDataQuattrocento(fname,path)
XX = [];
Header = [];

if nargin < 2
    path = [];
    if nargin < 1
        fname = [];
    end
end

if isempty(fname) || ~exist([path fname],'file') 
    [fname,path] = uigetfile('*','Choose Quattrocento File');
end

    head={'NumEMGChannel+NumAUXChannel' 'CallTimes'...
      'numCall' 'Fsample' 'bufferSample' 'bufferSize'...
      'IN1' 'IN2' 'IN3' 'IN4' 'IN5' 'IN6' 'IN7' 'IN8'...
      'MLT1' 'MLT2' 'MLT3' 'MLT4'};
    %function 
    try
      file=fopen([path,fname],'r');
      FileHeader=fread(file,18,'double');
      for i=1:18 
       Header{i,2}=FileHeader(i);
       Header{i,1}=head{i};
      end
      %FileHeader: (1)NumEMGChannel+obj.NumAUXChannel (2)CallTimes
      % (3)numCall (4)Fsample (5) bufferSample (6)bufferSize
      % (7:14)AS 0-1 Channel actived IN1 IN2 IN3 IN4 .... MLT1 MLT2...
      for j=1:FileHeader(2)
        XX((j-1)*FileHeader(4)*FileHeader(6)+1:j*FileHeader(4)*FileHeader(6),1:FileHeader(1))=...
            fread(file,[FileHeader(4)*FileHeader(6) FileHeader(1)],'double');
      end
      temp = fread(file,[FileHeader(3)*FileHeader(5), FileHeader(1)],'double');
      XX = [XX; temp];
      
      fclose(file);
    catch e
        getReport(e)
        fclose(file);
        return
    end
end