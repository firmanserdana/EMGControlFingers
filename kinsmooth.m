function [smoothed,kinresample]=kinsmooth(kinematic_data,trigger,smoothtype)
% Function for postprocessing the kinematic data (smoothing, interpolating
% and upsampling)
% Args
% kinematic_data = kinematic data (angles)
% trigger = Triggering signal for synchronization
% smoothtype = smoothing method

[B,A]=butter(1,10/250,'low');

%% Getting start and end time
i = 1;

% while trigger(i,3) < 4    
%     i = i + 1; 
% end

Starttime = trigger(50,2);


% while trigger(i,3) > 1    
%     i = i + 1;    
% end

Endtime = trigger(end-50,2);

%% Truncating Kinematic data according to start and end time
i = 1;

while kinematic_data(i,2) < Starttime    
    i = i + 1;    
end

StartKin = kinematic_data(i,1);

while kinematic_data(i,2) < Endtime    
    i = i + 1;    
end

EndKin = kinematic_data(i,1);
%kinematic_data(:,3:end)=filter(B,A,kinematic_data(:,3:end));
kinematictrunc = kinematic_data(StartKin:EndKin,:);

time=kinematictrunc(:,1:2);
kindata=kinematictrunc(:,3:end);

%% Smoothing the kinematic data, using 'gaussian' method by default, look at *help smoothdata* for other method
if nargin <3
    smoothtype='gaussian';
end

%kindata=smoothdata(kindata,smoothtype);

% Resampling data
kinresample=resample(kindata,2048,250);
timeresample(:,1)=0:size(kinresample,1)-1;
timeresample(:,2)=0:(time(end,2)/size(kinresample,1)):time(end,2)-(time(end,2)/size(kinresample,1));


smoothed=zeros(size(kinresample,1),size(kinematic_data,2));
smoothed(:,1:2)=timeresample;
%% Interpolating missing data and upsampling kinematic data according to EMG recording
% Interpolating with 'pchip' argument, choose other if desired, look at
% *help fillmissing*

nanfirst=isnan(kinresample(1,:));
nanend=isnan(kinresample(end,:));
kinresample(1,nanfirst)=kinresample(find(~isnan(kinresample(:,nanfirst)), 1),nanfirst);
kinresample(end,nanend)=kinresample(find(~isnan(kinresample(:,nanend)), 1,'last'),nanend);
smoothed(:,3:end)=fillmissing(kinresample,'pchip');
smoothed(:,3:end)=smoothdata(smoothed(:,3:end),smoothtype);