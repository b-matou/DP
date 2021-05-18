% načtení matice anotovaných dat s převzorkovanými daty na velikost 224x224
load('C:\Users\Barborka\Desktop\škola\DP\data\train\224\GTtrain.mat');
% vytvoření proměnné pro uložení všech anchorů
anchory = [];

% pro každý obrázek se projíždí jeho anchory, odzadu, jelikož se budou
% mazat řádky
for i = height(GT):-1:1
    % pokud ibrázek nemá žádný označený objekt, pak se smaže jeho řádek
    if isempty(GT{i,2}{1})
        GT(i,:) = [];
    % pokud se jedná o obrázek, který má označený objekt téměř přes celý
    % obrázek pro všechny objekty (nalezeno předem), pak se řádek vymaže
    elseif sum(i == [7280, 6707, 5671, 5352, 4116, 3213, 2701, 2586, 2548, 2341, 1941, 1273, 636, 310])
        GT(i,:) = [];
    % pokud jsou v obrázku označené cizí objekty, pak se uloží do proměnné
    % anchorů
    else
        anchory = [anchory; GT{i,2}{1}];
    end
end
% z informací o anchorech nás zajímá pouze jejich velikost, ne pozice
anchory = anchory(:,[2,4]);
% seřazení velikostí stran anchorů
anchory = sort(anchory,2);

% k-means pro rozdělení do 6 skupin
[idx,C] = kmeans(anchory,6);

% zobrazení velikostí anchorů a středů po k-means
figure
plot(anchory(find(idx==1),1),anchory(find(idx==1),2),'.','Color','#4DBEEE')
hold on
text(C(1,1),C(1,2),['[' num2str(round(C(1,1))) ', ' num2str(round(C(1,2))) ']'],'FontSize',17,'VerticalAlignment','bottom','HorizontalAlignment','right')
plot(anchory(find(idx==2),1),anchory(find(idx==2),2),'g.')
text(C(2,1),C(2,2),['[' num2str(round(C(2,1))) ', ' num2str(round(C(2,2))) ']'],'FontSize',17,'VerticalAlignment','bottom','HorizontalAlignment','right')
plot(anchory(find(idx==3),1),anchory(find(idx==3),2),'.','Color','#EDB120')
text(C(3,1),C(3,2),['[' num2str(round(C(3,1))) ', ' num2str(round(C(3,2))) ']'],'FontSize',17,'VerticalAlignment','bottom','HorizontalAlignment','right')
plot(anchory(find(idx==4),1),anchory(find(idx==4),2),'c.')
text(C(4,1),C(4,2),['[' num2str(round(C(4,1))) ', ' num2str(round(C(4,2))) ']'],'FontSize',17,'VerticalAlignment','bottom','HorizontalAlignment','right')
plot(anchory(find(idx==5),1),anchory(find(idx==5),2),'y.')
text(C(5,1),C(5,2),['[' num2str(round(C(5,1))) ', ' num2str(round(C(5,2))) ']'],'FontSize',17,'VerticalAlignment','bottom','HorizontalAlignment','right')
plot(anchory(find(idx==6),1),anchory(find(idx==6),2),'m.')
text(C(6,1),C(6,2),['[' num2str(round(C(6,1))) ', ' num2str(round(C(6,2))) ']'],'FontSize',17,'VerticalAlignment','bottom','HorizontalAlignment','right')
plot(C(:,1),C(:,2),'k*','MarkerSize',10)

%% výpočet velikostí anchorů a jejich průměrného IoU

% převedení matice anotovaných dat do datastoru
imdsTrain = imageDatastore(GT{:,'name'});
bldsTrain = boxLabelDatastore(GT(:,'object'));
trainingData = combine(imdsTrain,bldsTrain);

% stanovení počtu anchorů
numAnchors = 6;

% výpočet velikostí anchorů pro daný počet a průměrného IoU
[anchorBoxes IoU] = estimateAnchorBoxes(trainingData,numAnchors);