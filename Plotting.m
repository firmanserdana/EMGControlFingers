clc
clear
close all
%% Loading data into workspace
load('OpenChannelsFirman.mat');
load('OpenChannelsKaran.mat');
load('OpenChannelsSimone.mat');
load('OpenChannelsJumpei.mat');
[dataset1]=datasetbuild(30,30,10,OpenChannelsSimone);
[dataset2]=datasetbuild(30,30,10,OpenChannelsKaran);
[dataset3]=datasetbuild(30,30,10,OpenChannelsFirman);
[dataset4]=datasetbuild(30,30,10,OpenChannelsJumpei);
alldata=[dataset1 dataset2 dataset3 dataset4];
%% Plotting dataset
subplot(6,1,1);
plot(dataset3(3,2).rawinput(:,1:end-16));
title('Raw, RMS, and Kinematic Output Comparison');
ylabel('raw')
subplot(6,1,2);
plot(dataset3(3,2).rms);
ylabel('rms')
subplot(6,1,3);
plot(dataset3(3,2).reducedrms1);
ylabel('pca1')
subplot(6,1,4);
plot(dataset3(3,2).reducedrms7);
ylabel('pca7')
subplot(6,1,5);
plot(dataset3(3,2).reducedrms14);
ylabel('pca14')
subplot(6,1,6);
plot(dataset3(3,2).output(:,3:end));
ylabel('angles')

%% Plotting Neural Network Train Results
for Angles=3:13
    for Testing=1:10
    [net,rep2,shuffleddata]=NeuralNetTrain(Testing,Angles,300,dataset4,'intrinsic');
    outpred=predict(net,shuffleddata(Testing,end).intrinsic');
    outpredi=smoothdata(outpred','gaussian');
    [B,L]=butter(2,0.03,'low');
    outpredic=filter(B,L,outpredi);
    outpredic(1:30)=outpredic(30);
    maxlength=min([length(outpredic) length(shuffleddata(Testing,end).output)]);
    RMSE(Angles-2, Testing) = sqrt(mean((shuffleddata(Testing,end).output(1:maxlength,Angles)-outpredic(1:maxlength)).^2));
    SSE(Angles-2, Testing) = sum((sort(shuffleddata(Testing,end).output(1:maxlength,Angles))-sort(outpredic(1:maxlength))).^2);
    SSR(Angles-2, Testing) = sum((outpredic(1:maxlength)).^2);
    SST(Angles-2, Testing) = sum(((mean(shuffleddata(Testing,end).output(1:maxlength,Angles)))-sort(outpredic(1:maxlength))).^2);
    [R_square1(Angles-2,Testing), R_square2(Angles-2,Testing), R_square3(Angles-2,Testing), R_square4(Angles-2,Testing), Diff] = determ_coef(shuffleddata(Testing,end).output(1:maxlength,Angles),outpredic(1:maxlength));
    Rsquare(Angles-2,Testing) = 1-(SSE(Angles-2, Testing)/SST(Angles-2, Testing));
%     figure(Testing+1)
%     subplot(4,3,Angles-2)
%     plot(outpredic,'LineWidth',2);
%     hold on
%     plot(shuffleddata(Testing,end).output(:,Angles),':','LineWidth',2);
%     set(gca,'xtick',[]);
%     if Angles-2<11
%         axis([-inf inf -inf inf]);
%     else
%         axis([-inf inf -inf inf]);
%     end
%     L=LetterSelect(Testing);
%     A=AngleSelect(Angles-2);
%     if Angles-2==3
%         legend('filtered prediction','target');
%     end
%     if Angles-2==2
%         title(['Angles Prediction Against Targets for Alphabets ' L]);
%     end
%     xlabel(A);
%     if Angles-2==4
%         ylabel('Angles (Degrees)');
%     end
     end
end
RMSE(1,:)=RMSE(1,:)/90;
RMSE(4,:)=RMSE(4,:)/90;
RMSE(6,:)=RMSE(6,:)/90;
RMSE(7,:)=RMSE(7,:)/90;
RMSE(9,:)=RMSE(9,:)/90;
RMSE(2:3,:)=RMSE(2:3,:)/101;
RMSE(5,:)=RMSE(5,:)/101;
RMSE(8,:)=RMSE(8,:)/101;
RMSE(10,:)=RMSE(10,:)/101;

RMSE(11,:)=RMSE(11,:)/90;
error=(mean(RMSE'))';
%sdvrmse=std(std(RMSE));
r2=(mean(sqrt(R_square1')))';
%sdvr2=std(std(Rsquare));
% figure
% bar(RMSE')
% ylabel('RMSE (normalized)')
% xlabel('Alphabets')
% xticklabels({'A', 'B', 'C', 'D', 'F', 'I', 'K', 'L', 'O', 'W'})
% legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('RMSE level for each Angle and Alphabet with Neural Network')
% disp(['Average normalized RMSE ' num2str(error) '+' num2str(sdvrmse)])
% 
% figure
% bar(R_square1')
% ylabel('Rsquare*100%')
% xlabel('Alphabets')
% xticklabels({'A', 'B', 'C', 'D', 'F', 'I', 'K', 'L', 'O', 'W'})
% legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('R^2 for each Angle and Alphabet with Neural Network')
% 
% figure
% bar(mean(RMSE))
% hold on
% errorbar(mean(RMSE),std(RMSE),'.')
% axis([-inf inf 0 inf])
% ylabel('RMSE (normalized)')
% xlabel('Alphabets')
% xticklabels({'A', 'B', 'C', 'D', 'F', 'I', 'K', 'L', 'O', 'W'})
% %legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('RMSE level for each Alphabet with Neural Network')
% disp(['Average normalized RMSE ' num2str(error) '+' num2str(sdvrmse)])
% 
% figure
% bar(mean(RMSE'))
% hold on
% errorbar(mean(RMSE'),std(RMSE'),'.')
% axis([-inf inf 0 inf])
% ylabel('RMSE (normalized)')
% xlabel('Angles')
% xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
% %legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('RMSE level for each Angles with Neural Network')
% disp(['Average normalized RMSE ' num2str(error) '+' num2str(sdvrmse)])
% 
% figure
% bar(mean(R_square1))
% hold on
% errorbar(mean(R_square1),std(R_square1),'.')
% ylabel('Rsquare*100%')
% xlabel('Alphabets')
% xticklabels({'A', 'B', 'C', 'D', 'F', 'I', 'K', 'L', 'O', 'W'})
% %legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('R^2 for each Alphabet with Neural Network')
% 
% figure
% bar(mean(R_square1'))
% hold on
% errorbar(mean(R_square1'),std(R_square1'),'.')
% ylabel('Rsquare*100%')
% xlabel('Angles')
% xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
% %legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('R^2 for each Angles with Neural Network')

%% Plotting KNN Result
for Angles=3:13
    
    for Testing=1:10
    [modelknn,rep2,shuffleddata]=knearntrain(Testing,Angles,dataset3,'intrinsic');
    outpred=predict(modelknn,shuffleddata(Testing,end).intrinsic);
    outpredi=smoothdata(outpred,'gaussian');
    [B,L]=butter(2,0.03,'low');
    outpredic=filter(B,L,outpredi);
    outpredic(1:30)=outpredic(30);
    output{Angles,Testing}=outpredic;
    maxlength=min([length(outpredic) length(shuffleddata(Testing,end).output)]);
    RMSE(Angles-2, Testing) = sqrt(mean((shuffleddata(Testing,end).output(1:maxlength,Angles)-outpredic(1:maxlength)).^2));
    SSE(Angles-2, Testing) = sum((sort(shuffleddata(Testing,end).output(1:maxlength,Angles))-sort(outpredic(1:maxlength))).^2);
    SSR(Angles-2, Testing) = sum((outpredic(1:maxlength)).^2);
    SST(Angles-2, Testing) = sum(((mean(shuffleddata(Testing,end).output(1:maxlength,Angles)))-sort(outpredic(1:maxlength))).^2);
    [R_square1(Angles-2,Testing), R_square2(Angles-2,Testing), R_square3(Angles-2,Testing), R_square4(Angles-2,Testing), Diff] = determ_coef(shuffleddata(Testing,end).output(1:maxlength,Angles),outpredic(1:maxlength));
    Rsquare(Angles-2,Testing) = 1-(SSE(Angles-2, Testing)/SST(Angles-2, Testing));
%     figure(Testing+1)
%     subplot(4,3,Angles-2)
%     plot(outpredic,'LineWidth',2);
%     hold on
%     plot(shuffleddata(Testing,end).output(:,Angles),'LineWidth',2);
%     
%     set(gca,'xtick',[]);
% %     if Angles-2<11
% %         axis([-inf inf 70 180]);
% %     else
% %         axis([-inf inf 50 90]);
% %     end
%     L=LetterSelect(Testing);
%     A=AngleSelect(Angles-2);
%     if Angles-2==3
%         legend('filtered prediction','target','unfiltered prediction');
%     end
%     if Angles-2==2
%         title(['Angles Prediction Against Targets for Alphabets ' L]);
%     end
%     xlabel(A);
%     if Angles-2==4
%         ylabel('Angles (Degrees)');
%     end
     end
end
RMSE(1,:)=RMSE(1,:)/90;
RMSE(4,:)=RMSE(4,:)/90;
RMSE(6,:)=RMSE(6,:)/90;
RMSE(7,:)=RMSE(7,:)/90;
RMSE(9,:)=RMSE(9,:)/90;
RMSE(2:3,:)=RMSE(2:3,:)/101;
RMSE(5,:)=RMSE(5,:)/101;
RMSE(8,:)=RMSE(8,:)/101;
RMSE(10,:)=RMSE(10,:)/101;

RMSE(11,:)=RMSE(11,:)/90;
error=(mean(RMSE'))';
%sdvrmse=std(std(RMSE));
r2=(mean(sqrt(R_square1')))';
% 
% sdvr2=std(std(Rsquare));
% figure
% bar(RMSE')
% ylabel('RMSE (normalized)')
% xlabel('Alphabets')
% xticklabels({'A', 'B', 'C', 'D', 'F', 'I', 'K', 'L', 'O', 'W'})
% legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('RMSE level for each Angle and Alphabet with KNN')
% disp(['Average normalized RMSE ' num2str(error) '+' num2str(sdvrmse)])
% 
% figure
% bar(mean(RMSE))
% hold on
% errorbar(mean(RMSE),std(RMSE),'.')
% axis([-inf inf 0 inf])
% ylabel('RMSE (normalized)')
% xlabel('Alphabets')
% xticklabels({'A', 'B', 'C', 'D', 'F', 'I', 'K', 'L', 'O', 'W'})
% %legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('RMSE level for each Alphabet with KNN')
% disp(['Average normalized RMSE ' num2str(error) '+' num2str(sdvrmse)])
% 
% figure
% bar(mean(RMSE'))
% hold on
% errorbar(mean(RMSE'),std(RMSE'),'.')
% axis([-inf inf 0 inf])
% ylabel('RMSE (normalized)')
% xlabel('Angles')
% xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
% %legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('RMSE level for each Angles with KNN')
% disp(['Average normalized RMSE ' num2str(error) '+' num2str(sdvrmse)])
% 
% figure
% bar(mean(R_square1))
% hold on
% errorbar(mean(R_square1),std(R_square1),'.')
% ylabel('Rsquare*100%')
% xlabel('Alphabets')
% xticklabels({'A', 'B', 'C', 'D', 'F', 'I', 'K', 'L', 'O', 'W'})
% %legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('R^2 for each Alphabet with KNN')
% 
% figure
% bar(mean(R_square1'))
% hold on
% errorbar(mean(R_square1'),std(R_square1'),'.')
% ylabel('Rsquare*100%')
% xlabel('Angles')
% xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
% %legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB')
% title('R^2 for each Angles with KNN')

%% Plotting NN VS KNN Result
figure
a=0;
for Angles=3:8
    
    for Testing=1:5
    [modelknn,rep2,shuffleddata]=knearntrain(Testing,Angles,dataset3,'rms');
    outpred=predict(modelknn,shuffleddata(Testing,end).rms);
    outpredi=smoothdata(outpred,'gaussian');
    [B,L]=butter(2,0.03,'low');
    outpredic=filter(B,L,outpredi);
    outpredic(1:30)=outpredic(30);
    [net,~]=NeuralNetTrain(Testing,Angles,300,dataset3,'rms',rep2);
    outpred1=predict(net,shuffleddata(Testing,end).rms');
    outpredi1=smoothdata(outpred1','gaussian');
    [B,L]=butter(2,0.03,'low');
    outpredic1=filter(B,L,outpredi1);
    outpredic1(1:30)=outpredic1(30);
    a=a+1;
    Al=LetterSelect(Testing);
    A=AngleSelect(Angles-2);
    subplot(5,5,a)
    plot(outpredic1 , 'LineWidth',2)
    hold on
    plot(outpredic, 'LineWidth',2)
    hold on
    plot(shuffleddata(Testing,end).output(:,Angles),':','LineWidth',2)
    set(gca,'xtick',[],'ytick',[]);
%     if Angles-2<11
%         axis([-inf inf 70 180]);
%     else
%         axis([-inf inf 50 90]);
%     end
    if Testing==5 && Angles-2==1
        legend('NN','kNN','Target');
    end
    
    if Angles-2==1
    title(Al);
    end
   if Testing==1
    ylabel(A);
   end
     end
end
