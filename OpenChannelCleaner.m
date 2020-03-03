function [HandSignalCleanCut,RemovedChannels] = OpenChannelCleaner(OpenChannelList,HandSignalCut)

Grid1 = OpenChannelList{1};
Grid2 = OpenChannelList{2};
Grid3 = OpenChannelList{3};


for L = 1:10  
       for trial = 1:3 
       Channels1 = Grid1{L,trial};
       Channels2 = Grid2{L,trial}+64;
       Channels3 = Grid3{L,trial}+128;
       OpenChannels = [Channels1 Channels2 Channels3];
       CurrentFile = HandSignalCut{L,trial};
            for i = OpenChannels 
                if i == 0
                else
                CurrentFile(:,i) = 0;
                end
            end
       HandSignalCleanCut{L,trial} = CurrentFile;
       RemovedChannels{L,trial} = OpenChannels;
       end
end

end