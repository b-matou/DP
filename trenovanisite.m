load('C:\Users\Matous\Documents\DP\train\224\GTtrain.mat');
Dataset_train = GT;

for i = height(Dataset_train):-1:1
    if isempty(Dataset_train{i,2}{1})
        Dataset_train(i,:) = [];
    end
    if sum(i == [7280, 6707, 5671, 5352, 4116, 3213, 2701, 2586, 2548, 2341, 1941, 1273, 636, 310])
        Dataset_train(i,:) = [];
    end
end

trainingDataTbl = Dataset_train;

load('C:\Users\Matous\Documents\DP\dev\224\GTdev.mat');
Dataset_dev = GT;

for i = height(Dataset_dev):-1:1
    if isempty(Dataset_dev{i,2}{1})
        Dataset_dev(i,:) = [];
    end
end

evalDataTbl = Dataset_dev;

load('C:\Users\Matous\Documents\DP\test\224\GTtest.mat');
Dataset_test = GT;

testDataTbl = Dataset_test;


imdsTrain = imageDatastore(trainingDataTbl{:,'name'});
bldsTrain = boxLabelDatastore(trainingDataTbl(:,'object'));

imdsEval = imageDatastore(evalDataTbl{:,'name'});
bldsEval = boxLabelDatastore(evalDataTbl(:,'object'));

imdsTest = imageDatastore(testDataTbl{:,'name'});
bldsTest = boxLabelDatastore(testDataTbl(:,'object'));

trainingData = combine(imdsTrain,bldsTrain);
evalData = combine(imdsEval,bldsEval);
testData = combine(imdsTest,bldsTest);

data = read(trainingData);
I = data{1};
bbox = data{2};
annotatedImage = insertShape(I,'Rectangle',bbox);
annotatedImage = imresize(annotatedImage,2);
figure
imshow(annotatedImage)

%%
inputSize = [224 224 3];

%preprocessedTrainingData = transform(trainingData, @(data)preprocessData(data,inputSize));
numAnchors = 7;
anchorBoxes = [41 49; 46 29; 84 161;17 16;96 62;47 102;25 26];
% anchorBoxes = [19 19;95 156;71 52;36 35;48 108];
% [a b] = estimateAnchorBoxes(trainingData,numAnchors);

featureExtractionNetwork = resnet50;
featureLayer = 'activation_40_relu';
numClasses = 1;
lgraph = fasterRCNNLayers(inputSize,numClasses,anchorBoxes,featureExtractionNetwork,featureLayer);

%%
options = trainingOptions('adam',...
    'MaxEpochs',5,...
    'MiniBatchSize',7,...
    'InitialLearnRate',0.0001,...
    'ExecutionEnvironment','gpu',...
    'L2Regularization',0.000001,...
    'GradientDecayFactor',0.95,...
    'SquaredGradientDecayFactor',0.9);


[detector, info] = trainFasterRCNNObjectDetector(trainingDataTbl,lgraph,options,...
    'UseParallel',true, ...
    'NegativeOverlapRange',[0 0.3], ...
    'PositiveOverlapRange',[0.3 1],...
    'NumRegionsToSample',400,...
    'TrainingMethod','four-step');

% 'SmallestImageDimension',400,
% I = imread(testDataTbl.imageFilename{1});
% I = imresize(I,inputSize(1:2));
% [bboxes,scores] = detect(detector,I);
% 
% 
% I = insertObjectAnnotation(I,'rectangle',bboxes,scores);
% figure
% imshow(I)

%%
detectionResults = detect(detector,testData,'MinibatchSize',5,'Threshold',0.5);

[ap, recall, precision] = evaluateDetectionPrecision(detectionResults,testData,0.1);

figure
plot(recall,precision)
xlabel('Recall')
ylabel('Precision')
grid on
title(sprintf('Average Precision = %.2f', ap))

obrazek = 70;
I = imread(testDataTbl.name{obrazek});
I = insertShape(I,'Rectangle',testDataTbl.object{obrazek},'color','green','LineWidth',3);
I = insertShape(I,'Rectangle',detectionResults.Boxes{obrazek},'color','red','LineWidth',3);
figure
imshow(I,[])