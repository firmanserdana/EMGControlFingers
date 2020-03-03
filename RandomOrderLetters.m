%Randomize letters


for i = 1:10
    for j = 1:3
        Vector(i,j) = i;
    end
end

LetterVector = reshape(Vector,[30,1]);

RandomOrder = LetterVector(randperm(length(LetterVector)));

for i=1:length(RandomOrder)
RandomLetter(1,i) = LetterSelect(RandomOrder(i));
end

RandomLetter'

