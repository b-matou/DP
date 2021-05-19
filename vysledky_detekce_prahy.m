%% nalezení detekovaných objektů pro různé prahy
% načtení natrénovaného detektoru
load('detector14.5.mat');

% načtení matice anotovaných dat
load('test\224\GTtest.mat');

% vytvoření datastoru pro testovací data
imdsTest = imageDatastore(GT{:,'name'});
bldsTest = boxLabelDatastore(GT(:,'object'));
testData = combine(imdsTest,bldsTest);

% nastavení prahu na 0,5
prah = 0.5;

% for cyklus pro 3 různé prahy
for i = 1:3
    % vytvoření výsledných detekcí pro daný prah bez odstranění
    % překrývajících se boxů
    detectionResults{i} = detect(detector,testData,'MinibatchSize',8,'Threshold',prah,'SelectStrongest',false);
    % vytvoření matice s výsledky
    detectionResultsArr = table2array(detectionResults{i});
    % pro každý obrázek se odstraní překrývající se boxy s jakýmkoliv jiným
    % na víc než 10% a zůstane pouze ten s největším skóre
    for j = 1:1000
        [detectionResults{i}.Boxes{j},detectionResults{i}.Scores{j}] = selectStrongestBbox(detectionResultsArr{j,1},detectionResultsArr{j,2},'OverlapThreshold',0.1);
    end
    % zvýšení prahu
    prah = prah+0.05;
end

%% nalezení nejlepšího prahu
% pro každý prah
for j = 1:3
    % vytvoření proměnných
    TP = [];
    FP = [];
    FN = [];
    FP_bezanotace = [];
    
    % pro každý obraz
    for i = 1:1000
        % vytvoří se matice překryvů nalezených a anotovaných objektů,
        % metrikou je překrývající se plocha podělená plochou menšího
        % objektu
        overlapRatio = bboxOverlapRatio(detectionResults{j}{i,1}{1},GT{i,2}{1},'Min');
        % nalezne se, které překryvy jsou větší než 30%, ty jsou
        % vyhodnocené jako shodné objekty
        overlapRatio = overlapRatio>0.3;
        
        % pokud se nevyskytuje žádný anotovaný objekt, vyhodnotí se pouze
        % FP do vektoru obrazů bez cizího objektu
        if size(overlapRatio,2)==0
            FP_bezanotace = [FP_bezanotace size(overlapRatio,1)];
        % pokud se nenalezl žádný objekt, vyhodnotí se TP, FP a FN
        elseif size(overlapRatio,1)==0
            TP = [TP 0];
            FP = [FP 0];
            FN = [FN size(overlapRatio,2)];
        % pokud se naleznou objekty a zároveň jsou anotované objekty,
        % vypočte se TP, FP a FN podle matice překryvů, toto řešení bere v
        % potaz i případy, kdy jeden box překrývá více boxů
        else
            FN = [FN sum(sum(overlapRatio,1)==0)]; 
            FP = [FP sum(sum(overlapRatio,2)==0)];
            TP = [TP size(overlapRatio,2)-FN(end)];
        end
    end
    % vytvoření celkového počtu TP, FP a FN pro snímky s objekty pro každý
    % detektor
    sumTP(j) = sum(TP);
    sumFP(j) = sum(FP);
    sumFN(j) = sum(FN);
    
    % nahrazení precision 0, kde je NaN, a vytvoření precision a recall pro
    % každý snímek
    precision = TP./(TP+FP);
    precision(isnan(precision)) = 0;
    recall = TP./(TP+FN);
    F1 = 2*precision.*recall./(precision+recall);
    F1(isnan(F1)) = 0;
    
    % průměr hodnot precision a recall ze všech snímků s cizími objekty a
    % vypočtení hodnoty F1
    avPrecision(j) = mean(precision);
    avRecall(j) = mean(recall);
    avF1(j) = mean(F1);
    
    % vypočtení průměrného FP na snímek pro snímky s cizími objekty a bez
    % cizích objektů zvlášť
    FP2(j) = sum(FP_bezanotace)/length(FP_bezanotace);
    FP2_s(j) = sumFP(j)/length(FP);
end

% vytvoření tabulky pro všechny prahy se všemi statistikami
porovnani = table('Size',[8,3],'VariableTypes',{'double','double','double'},'VariableNames',{'0.5','0.55','0.6'},'Rownames',{'sumTP','sumFP','sumFN','FP_s','precision','recall','F1','FP_bez'});
porovnani{1:8,1:3} = [sumTP;sumFP;sumFN;FP2_s;avPrecision;avRecall;avF1;FP2]

% nalezení nejlepšího prahu pro detektor

% pokud není rozdíl FP při posunutí prahu alespoň 10x větší než rozdíl FN,
% pak se prah nezvýší
if 10*(sumFN(2)-sumFN(1)) > (sumFP(1)-sumFP(2))
    best = 0.5;
    prah = 1;
else
    % pokud není rozdíl FP při posunutí prahu alespoň 10x větší než rozdíl FN,
    % pak se prah nezvýší
    if 10*(sumFN(3)-sumFN(2)) < (sumFP(2)-sumFP(3))
        best = 0.6;
        prah = 3;
    else
        best = 0.55;
        prah = 2;
    end
end

disp(['Nejlepší práh detekce: ' num2str(best)])

%% detailnější zhodnocení výsledků
TP = [];
FP = [];
FN = [];
FP_bezanotace = [];

% pro každý obraz
for i = 1:1000
    % vytvoří se matice překryvů nalezených a anotovaných objektů,
    % metrikou je překrývající se plocha podělená plochou menšího
    % objektu
    overlapRatio = bboxOverlapRatio(detectionResults{prah}{i,1}{1},GT{i,2}{1},'Min');
    % nalezne se, které překryvy jsou větší než 30%, ty jsou
    % vyhodnocené jako shodné objekty
    overlapRatio = overlapRatio>0.3;

    % pokud se nevyskytuje žádný anotovaný objekt, vyhodnotí se pouze
    % FP do vektoru obrazů bez cizího objektu
    if size(overlapRatio,2)==0
        FP_bezanotace = [FP_bezanotace size(overlapRatio,1)];
    % pokud se nenalezl žádný objekt, vyhodnotí se TP, FP a FN
    elseif size(overlapRatio,1)==0
        TP = [TP 0];
        FP = [FP 0];
        FN = [FN size(overlapRatio,2)];
    % pokud se naleznou objekty a zároveň jsou anotované objekty,
    % vypočte se TP, FP a FN podle matice překryvů, toto řešení bere v
    % potaz i případy, kdy jeden box překrývá více boxů
    else
        FN = [FN sum(sum(overlapRatio,1)==0)]; 
        FP = [FP sum(sum(overlapRatio,2)==0)];
        TP = [TP size(overlapRatio,2)-FN(end)];
    end
end

% nahrazení precision 0, kde je NaN, a vytvoření precision a recall pro
% každý snímek
precision = TP./(TP+FP);
precision(isnan(precision)) = 0;
recall = TP./(TP+FN);
F1 = 2*precision.*recall./(precision+recall);
F1(isnan(F1)) = 0;

% průměr a rozptyl hodnot precision a recall ze všech snímků s cizími objekty
avPrecision = mean(precision);
avRecall = mean(recall);
avF1 = mean(F1); 
stdPrecision = std(precision);
stdRecall = std(recall);
stdF1 = std(F1);

% zobrazení boxplotu
figure
boxplot([precision',recall',F1'],'Labels',{'Přesnost','Výtěžnost','F1 skóre'},'Whisker',1);
