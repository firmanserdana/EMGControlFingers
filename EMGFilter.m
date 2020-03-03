function [filtered,grid]=EMGFilter(EMGsignal, grid1,grid2,grid3,grid4,grid5)
%Filtering EMG data

%% Get only data from triggered movements
EMGTrigger=EMGsignal(:,end-15);
EMG=EMGsignal(:,1:end-16);
idx=EMGTrigger>1;
EMGData=EMG(idx,:);

%% Apply bandpass filter, 20 low cut off for motion artifacts

[B,A]= butter(4, [20 400]/2048);
filtered(:,:)=filter(B,A,EMGData);
filtered(:,end+1)=EMGTrigger(idx);

if grid1==0
    grid1=[];
end
if grid2==0
    grid2=[];
end
if grid3==0
    grid3=[];
end
if grid4==0
    grid4=[];
end
if grid5==0
    grid5=[];
end

grid{1}=grid1;
grid{2}=grid2;
grid{3}=grid3;
grid{4}=grid4;
grid{5}=grid5;

%% Remove openchannel by atenuating
if isempty(grid1)==0
    for i=1:length(grid1)
        filtered(:,grid1(i)+64+64)=filtered(:,grid1(i)+64+64)/100000;
    end
end
if isempty(grid2)==0
    for i=1:length(grid2)
        filtered(:,grid2(i)+64+64+64)=filtered(:,grid2(i)+64+64+64)/100000;
    end
end
if isempty(grid3)==0
    for i=1:length(grid3)
        filtered(:,grid3(i)+64+64+64+64)=filtered(:,grid3(i)+64+64+64+64)/100000;
    end
end
if isempty(grid4)==0
    for i=1:length(grid4)
        filtered(:,grid4(i))=filtered(:,grid4(i))/100000;
    end
end
if isempty(grid5)==0
    for i=1:length(grid5)
        filtered(:,grid5(i)+64)=filtered(:,grid5(i)+64)/100000;
    end
end

[B,A]= butter(2, 16/2048,'low');
filtered(:,1:end-1)=filter(B,A,filtered(:,1:end-1));

