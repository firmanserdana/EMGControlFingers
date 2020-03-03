function [spatial]=SpatialFeature(EMGsignal)
EMGTrigger=EMGsignal(:,257);
EMG=EMGsignal(:,1:256);
idx=EMGTrigger>3;
EMGData=EMG(idx,1:256);