function [modellda,rep2,shuffleddata]=linedatrain(Angles,dataset,fieldname)
traininput=[];
trainoutput=[];
for i=1:size(dataset,1)
    rep2=randperm(size(dataset,2));
    dataset(i,:)=dataset(i,rep2);
end
shuffleddata=dataset;
for i=1:size(dataset,1)
    for j=1:size(dataset,2)-1
        tempinput=getfield(dataset(i,j),fieldname);
        k = min([length(tempinput) length(dataset(i,j).output)]);
        traininput{i,j}(:,:)=tempinput(1:k,:)';
        trainoutput{i,j}(:,:)=dataset(i,j).output(1:k,Angles)';
    end
end
traininput=reshape(traininput,size(traininput,1)*size(traininput,2),1);
trainoutput=reshape(trainoutput,size(trainoutput,1)*size(trainoutput,2),1);

idx=randperm(length(traininput));
traininput=traininput(idx);
trainoutput=trainoutput(idx);

traininput=traininput(1:floor(0.7*length(traininput)));
trainoutput=trainoutput(1:floor(0.7*length(trainoutput)));
valinput=traininput(floor(0.7*length(traininput)):end);
valoutput=trainoutput(floor(0.7*length(trainoutput)):end);


modellda = fitcsvm(traininput{1,1}',trainoutput{1,1}(1:end,:)');