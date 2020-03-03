function [rms,wl]=TemporalFreqFeature(EMGsignal,winsize,wininc)
%Temporal frequency feature extractions,
% Output arg
% rms = root mean square
% wl = waveform length

% Input arg
% EMGsignal = EMG data
% winsize = windowing size to be processed
% wininc = windowing size to be truncated

EMGTrigger=EMGsignal(:,end);
EMG=EMGsignal(:,1:end-1);
%idx=EMGTrigger>1;
EMGData=EMG;

%% Data Windowing
datasize = size(EMGData,1);
Nsignals = size(EMGData,2);
numwin = floor((datasize - winsize)/wininc)+1;
datawin=ones(winsize,1);

%% RMS Feature Extract

rms = zeros(numwin,Nsignals);

st = 1;
en = winsize;

for i = 1:numwin   
   curwin = EMGData(st:en,:).*repmat(datawin,1,Nsignals);
   rms(i,:) = sqrt(mean(curwin.^2));
   
   st = st + wininc;
   en = en + wininc;
end

%% WL Feature Extract

wl = zeros(numwin,Nsignals);

st = 1;
en = winsize;

for i = 1:numwin
   
   curwin = EMGData(st:en,:).*repmat(datawin,1,Nsignals);
   wl(i,:) = sum(abs(diff(curwin,2)));
   
   st = st + wininc;
   en = en + wininc;
end

