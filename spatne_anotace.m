% načtení matice anotovaných trénovacích dat
cesta = 'C:\Users\Barborka\Desktop\škola\DP\';
load([cesta 'data\train\224\GTtrain.mat']);

% pro každý obraz
for i = 1:8000
    % zjištění počtu objektů v obraze
    object = GT.object(i);
    num_object = size(object{1},1);
    
    % pokud je objekt pouze jeden
    if num_object == 1      
        % pokud má objekt větší velikost než 100x150, pak se načte a
        % zobrazí i s vyznačeným boxem pro následné subjektivní porovnání
        if (object{1}(3)>150 && object{1}(4)>100) || (object{1}(3)>100 && object{1}(4)>150)
            obr = imread([cesta 'data\train\224\' num2str(i.','%05d') '.jpg']);
            RGB = insertShape(obr,'Rectangle',object{1},'Color', 'green','Opacity',0.7,'LineWidth',5);
            figure
            imshow(RGB);
            title(num2str(i))
        end   
    end
end