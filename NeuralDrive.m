function [neudrive]=NeuralDrive(EMGsignal)
EMGTrigger=EMGsignal(:,end);
EMG=EMGsignal(:,1:end-1);
EMGData=EMG;


