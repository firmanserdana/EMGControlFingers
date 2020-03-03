function [net,rep2,shuffleddata]=NetTrain(Alphabet,Angles,dataset,fieldname)
%Angles=5;
%Testing=5;

traininput=[];
trainoutput=[];
for i=1:size(dataset,1)
    rep2=randperm(size(dataset,2));
    dataset(i,:)=dataset(i,rep2);
end
shuffleddata=dataset;

    for j=1:size(dataset,2)-1
        tempinput=getfield(dataset(Alphabet,j),fieldname);
        k = min([length(tempinput) length(dataset(Alphabet,j).output)]);
        traininput{j}(:,:)=tempinput(1:k,:)';
        trainoutput{j}(:,:)=dataset(Alphabet,j).output(1:k,Angles)';
    end

traininput=reshape(traininput,size(traininput,1)*size(traininput,2),1);
trainoutput=reshape(trainoutput,size(trainoutput,1)*size(trainoutput,2),1);

idx=randperm(length(traininput));
traininput1=traininput(idx);
trainoutput1=trainoutput(idx);
input=[];
output=[];
for i=1:length(idx)
    tempin=traininput{i,1};
    tempout=trainoutput{i,1};
    input=[input tempin];
    output=[output tempout];
end
assignin('base','input',input);
assignin('base','output',output);
hiddenLayerSize = 10;

net = timedelaynet(1:2,hiddenLayerSize);

% Set up Division of Data for Training, Validation, Testing
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;


net = train(net,input,output);
    

