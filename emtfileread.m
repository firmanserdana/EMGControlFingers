function [readed]=emtfileread(path,fname)
% For easier data import of emt files from BTS SmartAnalyzer app, *file*
% only specify uigetfile window name

%% Getting file location, *WARNING* choose correct file.
%[fname,path] = uigetfile('.emt',file);
fid = fopen([path,fname],'rt');
nlines = 0;
while (fgets(fid) ~= -1)
  nlines = nlines+1;
end
fclose(fid);

%% Converting to matlab workspace
text = textread([path,fname],'%s',nlines,'delimiter','\n', 'headerlines',12-1);
readed=[];
for i=1:length(text)-2
    readed(i,:)=str2num(text{i,1});
end
