% načtení matici anotovaných trénovacích dat
load('C:\Users\Matous\Documents\DP\train\224\GTtrain.mat');

% projití všech snímků z trénovací množiny odzadu
for i = height(GT):-1:1
    % pokud není v obrázku anotovaný objekt, pak se z množiny odstraní
    if isempty(GT{i,2}{1})
        GT(i,:) = [];
    end
    % odstranění nevhodně anotovaných dat
    if sum(i == [7280, 6707, 5671, 5352, 4116, 3213, 2701, 2586, 2548, 2341, 1941, 1273, 636, 310])
        GT(i,:) = [];
    end
end

% vytvoření datastoru, který je požadovaný na vstup sítě
imdsTrain = imageDatastore(GT{:,'name'});
bldsTrain = boxLabelDatastore(GT(:,'object'));
trainingData = combine(imdsTrain,bldsTrain);

% načtení jednoho obrázku i s anotovanými objekty pro kontrolu
data = read(trainingData);
I = data{1};
bbox = data{2};
annotatedImage = insertShape(I,'Rectangle',bbox);

% zobrazení
figure
imshow(annotatedImage)

%% příprava a trénování sítě
% definice velikosti vstupních obrazů
inputSize = [224 224 3];

% definice velikostí anchorů
anchorBoxes = [41 49; 46 29; 84 161;17 16;96 62;47 102;25 26];

% vytvoření Faster R-CNN sítě s přetrénovanou CNN ResNet50
featureExtractionNetwork = resnet50;
featureLayer = 'activation_40_relu';
numClasses = 1;
lgraph = fasterRCNNLayers(inputSize,numClasses,anchorBoxes,featureExtractionNetwork,featureLayer);

% nastavení učících parametrů
options = trainingOptions('adam',...
    'MaxEpochs',5,...
    'MiniBatchSize',7,...
    'InitialLearnRate',0.0001,...
    'ExecutionEnvironment','gpu',...
    'L2Regularization',0.000001,...
    'GradientDecayFactor',0.95,...
    'SquaredGradientDecayFactor',0.9);

% trénování sítě
[detector, info] = trainFasterRCNNObjectDetector(GT,lgraph,options,...
    'UseParallel',true, ...
    'NegativeOverlapRange',[0 0.3], ...
    'PositiveOverlapRange',[0.3 1],...
    'NumRegionsToSample',400,...
    'TrainingMethod','four-step');