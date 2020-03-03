function [net,shuffleddata]=NeuralNetTrain(Alphabets,Angles,maxEpochs,dataset,fieldname,rep2)
%Angles=5;
%Testing=5;

traininput=[];
trainoutput=[];
for i=1:size(dataset,1)
%     rep2=randperm(size(dataset,2));
    dataset(i,:)=dataset(i,rep2);
end
shuffleddata=dataset;
    for j=1:size(dataset,2)-1
        tempinput=getfield(dataset(Alphabets,j),fieldname);
        k = min([length(tempinput) length(dataset(Alphabets,j).output)]);
        traininput{j}(:,:)=tempinput(1:k,:)';
        trainoutput{j}(:,:)=dataset(Alphabets,j).output(1:k,Angles)';
    end
traininput=reshape(traininput,size(traininput,1)*size(traininput,2),1);
trainoutput=reshape(trainoutput,size(trainoutput,1)*size(trainoutput,2),1);

idx=randperm(length(traininput));
traininput=traininput(idx);
trainoutput=trainoutput(idx);



valinput=traininput(floor(0.7*length(traininput)):end);
valoutput=trainoutput(floor(0.7*length(trainoutput)):end);
traininput1=traininput(1:floor(0.7*length(traininput)));
trainoutput1=trainoutput(1:floor(0.7*length(trainoutput)));


numFeatures = size(tempinput,2);
numHiddenUnits = 125;
numResponses = length(Angles);

layers = [ ...
        sequenceInputLayer(numFeatures)
        reluLayer
        fullyConnectedLayer(100)
        dropoutLayer(0.5)
        reluLayer
        fullyConnectedLayer(50)
        fullyConnectedLayer(numResponses)
        regressionLayer];


%maxEpochs = 500;
miniBatchSize = 20;

    options = trainingOptions('adam', ...
        'MaxEpochs',maxEpochs, ...
        'MiniBatchSize',miniBatchSize, ...
        'InitialLearnRate',0.01, ...
        'ValidationData',{valinput,valoutput}, ...
        'ValidationFrequency',10, ...
        'GradientThreshold',1, ...
        'Shuffle','never', ...
        'SequenceLength', 'shortest',...
        'ValidationPatience', 10,...
        'Verbose',0);
    
net = trainNetwork(traininput1,trainoutput1,layers,options);

%plot(outpredic,'LineWidth',2);
%hold on
%plot(dataset(Testing,3).output(:,Angles),'LineWidth',2);
%hold on
%plot(outpredi,'--');
%legend('filtered prediction','target','unfiltered prediction');
%title(['Angles Prediction Against Targets with RMSE = ' num2str(RMSE)]);
%xlabel('Steps');
%ylabel('Angles');