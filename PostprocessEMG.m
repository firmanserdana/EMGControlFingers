%% EMG postprocessing

clear all

[b,a] = butter(4,[50 400]/1024); %4th order butterworth filter between 20 Hz and 400 Hz

% Loading EMG trials on a cell



for L = 1:10   
   Letter = LetterSelect(L);
    for trial = 1:3   
        Fname = sprintf('EMG_%s%d',Letter,trial);
        Dir = sprintf('E:\\MSc Project\\Karan31-07\\EMG\\%s\\',Letter);   
        EMG_Files{L,trial} = OpenDataQuattrocento(Fname,Dir);  
    end   
end

% Discarding forearm channels 

for L = 1:10 
      for trial = 1:3
       CurrentFile = EMG_Files{L,trial};
       HandSignal{L,trial} = CurrentFile(:,129:256);
       Trigger{L,trial} = CurrentFile(:,257);       
      end
end


% Removing signal outside trigger time + Bandpass filtering  + obtaining signal envelope +
% downsampling


for L = 1:10 
       for trial = 1:3  
           TriggerSig = Trigger{L,trial};
                for i=1:length(TriggerSig)/2  
                     if TriggerSig(i) > 1
                        Startsample = i ;
                        break;
                     end  
                end
                
                for i=length(TriggerSig)/2:length(TriggerSig)
                     if TriggerSig(i) < 1
                         Endsample = i ;
                         break
                     end  
                end
            EMGsignal = HandSignal{L,trial};
            EMGsignalCut = EMGsignal(Startsample:Endsample,:); %Cutting
            EMGsignalCut =filtfilt(b, a, EMGsignalCut);        %Filtering
            [EMGsignalCutEnv,~] = envelope(abs( EMGsignalCut));%Envelope 
            EMGsignalCutEnv = downsample(EMGsignalCutEnv,64);  %Downsampling
            HandSignalCut{L,trial} = EMGsignalCutEnv;
       end    
end

 



% Removing open channels 

for L = 1:10 
       for trial = 1:3 
       CurrentFile = HandSignalCut{L,trial};
       OpenChannels = sort(find(sum(abs(CurrentFile) > 2)),'descend');
            for i = OpenChannels 
                CurrentFile(:,i) = 0;
            end
       HandSignalCleanCut{L,trial} = CurrentFile;
       RemovedChannels{L,trial} = OpenChannels;
       end
end


% Merging all data into one matrix

MergedData = [];


for L = 1:10 
       for trial = 1:3            
           if length(RemovedChannels{L,trial}) > 20
               break        
           else                   
           MergedData = [MergedData;HandSignalCleanCut{L,trial}];           
           end
       end
end


%FFT 

Fs = 2048;                               % Sampling frequency                    
T = 1/Fs;                                % Sampling period       
L = length(HandSignal{1,2});             % Length of signal
t = (0:L-1)*T;                           % Time vector

Signal = HandSignal{1,2};

Channel = Signal(:,1);

Channel =filtfilt(b, a, Channel);        %Filtering


Y = fft(Channel);

P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;

figure(1)
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

figure(2)

plot(Channel)

       
% Open channel list
 
%KARAN OPEN CHANNELS
MergedData(:,58) = 0;
MergedData(:,54) = 0;
MergedData(:,53) = 0;
MergedData(:,52) = 0;
MergedData(:,51) = 0;
MergedData(:,47) = 0;
MergedData(:,46) = 0;
MergedData(:,26) = 0;

%FIRMAN OPEN CHANNELS
% MergedData(:,45) = 0;

%% Synergy analysis


%PCA
[coeffMS,scoreMS,latentMS,tsquaredMS,explainedMS,muMS] = pca(MergedData);

%Number of synergies
Nsyn = 2;

for iter = 1:10
    
%NNMF
[W,H] = nnmf(MergedData(:,1:64),2);

%NNMF Variance
Variance(iter,:) = NNMFVariance(W,H,MergedData(:,1:64));

HStored{iter}= H;

end

MeanVar = mean(Variance);

%Choosing NNMF iteration that explains the highest variance of the data
[Best,pos] = max(Variance(:,Nsyn));
H = HStored{pos};


%Normalizing data
NormSynergies = normalize(H','range');


%NNMF HEATMAPS
 
[Heatmap]  = SquareGridHeatmap(NormSynergies(1:64,1));
[Heatmap2] = SquareGridHeatmap(NormSynergies(1:64,2));
[Heatmap3] = SquareGridHeatmap(NormSynergies(1:64,3));
[Heatmap4] = SquareGridHeatmap(NormSynergies(1:64,4));
[Heatmap5] = SquareGridHeatmap(NormSynergies(1:64,5));
% 
% 
[Heatmap6]  =  EMGHeatmaps(NormSynergies(65:128,1));
[Heatmap7]  =  EMGHeatmaps(NormSynergies(65:128,2));
[Heatmap8]  =  EMGHeatmaps(NormSynergies(65:128,3));
[Heatmap9]  =  EMGHeatmaps(NormSynergies(65:128,4));
[Heatmap10] =  EMGHeatmaps(NormSynergies(65:128,5));


 
%PCA HEATMAPS
% 
% [Heatmap] =  SquareGridHeatmap(normalize(abs(coeffMS(1:64,1)),'range'));
% [Heatmap2] = SquareGridHeatmap(normalize(abs(coeffMS(1:64,2)),'range'));
% [Heatmap3] = SquareGridHeatmap(normalize(abs(coeffMS(1:64,3)),'range'));
% [Heatmap4] = SquareGridHeatmap(normalize(abs(coeffMS(1:64,4)),'range'));
% [Heatmap5] = SquareGridHeatmap(normalize(abs(coeffMS(1:64,5)),'range'));
% 
% 
% [Heatmap6] =  EMGHeatmaps(normalize(abs(coeffMS(65:128,1)),'range'));
% [Heatmap7] = EMGHeatmaps(normalize(abs(coeffMS(65:128,2)),'range'));
% [Heatmap8] = EMGHeatmaps(normalize(abs(coeffMS(65:128,3)),'range'));
% [Heatmap9] = EMGHeatmaps(normalize(abs(coeffMS(65:128,4)),'range'));
% [Heatmap10] = EMGHeatmaps(normalize(abs(coeffMS(65:128,5)),'range'));


%Plotting heatmaps

cmin = 0;
cmax = 1;

figure(1)
imagesc(Heatmap,[cmin cmax])
title('Synergy1 Palm')
colorbar

figure(2)
imagesc(Heatmap2,[cmin cmax])
title('Synergy2 Palm')
colorbar
% 
% figure(3)
% imagesc(Heatmap3,[cmin cmax])
% title('Synergy3 Palm')
% colorbar
% 
% figure(4)
% imagesc(Heatmap4,[cmin cmax])
% title('Synergy4 Palm')
% colorbar
% 
% figure(5)
% imagesc(Heatmap5,[cmin cmax])
% title('Synergy5 Palm')
% colorbar
% 
% 
% 
% figure(6)
% imagesc(Heatmap6,[cmin cmax])
% title('Synergy1 Thumb')
% colorbar
% 
% figure(7)
% imagesc(Heatmap7,[cmin cmax])
% title('Synergy2 Thumb')
% colorbar
% 
% figure(8)
% imagesc(Heatmap8,[cmin cmax])
% title('Synergy3 Thumb')
% colorbar
% 
% figure(9)
% imagesc(Heatmap9,[cmin cmax])
% title('Synergy4 Thumb')
% colorbar
% 
% figure(10)
% imagesc(Heatmap10,[cmin cmax])
% title('Synergy5 Thumb')
% colorbar
















%We are doing force against the bandages

%FIRMAN:

%First synergy variance = 0.4384
%First and second synergy variance = 0.592
%First,second and third synergy variance = 0.7331
%First,second,third and fourth synergy variance = 0.8425
%First,second,third,fourth and fifth synergy variance = 0.9154


%KARAN:

%First synergy variance = 0.9257
%First and second synergy variance = 0.9629
%First,second and third synergy variance = 0.9755
%First,second,third and fourth synergy variance = 0.9826
%First,second,third,fourth and fifth synergy variance = 0.9919

