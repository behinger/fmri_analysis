function [] = calc_spmContrast(bidsdir,subjectlist,task)
assert(iscell(subjectlist))

for SID = subjectlist
    
    spmdatadir = fullfile(bidsdir,'derivates','spm',SID{1},'ses-01','GLM',task);
    tmp = load(fullfile(spmdatadir,'SPM.mat'));
    SPM = tmp.SPM;
    % now we have to recover the column names
    names = cellfun(@(x)x{2},regexp(tmp.SPM.xX.name,'Sn\(\d*\) ','split'),'UniformOutput',0);
    
    % filter out motion (R\d) & constant. These we gonna put to 0;
    motion = regexp(names,'^R\d$','start');
    motion = cellfun(@(x)~isempty(x),motion);% get rid of cells
    constant = regexp(names,'^constant$','start');
    constant = cellfun(@(x)~isempty(x),constant);% get rid of cells
    
    setToZero = constant|motion;
    predictorNames = names(~setToZero);
    
    % Find unique ones
    [uniqueNames,~,uniqueIX] = unique(predictorNames);
    
    % go through all predictors and extract the conditions
    splitConditions = [];
    splitFactor = [];
    for p = 1:length(uniqueNames)
        splitBasisFunction = strsplit(predictorNames{p},'*');
        splitNames{p} = strsplit(splitBasisFunction{1},'_');
        for n = 1:length(splitNames{p})
            splitFactor{p,n} = strsplit(splitNames{p}{n},':');
        end
    end
    
    % find unique factors (for main effect contrast)
    [factorNames,~,namesIX] = unique(cellfun(@(x)x{1},{splitFactor{:}},'UniformOutput',0));
    namesIX = reshape(namesIX,size(splitFactor));
    % find levels of each factor and combine them to contrasts
    % e.g. for a 2x3 design:
    %[1 1 1 1 1 1] % all activation
    %[1 1 1 -1 -1 -1 ] % flashed vs. continuous
    %[1 1 -2 1 1 -2 ] % gabor vs. noise, special case due to 3 levels but ok.
    %[1 -2 1 1 -2 1  ] %
    
    uniqueContrasts = [];
    contrastNames = [];
    uniqueContrasts(1,:) = [ones(size(namesIX,1),1)];
    contrastNames{1} = 'ALL';
    
    for f = 1:length(factorNames)
        levels = cellfun(@(x)x(2),    splitFactor(namesIX == f));
        [uniqueLevels,~,levelIX] = unique(levels);
        switch length(uniqueLevels)
            case 2
                contrastLookup = [1 -1;
                                  -1 1];
            case 3
                contrastLookup = [1 1 -2;
                    1 -2 1
                    -2 1 1];
            case 4 
                contrastLookup = [0.5  0.5 0 0;
                                  1 -1 0 0;
                                  0 0 1 0;];
                
        end
        for c = 1:(size(contrastLookup,1))
            uniqueContrasts(end+1,:) = contrastLookup(c,levelIX);
            name = [];
            for ci = 1:length(contrastLookup(c,:))
                name{ci} = strjoin({num2str(contrastLookup(c,ci)),uniqueLevels{ci}},'*');
            end
            contrastNames{end+1} = strjoin(name,'+');
        end
    end

    
    
    % Now we know which unique condition gets what contrast matrix entry.
    % now we have to fill it in the big matrix
    expandedContrast = uniqueContrasts(:,uniqueIX); % for all runs
    fullcontrastMatrix = zeros(length(contrastNames),size(setToZero,2));
    fullcontrastMatrix(:,~setToZero) = expandedContrast;
    
    matlabbatch = [];
    matlabbatch{1}.spm.stats.con.spmmat = cellstr(fullfile(spmdatadir,'SPM.mat'));
    
    consess = [];
    for c = 1:length(contrastNames)
        if c == 1
            consess{1}.tcon.weights = fullcontrastMatrix(c,:);
        else
            consess{end+1}.tcon.weights = fullcontrastMatrix(c,:);
        end
        consess{end}.tcon.name = contrastNames{c};
    end
    matlabbatch{1}.spm.stats.con.consess = consess;
    spm_jobman('run',matlabbatch);
end