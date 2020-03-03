function [dataset]=datasetbuild(winsize,wininc,dataamount,openchannel)
% Building dataset for training and testing
% winsize = windowing size to be processed
% wininc = windowing size to be truncated
% dataamount = total data to be included
pardir = uigetdir(pwd, 'Select Dataset Folder');
PinOut = [0 1 2 3 4 5 6 7 8 9 10 11 12;...
    25 24 23 22 21 20 19 18 17 16 15 14 13;...
    26 27 28 29 30 31 32 33 34 35 36 37 38;...
    51 50 49 48 47 46 45 44 43 42 41 40 39;...
    52 53 54 55 56 57 58 59 60 61 62 63 64];

for i=1:dataamount
    Letter = LetterSelect(i);
    
    for trial =1:3
        %[EMGsignal,~]= OpenDataQuattrocento();
        %[filteredemg]=EMGFilter(EMGsignal);
        %Fname = sprintf('EMG_%s%d',Letter,trial);
        Grid1=openchannel{1,1}{i,trial};
        Grid2=openchannel{1,2}{i,trial};
        Grid3=openchannel{1,3}{i,trial};
        Grid4=openchannel{1,4}{i,trial};
        Grid5=openchannel{1,5}{i,trial};
        
        emgdir = [pardir '\' Letter '\'];   
        emgfiles = dir(fullfile(emgdir,[Letter num2str(trial)]));
        [EMGsignal,~] = OpenDataQuattrocento(emgfiles.name,emgdir);
        [filteredemg,grid]=EMGFilter(EMGsignal,Grid1,Grid2,Grid3,Grid4,Grid5);
        
        
        kindir=[pardir '\' Letter '\'];
        kinfiles = dir(fullfile(kindir,['Angles_' Letter num2str(trial) '.emt']));
        kintrigfiles = dir(fullfile(kindir,['EMG_' Letter num2str(trial) '.emt']));
        [readkin]=emtfileread(kindir,kinfiles.name);
        [readtrig]=emtfileread(kindir,kintrigfiles.name);
        [smoothedkin]=kinsmooth(readkin,readtrig,'gaussian');
    
        Difference = abs(length(filteredemg) - length(smoothedkin));

        if mod(Difference,2) ~= 0
            Difference = Difference + 1; 
            filteredemg = filteredemg(1:end-1,:);
        end

        matchedkinematic = smoothedkin(1+Difference/2:end-Difference/2,:);
        
        bihori=[];
        biveri=[];
        a=0;
        for j=1:4
            tempemg=filteredemg(:,64*j-63:64*j);
            for e=1:4
                for k=1:13
                    a=a+1;
                    
                    if PinOut(e,k)~=0
                        bihori(:,a)=tempemg(:,PinOut(e,k))-tempemg(:,PinOut(e+1,k));
                    end
                    
                end
            end
        end
        bihori( :,all(~bihori,1) ) = [];
        
        a=0;
        
            tempemg=filteredemg(:,64*5-63:64*5);
            for e=1:5
                for k=1:12
                    a=a+1;
                    
                    if PinOut(e,k)~=0
                        biveri(:,a)=tempemg(:,PinOut(e,k))-tempemg(:,PinOut(e,k+1));
                    end
                    
                end
            end
        
        biveri( :,all(~biveri,1) ) = [];
        
        bipolar=[bihori biveri filteredemg(:,end)];
        
        [rms,wl]=TemporalFreqFeature(filteredemg,winsize,wininc);
        [rmsbi,wlbi]=TemporalFreqFeature(bipolar,winsize,wininc);
        reducedrms1=[];
        reducedrms7=[];
        reducedrms14=[];
        reducedrms1bi=[];
        reducedrms7bi=[];
        reducedrms14bi=[];
        
        for j=1:5
            coeffrms{j}=pca(rms(:,64*j-63:64*j));
            reducedrms1(:,j)=rms(:,64*j-63:64*j)*coeffrms{j}(:,1);
            reducedrms7(:,7*j-6:7*j)=rms(:,64*j-63:64*j)*coeffrms{j}(:,1:7);
            reducedrms14(:,14*j-13:14*j)=rms(:,64*j-63:64*j)*coeffrms{j}(:,1:14);
            coeffwl{j}=pca(wl(:,64*j-63:64*j));
        end
        for j=1:4
            coeffrmsbi{j}=pca(rmsbi(:,51*j-50:51*j));
            reducedrms1bi(:,j)=rmsbi(:,51*j-50:51*j)*coeffrmsbi{j}(:,1);
            reducedrms7bi(:,7*j-6:7*j)=rmsbi(:,51*j-50:51*j)*coeffrmsbi{j}(:,1:7);
            reducedrms14bi(:,14*j-13:14*j)=rmsbi(:,51*j-50:51*j)*coeffrmsbi{j}(:,1:14);
        end
        coeffrmsbi{5}=pca(rmsbi(:,51*4+1:end));
        reducedrms1bi(:,5)=rmsbi(:,51*5-50:end)*coeffrmsbi{5}(:,1);
        reducedrms7bi(:,7*5-6:7*5)=rmsbi(:,51*5-50:end)*coeffrmsbi{5}(:,1:7);
        reducedrms14bi(:,14*5-13:14*5)=rmsbi(:,51*5-50:end)*coeffrmsbi{5}(:,1:14);
        
        coeffoutput=pca(matchedkinematic(1:wininc:end,3:13));
        reducedoutput=matchedkinematic(1:wininc:end,3:13)*coeffoutput(:,1:5);
        dataset(i,trial).reducedoutput=reducedoutput;
        
        dataset(i,trial).reducedrms1=reducedrms1bi;
        dataset(i,trial).reducedrms7=reducedrms7bi;
        dataset(i,trial).reducedrms14=reducedrms14bi;
        dataset(i,trial).rms=rmsbi;
        
        dataset(i,trial).wl=wl;
        dataset(i,trial).rawinput=filteredemg;
        
        dataset(i,trial).angle=matchedkinematic(1:wininc:end,:);
        dataset(i,trial).output(:,1:2)=matchedkinematic(1:wininc:end,1:2);
        dataset(i,trial).output(:,3:13)=matchedkinematic(1:wininc:end,3:13);
        dataset(i,trial).rawoutput=matchedkinematic;
        
        dataset(i,trial).extrinsic=rmsbi(:,1:102);
        dataset(i,trial).intrinsic=rmsbi(:,103:end);
        rms14=[];
        rms7=[];
        for k=1:4
            rms14(:,13*k-12:13*k)=rmsbi(:,PinOut(4,1:end)+51*k-51);
            rms7(:,7*k-6:7*k)=rmsbi(:,PinOut(4,1:2:end)+51*k-51);
        end
        
        rms14=[rms14 rmsbi(:,PinOut(1:end,7)+51*5-51)];
        rms7=[rms7 rmsbi(:,PinOut(1:2:end,7)+51*5-51)];
        
        dataset(i,trial).rms14=rms14;
        dataset(i,trial).rms7=rms7;
    end
end