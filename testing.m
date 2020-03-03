traininput=[];
trainoutput=[];
for i=1:size(dataset,1)
    for j=1:size(dataset,2)-1
        k = min([length(dataset(i,j).rms) length(dataset(i,j).output)]);
        tempinput=dataset(i,j).rms;
        traininput{i,j}(:,:)=tempinput(1:k,:)';
        trainoutput{i,j}(:,:)=dataset(i,j).output(1:k,5)';
    end
end


data=[];
    group=[];
for k=1:10
for i=3:13
    for j=1:12
        if i<13
            a=alldata(k,j).output(:,i);
        else
            a=alldata(k,j).output(:,i);
        end
        artest(j).input=a;
        data=[data artest(j).input'];
        grouping=[];
        for b=1:length(artest(j).input)
            grouping(b)=j;
        end
        group=[group grouping];
    end
    
    [anovatest(i-2),~,stats(i-2)]=anova1(data, group,'off');
    data=[];
    group=[];
end
test(k,:)=anovatest;
stat(k,:)=stats;

end
figure
bar(test)
ylabel('p-value')
xlabel('Alphabets')
xticklabels({'A', 'B', 'C', 'D', 'F', 'I', 'K', 'L', 'O', 'W'})

title('p-value from ANOVA for each Angle and Alphabets')
for i=1:10
    A(i)=0.05;
end
hold on
plot(1:10,A,'--','Linewidth',3)
axis([-inf inf 0.02 0.07])
legend('TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB','0.05 significance level')

a=0;
for i=1:size(allpval,1) 
    for j=1:size(allpval,2)
        if allpval(i,j)<0.05
        alltest(i*5-4,j)="<0.05";
        else
            alltest(i*5-4,j)="n.s.";
        end
        if data1pval(i,j)<0.05
        alltest(i*5-3,j)="<0.05";
        else
            alltest(i*5-3,j)="n.s.";
        end
        if data2pval(i,j)<0.05
        alltest(i*5-2,j)="<0.05";
        else
            alltest(i*5-2,j)="n.s.";
        end
        if data3pval(i,j)<0.05
        alltest(i*5-1,j)="<0.05";
        else
            alltest(i*5-1,j)="n.s.";
        end
        if data4pval(i,j)<0.05
        alltest(i*5,j)="<0.05";
        else
            alltest(i*5,j)="n.s.";
        end
    end
end
    
for i=1:size(data4pval,1)
    for j=1:size(data4pval,2)
        if data4pval(i,j)<0.05
        alltest(i,j)="<0.05";
        else
            alltest(i,j)="n.s.";
        end
    end
end
%% PCA

%PCA EMG
for j=1:10
    for k=1:12
for i=1:5
    [~,~,~,~,explained{j,k}(:,i),~] = pca(alldata(j,k).rawinput(:,64*i-63:64*i));
end
    end
end
totalexplained=[];
for i=1:5
    a=0;
for j=1:10
    for k=1:12
        a=a+1;
        totalexplained{i}(:,a)=explained{j,k}(:,i);
    end
end
end
for i=1:5
    meanexplained(i,:)=mean(totalexplained{1,i},2);
end
for i=1:5
    stdexplained(i,:)=std(totalexplained{1,i}');
end

for i=2:7
    meanexplained(:,i)=meanexplained(:,i)+meanexplained(:,i-1);
end

figure
bar(meanexplained(:,1:7)')
hold on
ngroups = size(meanexplained(:,1:7)', 1);
nbars = size(meanexplained(:,1:7)', 2);
% Calculating the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, meanexplained(i,1:7), stdexplained(i,1:7), '.');
end
legend('Ext1','Ext2','Int1','Int2','Thenar')

axis([-inf inf 50 100])
ylabel('Percent Explained')
xlabel('First Principal Components')

% PCA Kinematics
for j=1:10
    for k=1:3
    averagekin1{j,k} = mean(dataset1(j,k).rawoutput(:,3:13));
    averagekin2{j,k} = mean(dataset2(j,k).rawoutput(:,3:13));
    averagekin3{j,k} = mean(dataset3(j,k).rawoutput(:,3:13));
    averagekin4{j,k} = mean(dataset4(j,k).rawoutput(:,3:13));
    end
end
totalexplainedkin=[];
    a=0;
for j=1:10
    for k=1:3
        a=a+1;
        totalaeveragekin1(:,a)=averagekin1{j,k};
        totalaeveragekin2(:,a)=averagekin2{j,k};
        totalaeveragekin3(:,a)=averagekin3{j,k};
        totalaeveragekin4(:,a)=averagekin4{j,k};
    end
end

[~,score1,~,~,explained(1,:),~] = pca(totalaeveragekin1');
[~,score2,~,~,explained(2,:),~] = pca(totalaeveragekin2');
[~,score3,~,~,explained(3,:),~] = pca(totalaeveragekin3');
[~,score4,~,~,explained(4,:),~] = pca(totalaeveragekin4');

meanexplainedkin=mean(explained);
stdexplainedkin=std(explained);

for i=2:11
    meanexplainedkin(i)=meanexplainedkin(i)+meanexplainedkin(i-1);
end

for i=1:10
    for j=1:11
        meanscores(i,j)=mean([mean(score1(i*3-2:i*3,j)) mean(score2(i*3-2:i*3,j)) mean(score3(i*3-2:i*3,j)) mean(score4(i*3-2:i*3,j))]);
        stdscores(i,j)=std([mean(score1(i*3-2:i*3,j)) mean(score2(i*3-2:i*3,j)) mean(score3(i*3-2:i*3,j)) mean(score4(i*3-2:i*3,j))]);
    end
end
  
figure(20)

for i=1:10
errorbar(meanscores(i,1),meanscores(i,2),stdscores(i,1),'horizontal','r')
hold on
errorbar(meanscores(i,1),meanscores(i,2),stdscores(i,2),'r')
end
alpha(0.3)
for i=1:10
    h(i)=scatter(meanscores(i,1),meanscores(i,2));
hold on

end
for i=1:10
    text(meanscores(i,1)+5,meanscores(i,2)+5,LetterSelect(i))
end
alpha(0.3)
xlabel('PC1')
ylabel('PC2')
hold off

figure(21)
hold on
plot3d_errorbars(meanscores(1:10,1),meanscores(1:10,2),meanscores(1:10,3), stdscores(1:10,1), stdscores(1:10,2), stdscores(1:10,3),'o');
for i=1:10
    text(meanscores(i,1)+5,meanscores(i,2)+5,meanscores(i,3)+5,LetterSelect(i))
end
hold off
grid on
alpha(0.3)
xlabel('PC1')
ylabel('PC2')
zlabel('PC3')

    figure
plot(meanexplainedkin,'Linewidth',2)
hold on
errorbar(meanexplainedkin,stdexplainedkin,'.')
for i=1:5
text(i+0.05,meanexplainedkin(i)-0.2,num2str(meanexplainedkin(i),4))
end
axis([0 inf 50 100])
ylabel('Percent Explained')
xlabel('First Principal Components ')

% Prediction Kinematics PCA
for i=1:10
    for j=1:11
        outputed(j,i)=mean(output{j,i});
    end
end


[~,scoreout,~,~,~,~] = pca(outputed'); 
figure(20)
hold on
for i=1:10
    h(i)=scatter(scoreout(i,1),scoreout(i,2),'filled','diamond');

end


hold off

figure(21)
hold on
for i=1:10
    h(i)=scatter3(scoreout(i,1),scoreout(i,2),scoreout(i,3),'filled','diamond');

end


hold off

%%Summary barplot
title('Average Normalized RMSE for each Grid Conf, Num of Features, and Classifier')
ylabel('RMSE (normalized)')
xticklabels({'FullGrid','PCA7','PCA14'})
legend('30-07 NN','30-07 KNN','08-08 NN','08-08 KNN')

%% Fourier Analysis
a=7;
b=4;
emgsignal=alldata(a,b).rawinput;
Fs=2048;
t=0:1/Fs:size(emgsignal,1)/Fs;
nfft=1024;
Freqsignal=fft(emgsignal(:,end-45),nfft);
Freqsignal=Freqsignal(1:nfft/2);
mF=abs(Freqsignal);
f=(0:nfft/2-1)*Fs/nfft;
figure
plot(f,mF);
title('Power Spectrum of EMG Signal');
xlabel('Frequency (Hz)');
ylabel('Power'); 

%%Summary Result

allrmse=error;
allstdrmse=sdvrmse;
allr2=r2;
allstdr2=sdvr2;


allrmse=[allrmse error];
allstdrmse=[allstdrmse sdvrmse];
allr2=[allr2 r2];
allstdr2=[allstdr2 sdvr2];

allrmse=[allrmse 0];
allstdrmse=[allstdrmse 0];
allr2=[allr2 0];
allstdr2=[allstdr2 0];

figure
bar(1:19,allr2','DisplayName','meanexplained')
hold on
errorbar(allr2',allstdr2','.','Linewidth',1)
XTickLabel={'KNNfull' ; 'KNN14'; 'KNN7' ; 'KNN1';'';'NNfull';'NN14';'NN7';'NN1';'';'NN-S1';'NN-S2';'NN-S3';'NN-S4';'';'KNN-S1';'KNN-S2';'KNN-S3';'KNN-S4'};
XTick=1:19;
set(gca, 'XTickLabel', XTickLabel);
set(gca, 'XTick',XTick);
axis([-inf inf 0 inf])
title('Average Determination Coefficient')
ylabel('Percentage/100%')

figure
bar(1:19,allrmse','DisplayName','meanexplained')
hold on
errorbar(allrmse',allstdrmse','.','Linewidth',1)
XTickLabel={'KNNfull' ; 'KNN14'; 'KNN7' ; 'KNN1';'';'NNfull';'NN14';'NN7';'NN1';'';'NN-S1';'NN-S2';'NN-S3';'NN-S4';'';'KNN-S1';'KNN-S2';'KNN-S3';'KNN-S4'};
XTick=1:19;
set(gca, 'XTickLabel', XTickLabel);
set(gca, 'XTick',XTick);
axis([-inf inf 0 inf])
title('Average RMSE Level')
ylabel('Percentage/100%')

%% Result Analysis
% angles based analysis
for i=1:11
    [prmseall(:,i),~,statsrmse(:,i)]=anovan(meanrmseangle(i,:),{grsangle,grregangle,grdimangle},'model','interaction','display','off');
    [pr2all(:,i),~,statsr2(:,i)]=anovan(meanr2angle(i,:),{grsangle,grregangle,grdimangle},'model','interaction','display','off');
end

% bar rmse averaged by subject, differed by regressor and dimension

for i=1:4
    tempdata1(:,i)=meanrmseangle(:,i*8-7);
    tempdata2(:,i)=meanrmseangle(:,i*8-6);
    tempdata3(:,i)=meanrmseangle(:,i*8-5);
    tempdata4(:,i)=meanrmseangle(:,i*8-4);
    tempdata5(:,i)=meanrmseangle(:,i*8-3);
    tempdata6(:,i)=meanrmseangle(:,i*8-2);
    tempdata7(:,i)=meanrmseangle(:,i*8-1);
    tempdata8(:,i)=meanrmseangle(:,i*8);
    tempdata9(:,i)=meanrmseangle(:,(i*8-7)+32);
    tempdata10(:,i)=meanrmseangle(:,(i*8-6)+32);
    tempdata11(:,i)=meanrmseangle(:,(i*8-5)+32);
    tempdata12(:,i)=meanrmseangle(:,(i*8-4)+32);
    tempdata13(:,i)=meanrmseangle(:,(i*8-3)+32);
    tempdata14(:,i)=meanrmseangle(:,(i*8-2)+32);
    tempdata15(:,i)=meanrmseangle(:,(i*8-1)+32);
    tempdata16(:,i)=meanrmseangle(:,(i*8)+32);
end
meanrmsetotal1=[mean(tempdata1') ;mean(tempdata2') ;mean(tempdata3') ;mean(tempdata4') ;mean(tempdata5') ;mean(tempdata6')]; 
meanrmsetotal2=[mean(tempdata9') ;mean(tempdata10') ;mean(tempdata11') ;mean(tempdata12') ;mean(tempdata13') ;mean(tempdata14')];
meanrmsetotal3=[mean(tempdata1') ;mean(tempdata7') ;mean(tempdata8') ;mean(tempdata9') ;mean(tempdata15') ;mean(tempdata16')];

rmsetotal1=[(tempdata1') ;(tempdata2') ;(tempdata3') ;(tempdata4') ;(tempdata5') ;(tempdata6')]; 
rmsetotal2=[(tempdata9') ;(tempdata10') ;(tempdata11') ;(tempdata12') ;(tempdata13') ;(tempdata14')];
rmsetotal3=[(tempdata1') ;(tempdata7') ;(tempdata8') ;(tempdata9') ;(tempdata15') ;(tempdata16')];

stdrmsetotal1=[std(tempdata1') ;std(tempdata2') ;std(tempdata3') ;std(tempdata4') ;std(tempdata5') ;std(tempdata6')];
stdrmsetotal2=[std(tempdata9') ;std(tempdata10') ;std(tempdata11') ;std(tempdata12') ;std(tempdata13') ;std(tempdata14')];
stdrmsetotal3=[std(tempdata1') ;std(tempdata7') ;std(tempdata8') ;std(tempdata9') ;std(tempdata15') ;std(tempdata16')];

[bestrmse,idbestrmse]=min(meanrmsetotal);
beststdrmse=stdrmsetotal(idbestrmse);

% anova testing feature dimension in NN PCA14vsSel14, PCA7vsSel7,
% FullvsPCAs, FullvsSels
for i=1:11
    prmse(1,i)=anova1([tempdata2(i,:)';tempdata5(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    prmse(2,i)=anova1([tempdata3(i,:)';tempdata6(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    prmse(3,i)=anova1([tempdata1(i,:)';tempdata2(i,:)';tempdata3(i,:)';tempdata4(i,:)'],[1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4],'off');
end

for i=1:11
    prmse(4,i)=anova1([tempdata1(i,:)';tempdata5(i,:)';tempdata6(i,:)'],[1 1 1 1 2 2 2 2 3 3 3 3],'off');
end

% anova dimension in kNN PCA14vsSel14, PCA7vsSel7,
% FullvsPCAs, FullvsSels
for i=1:11
    prmse(5,i)=anova1([tempdata10(i,:)';tempdata13(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    prmse(6,i)=anova1([tempdata11(i,:)';tempdata14(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    prmse(7,i)=anova1([tempdata9(i,:)';tempdata10(i,:)';tempdata11(i,:)';tempdata12(i,:)'],[1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4],'off');
end

for i=1:11
    prmse(8,i)=anova1([tempdata9(i,:)';tempdata13(i,:)';tempdata14(i,:)'],[1 1 1 1 2 2 2 2 3 3 3 3],'off');
end

% anova testing NNvskNN, Intvsfull, ExtvsFull, ExtvsInt
for i=1:11
    prmse(9,i)=anova1([tempdata1(i,:)';tempdata9(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    prmse(10,i)=anova1([tempdata1(i,:)';tempdata7(i,:)'],[1 1 1 1 2 2 2 2],'off');
    prmse(11,i)=anova1([tempdata9(i,:)';tempdata15(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    prmse(12,i)=anova1([tempdata1(i,:)';tempdata8(i,:)'],[1 1 1 1 2 2 2 2],'off');
    prmse(13,i)=anova1([tempdata9(i,:)';tempdata16(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    prmse(14,i)=anova1([tempdata7(i,:)';tempdata8(i,:)'],[1 1 1 1 2 2 2 2],'off');
    prmse(15,i)=anova1([tempdata15(i,:)';tempdata16(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

figure(11)
subplot(2,1,1)
bar(100*meanrmsetotal1')
hold on
ngroups = size(meanrmsetotal1', 1);
nbars = size(meanrmsetotal1', 2);
% Calculating the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, 100*meanrmsetotal1(i,:), 100*stdrmsetotal1(i,:), '.');
end
ylabel('RMSE/Range of Motion %')
set(gca,'xtick',[])
axis([-inf inf 0 100])

xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
legend('NN-Full', 'NN-PCA14', 'NN-PCA7', 'NN-PCA1', 'NN-Se14','NN-Sel7')
hold off

figure(12)
subplot(2,1,1)
bar(100*meanrmsetotal2')
hold on
ngroups = size(meanrmsetotal2', 1);
nbars = size(meanrmsetotal2', 2);
% Calculating the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, 100*meanrmsetotal2(i,:), 100*stdrmsetotal2(i,:), '.');
end
ylabel('RMSE/Range of Motion %')
set(gca,'xtick',[])
axis([-inf inf 0 100])

xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
legend('kNN-Full', 'kNN-PCA14', 'kNN-PCA7', 'kNN-PCA1', 'kNN-Se14','kNN-Sel7')
hold off

figure(13)
subplot(2,1,1)
bar(100*meanrmsetotal3')
hold on
ngroups = size(meanrmsetotal3', 1);
nbars = size(meanrmsetotal3', 2);
% Calculating the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, 100*meanrmsetotal3(i,:), 100*stdrmsetotal3(i,:), '.');
end
ylabel('RMSE/Range of Motion %')
set(gca,'xtick',[])
axis([-inf inf 0 100])

xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
legend('NN-Full', 'NN-Ext', 'NN-Int', 'kNN-Full', 'kNN-Ext','kNN-Int')
hold off

% bar r2 averaged by subject differed by regressor and dimension
for i=1:4
    tempdata1(:,i)=meanr2angle(:,i*8-7);
    tempdata2(:,i)=meanr2angle(:,i*8-6);
    tempdata3(:,i)=meanr2angle(:,i*8-5);
    tempdata4(:,i)=meanr2angle(:,i*8-4);
    tempdata5(:,i)=meanr2angle(:,i*8-3);
    tempdata6(:,i)=meanr2angle(:,i*8-2);
    tempdata7(:,i)=meanr2angle(:,i*8-1);
    tempdata8(:,i)=meanr2angle(:,i*8);
    tempdata9(:,i)=meanr2angle(:,(i*8-7)+32);
    tempdata10(:,i)=meanr2angle(:,(i*8-6)+32);
    tempdata11(:,i)=meanr2angle(:,(i*8-5)+32);
    tempdata12(:,i)=meanr2angle(:,(i*8-4)+32);
    tempdata13(:,i)=meanr2angle(:,(i*8-3)+32);
    tempdata14(:,i)=meanr2angle(:,(i*8-2)+32);
    tempdata15(:,i)=meanr2angle(:,(i*8-1)+32);
    tempdata16(:,i)=meanr2angle(:,(i*8)+32);
end
meanr2total1=[mean(tempdata1') ;mean(tempdata2') ;mean(tempdata3') ;mean(tempdata4') ;mean(tempdata5') ;mean(tempdata6')]; 
meanr2total2=[mean(tempdata9') ;mean(tempdata10') ;mean(tempdata11') ;mean(tempdata12') ;mean(tempdata13') ;mean(tempdata14')];
meanr2total3=[mean(tempdata1') ;mean(tempdata7') ;mean(tempdata8') ;mean(tempdata9') ;mean(tempdata15') ;mean(tempdata16')];

stdr2total1=[std(tempdata1') ;std(tempdata2') ;std(tempdata3') ;std(tempdata4') ;std(tempdata5') ;std(tempdata6')];
stdr2total2=[std(tempdata9') ;std(tempdata10') ;std(tempdata11') ;std(tempdata12') ;std(tempdata13') ;std(tempdata14')];
stdr2total3=[std(tempdata1') ;std(tempdata7') ;std(tempdata8') ;std(tempdata9') ;std(tempdata15') ;std(tempdata16')];

[bestr2,idbestr2]=max(meanr2total);
beststdr2=stdr2total(idbestr2);

% anova testing feature dimension in NN PCA14vsSel14, PCA7vsSel7,
% FullvsPCAs, FullvsSels
for i=1:11
    pr2(1,i)=anova1([tempdata2(i,:)';tempdata5(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    pr2(2,i)=anova1([tempdata3(i,:)';tempdata6(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    pr2(3,i)=anova1([tempdata1(i,:)';tempdata2(i,:)';tempdata3(i,:)';tempdata4(i,:)'],[1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4],'off');
end

for i=1:11
    pr2(4,i)=anova1([tempdata1(i,:)';tempdata5(i,:)';tempdata6(i,:)'],[1 1 1 1 2 2 2 2 3 3 3 3],'off');
end

% anova dimension in kNN PCA14vsSel14, PCA7vsSel7,
% FullvsPCAs, FullvsSels
for i=1:11
    pr2(5,i)=anova1([tempdata10(i,:)';tempdata13(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    pr2(6,i)=anova1([tempdata11(i,:)';tempdata14(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    pr2(7,i)=anova1([tempdata9(i,:)';tempdata10(i,:)';tempdata11(i,:)';tempdata12(i,:)'],[1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4],'off');
end

for i=1:11
    pr2(8,i)=anova1([tempdata9(i,:)';tempdata13(i,:)';tempdata14(i,:)'],[1 1 1 1 2 2 2 2 3 3 3 3],'off');
end

% anova testing NNvskNN, Intvsfull, ExtvsFull, ExtvsInt
for i=1:11
    pr2(9,i)=anova1([tempdata1(i,:)';tempdata9(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    pr2(10,i)=anova1([tempdata1(i,:)';tempdata7(i,:)'],[1 1 1 1 2 2 2 2],'off');
    pr2(11,i)=anova1([tempdata9(i,:)';tempdata15(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    pr2(12,i)=anova1([tempdata1(i,:)';tempdata8(i,:)'],[1 1 1 1 2 2 2 2],'off');
    pr2(13,i)=anova1([tempdata9(i,:)';tempdata16(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

for i=1:11
    pr2(14,i)=anova1([tempdata7(i,:)';tempdata8(i,:)'],[1 1 1 1 2 2 2 2],'off');
    pr2(15,i)=anova1([tempdata15(i,:)';tempdata16(i,:)'],[1 1 1 1 2 2 2 2],'off');
end

figure(11)
subplot(2,1,2)
bar(100*meanr2total1')
hold on
ngroups = size(meanr2total1', 1);
nbars = size(meanr2total1', 2);
% Calculating the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, 100*meanr2total1(i,:), 100*stdr2total1(i,:), '.');
end
ylabel('R %')
axis([-inf inf 0 100])
xlabel('Joint Angle')
xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
hold off

figure(12)
subplot(2,1,2)
bar(100*meanr2total2')
hold on
ngroups = size(meanr2total2', 1);
nbars = size(meanrmsetotal2', 2);
% Calculating the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, 100*meanr2total2(i,:), 100*stdr2total2(i,:), '.');
end
ylabel('R %')
axis([-inf inf 0 100])
xlabel('Joint Angle')
xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
hold off

figure(13)
subplot(2,1,2)
bar(100*meanr2total3')
hold on
ngroups = size(meanr2total3', 1);
nbars = size(meanr2total3', 2);
% Calculating the width for each bar group
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, 100*meanr2total3(i,:), 100*stdr2total3(i,:), '.');
end
ylabel('R %')
axis([-inf inf 0 100])
xlabel('Joint Angle')
xticklabels({'TIF','TAP','MPF2','FIF2','MPF3','FIF3','FIF4','MPF4','FIF5','MPF5','TAB'})
hold off

%% Rmse correction
meanrmseangle(1,:)=meanrmseangle(1,:)*90;
meanrmseangle(4,:)=meanrmseangle(4,:)*90;
meanrmseangle(6,:)=meanrmseangle(6,:)*90;
meanrmseangle(7,:)=meanrmseangle(7,:)*90;
meanrmseangle(9,:)=meanrmseangle(9,:)*90;
meanrmseangle(2:3,:)=meanrmseangle(2:3,:)*101;
meanrmseangle(5,:)=meanrmseangle(5,:)*101;
meanrmseangle(8,:)=meanrmseangle(8,:)*101;
meanrmseangle(10,:)=meanrmseangle(10,:)*101;

meanrmseangle(11,:)=meanrmseangle(11,:)*90;