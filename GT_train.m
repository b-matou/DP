% cesta ke složce a načtení matice s názvy obrázků a označenými objekty
cesta = 'C:\Users\Matous\Documents\DP\';
load([cesta 'train.mat']);

% vytvoření tabulky GT pro uložení matice anotovaných dat
GT = table('Size',[8000,2],'VariableTypes',{'cell','cell'});

% for cyklus pro všechny obrázky ze skupiny trénovacích dat
for i = 1:8000
    % přeuložení názvu do tabulky GT spolu s cestou k novému obrázku
    nazev = char(train{i,1}(1,1));
    GT{i,1} = {char(strcat([cesta 'train\224\'],nazev(1:end-4),'.png'))};
    
    % načtení původního obrázku
    img = imread(char(strcat([cesta 'train\'],nazev)));
    
    % převedení obrázku do double, přeškálování na velikost 224x224 dle
    % potřeby vstupu do předtrénované sítě a normalizace do rozmezí <0,1>
    img = im2double(img);
    resized = imresize(img,[224 224]);
    new = rescale(resized,0,1);
    
    % úprava původního obrazu pomocí CLAHE, přeškálování na velikost
    % 224x224 dle potřeby vstupu do předtrénované sítě, normalizace do
    % rozmezí <0,1> a uložení do druhé vrstvy nového obrazu
    adapt = adapthisteq(img);
    resized2 = imresize(adapt,[224 224]);
    new(:,:,2) = rescale(resized2,0,1);
    
    % úprava původního obrazu pomocí ekvalizace histogramu, přeškálování 
    % na velikost 224x224 dle potřeby vstupu do předtrénované sítě, 
    % normalizace do rozmezí <0,1> a uložení do třetí vrstvy nového obrazu
    eq = histeq(img);
    resized3 = imresize(eq,[224 224]);
    new(:,:,3) = rescale(resized3,0,1);
    
    % uložení nového obrazu
    imwrite(new,strcat([cesta 'train\224\'],nazev(1:end-4),'.png'));
    
    % vypočtení zmenšení obrazu
    scale = [224 224]./size(img,[1 2]);
    
    % nalezení počtu objektů v obraze
    num_object = sum(~cellfun(@isempty,train(i,2:end)));
    
    % pro všechny obrazy, kde je alespoň jeden objekt
    if num_object > 0
        % proměnná pro uložení umístění jednotlivých objektů
        object = zeros(num_object,4);
        
        % pro každý objekt
        for j = 1:num_object
            % souřadnice bodů objektu
            points = train{i,j+1};
            
            % rozdělení přepočtu bodů dle tvaru původního objektu
            % 0-obdélník, 1-elipsa, 2-polygon
            
            % pro obdélník a elipsu se uloží souřadnice levého horního rohu
            % a dále se vypočte šířka a výška boxu
            if points(1) == 0 || points(1)==1
                new_points = [points(2:3), points(4)-points(2), points(5)-points(3)];
            % pro polygon se najdou nejmenší hodnoty souřadnice pro obě dimenze
            % všech bodů a pomocí největších hodnot souřadnic se vypočte
            % opět šířka a výška boxu
            else
                rows = points(2:2:end);
                columns = points(3:2:end);
                new_points = [min(rows), min(columns), max(rows)-min(rows), max(columns)-min(columns)]; 
            end
            
            % pokud je box začíná mimo obraz, box se zmenší na počátek
            % obrazu
            if ~isempty(find(new_points<=0))
                new_points(find(new_points<=0)) = 1;
            end
            
            % pokud box přesahuje šířku obrazu, upraví se konec boxu
            % na okraj obrazu
            if new_points(1)+new_points(3)>size(img,2)
                new_points(3) = size(img,2)-new_points(1);
            end
            
            % pokud box přesahuje výšku obrazu, upraví se konec boxu
            % na okraj obrazu
            if new_points(2)+new_points(4)>size(img,1)
                new_points(4) = size(img,1)-new_points(2);
            end
            
            % upravení pozice boxu podle zmenšení nového obrazu
            new_points = bboxresize(new_points,scale);
            
            % uložení upravených bodů boxu do proměnné
            object(j,:) =  new_points;
        end
        % uložení pozic boxů do matice anotovaných dat
        GT{i,2} = {object};
    end
end

% pojmenování sloupců matice anotovaných dat
GT.Properties.VariableNames = {'name','object'};

% zobrazení jednoho obrazu pro kontrolu správnosti
obr = imread([cesta 'data\train\224\00012.jpg']);
RGB = insertShape(obr,'Rectangle',GT{12,2}{1,1},'Color', 'green','Opacity',0.7,'LineWidth',5);
imshow(RGB);

% uložení matice anotovaných dat pro trénovací obrazy
save([cesta 'train\224\GTtrain.mat'],'GT');