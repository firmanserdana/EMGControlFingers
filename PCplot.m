for L=1:11
    Letter = LetterSelect(L);
    for trial =1:3
        kindir=sprintf('C:\\Users\\Admin\\OneDrive - Imperial College London\\Project\\mock\\savedData\\Jumpei23-08Dataset\\%s\\',Letter);
        kinfiles = dir(fullfile(kindir,'Angle*'));
        kintrigfiles = dir(fullfile(kindir,'EMG*'));
        [readkin]=emtfileread(kindir,kinfiles(trial).name);
        [readtrig]=emtfileread(kindir,kintrigfiles(trial).name);
        [smoothedkin]=kinsmooth(readkin,readtrig,'gaussian');
        Kindata{L,trial} = smoothedkin(:,3:13);
        KinMean{L,trial} = mean(smoothedkin(:,3:13));
    end 
end

KinAverage = [];


for L = 1:10 
       for trial = 1:3                             
           KinAverage = [KinAverage;KinMean{L,trial}];
       end
end


[coeffKSM,scoreKSM,latentKSM,tsquaredKSM,explainedKSM,muKSM] = pca(KinAverage);

figure
plot(explainedKSM)

figure(10)

scatter(scoreKSM(1:3,1),scoreKSM(1:3,2),'r','filled')
hold on
scatter(scoreKSM(4:6,1),scoreKSM(4:6,2),'y','filled')
hold on
scatter(scoreKSM(7:9,1),scoreKSM(7:9,2),'m','filled')
hold on
scatter(scoreKSM(10:12,1),scoreKSM(10:12,2),'c','filled')
hold on
scatter(scoreKSM(13:15,1),scoreKSM(13:15,2),'g','filled')
hold on
scatter(scoreKSM(16:18,1),scoreKSM(16:18,2),'b','filled')
hold on
scatter(scoreKSM(19:21,1),scoreKSM(19:21,2),'k','filled')
hold on
scatter(scoreKSM(22:24,1),scoreKSM(22:24,2),30,[0.8500, 0.3250, 0.0980],'filled')
hold on
scatter(scoreKSM(25:27,1),scoreKSM(25:27,2),30,[0.4940, 0.1840, 0.5560],'filled')
hold on
scatter(scoreKSM(28:30,1),scoreKSM(28:30,2),30,[0.6350, 0.0780, 0.1840],'filled')

legend('A','B','C','D','F','I','K','L','O','W')

xlabel('PC1')
ylabel('PC2')
