cfgPlot = [];
cfg.bidsdir = fullfile('/','project','3018029.10','sequence','data','pilot','bids');
cfg.project = 'sequence';

cfgPlot.task = {'sequential'};
cfgPlot.bslcorrect = [0 1];
cfgPlot.topvoxel = [0 1];
cfgPlot.tweight = 0;
cfgPlot.topvoxel = 500;
cfgPlot.TR = 2.375
subjectlist = {'sub-04'};%cfgPlot.subjectlist;



bslcorrectFun = @(x,times)bsxfun(@minus,x,trimmean(x(:,times>=-1.5 & times<=1.5),20,2)); %
bsl_statfun_trimmean = @(y,times)([trimmean(bslcorrectFun(y,times),20);bootci(500,{@(ty)trimmean(ty,20),bslcorrectFun(y,times)},'alpha',0.05)]);

statfun_trimmean = @(y)([trimmean((y),20);bootci(500,{@(ty)trimmean(ty,20),(y)},'alpha',0.05)]);

cfgPlot.layerplots = 1;
cfgPlot.save = 0;

for SID = 1:length(subjectlist)
    
    for bslcorrect =      cfgPlot.bslcorrect
        % cfgPlot.task = 'localizer';
        for task = cfgPlot.task
            for tweight = cfgPlot.tweight
                for topvoxel= cfgPlot.topvoxel
                    if tweight
                        cfgPlot.mask = 'zscore-tweight-';
                    else
                        cfgPlot.mask = 'zscore-';
                        
                    end
                    warning('multiple localizer to be implemented')
                    cfgPlot.mask = [cfgPlot.mask 'localizer*'];
                    
                    if topvoxel
                        cfgPlot.mask = [cfgPlot.mask sprintf('Topvoxels%i*',cfgPlot.topvoxel)];
                    else
                        error('to be implemented')
                        cfgPlot.mask =[cfgPlot.mask '0.01_*'];
                    end
                    
                    
                    bidspath      = fullfile(cfg.bidsdir,'%s','%s',subjectlist{SID},'ses-01');
                    path_layer= sprintf(bidspath,'derivates','tvm_layers');
                    funclist = dir(fullfile(path_layer,'timecourse',sprintf('*_task-%s_*_desc-preproc-%s_timecourse*',task{1},cfgPlot.mask)));
                    funclist = fullfile({funclist.folder},{funclist.name});
                    events = collect_events(cfg.bidsdir,subjectlist{SID});
                    onsetIX = events.trial == 1;
                    events_onset = events(onsetIX,:);
                    
                    [erb_table,times_tr] = layer_calc_erb(funclist,events_onset,cfgPlot.TR,[-3 20])
                    
                    
                    if bslcorrect
                        statfun = @(x)bsl_statfun_trimmean(x,times_tr/cfgPlot.TR);
                    else
                        statfun = statfun_trimmean;
                    end
                    %%
                    
                    tmp = strsplit(funclist{1},'_');
                    if bslcorrect
                        tmp{6} = [tmp{6} '-bsl1'];
                    end
                    descriptor = strjoin(tmp([2,3,4,6]),'_');
                    
                    descriptor_path = fullfile('plots',tmp{[2,3,4,6]});
                    if ~exist(descriptor_path,'dir')
                        mkdir(descriptor_path)
                    end
                    
                    
                    %% ROI-Split up timecourse
                    figure
                    g = gramm('x',times_tr,'y',erb_table.erb,'color',erb_table.roi);
%                     g.geom_line('alpha',0.2);
                    g.stat_summary('type',statfun,'geom',{'line','point','errorbar'},'setylim',1);
                    
                    g.set_names     ('x','Time [s]');
                    g.set_title(descriptor,'FontSize',8);
                    g.draw();
                    
                    for kAlpha = 1:length(g.results.stat_summary)
                        g.results.stat_summary(kAlpha).line_handle.Color(4) = 0.5;
                    end
                    
                    set(gcf,'Position',[ 2350         288         888         428]);
                    
                    if cfgPlot.save
                        g.export('export_path',descriptor_path,'file_type','pdf','file_name',['x-time_color-roi_' descriptor,'_plot.pdf']);
                    end
                    
                    %% Layer/ROI-Split up timecourse
                    if cfgPlot.layerplots
                        figure
                        g = gramm('x',times_tr,'y',erb_table.erb,'color',erb_table.layer);
                        % g.geom_line('alpha',0.2);
                        g.stat_summary('type',statfun,'geom',{'line','point','errorbar'},'setylim',1);
                        g.set_names('x','Time [s]');
                        g.set_title(descriptor,'FontSize',8);
                        g.facet_grid(erb_table.roi,[]);
                        
                        g.draw();
                        
                        set(gcf,'Position',[ 2350         288         888         428]);
                        if cfgPlot.save
                            g.export('export_path',descriptor_path,'file_type','pdf','file_name',['x-time_color-layer_facet-roi_' descriptor,'_plot.pdf']);
                        end
                    end
                    %% ROI-Condition split up
                    figure
                    g = gramm('x',times_tr,'y',erb_table.erb,'color',erb_table.condition);
                    %g.geom_line('alpha',0.05);
                    g.stat_summary('type',statfun,'geom',{'line','point','errorbar'},'setylim',1);
                    %                             g.stat_summary('type',statfun,'setylim',1,'geom',{'line','point','errorbar'});
                    %                     g.stat_summary('type',statfun,'setylim',1,'geom','errorbar','dodge',0.3,'width',1) ;
                    
                    
                    g.set_names('x','Time [s]');
                    g.set_title(descriptor,'FontSize',8);
                    g.facet_grid(erb_table.roi,[]);
                    
                    g.draw();
                    %                       for kAlpha = 1:length(g.results.stat_summary)
                    %                         g.results.stat_summary(kAlpha).line_handle.Color(4) = 0.5;
                    %                         g.results.stat_summary(kAlpha).point_handle.MarkerSize = 1;
                    %                     end
                    %                     set(gcf,'Position',[ 2350         288         888         428]);
                    %                     %% ROI-Condition split up
                    %                     figure
                    %                     g = gramm('x',times_tr,'y',erb_table.erb,'color',erb_table.condition);
                    %                     %g.geom_line('alpha',0.05);
                    % %                     g.stat_summary('type',statfun,'setylim',1)
                    %                             g.stat_summary('type',statfun,'setylim',1,'geom',{'line','point','errorbar'});
                    %                     g.stat_summary('type',statfun,'setylim',1,'geom','errorbar','dodge',0.3,'width',1) ;
                    %
                    %
                    %                     g.set_names('x','Time [s]')
                    %                     g.set_title(descriptor,'FontSize',8)
                    %                     g.facet_grid(erb_table.roi,[])
                    %
                    %                     g.draw();
                    %                       for kAlpha = 1:length(g.results.stat_summary)
                    %                         g.results.stat_summary(kAlpha).line_handle.Color(4) = 0.5;
                    %                         g.results.stat_summary(kAlpha).point_handle.MarkerSize = 3;
                    %                     end
                    %                     set(gcf,'Position',[ 2350         288         888         428]);
                    if cfgPlot.save
                        g.export('export_path',descriptor_path,'file_type','pdf','file_name',['x-time_color-condition_facet-roi_' descriptor,'_plot.pdf']);
                    end
                    %%
                    if strcmp(cfgPlot.task,'adaptation')
                        % ROI-Stim1/Stim2 slit up
                        
                        figure
                        %                         g = gramm('x',times_tr,'y',erb_table.erb,'color',cellfun(@(x,y)strjoin({x,y}),erb_table.stimulus1,erb_table.stimulus2,'UniformOutput',0),'linestyle',erb_table.condition);
                        g = gramm('x',times_tr,'y',erb_table.erb,'color',erb_table.stimulus1,'linestyle',erb_table.condition);
                        %g.geom_line('alpha',0.05);
                        %                       g.stat_summary('type',statfun,'setylim',1)
                        g.stat_summary('type',statfun,'geom',{'line','point','errorbar'},'setylim',1);
                        g.set_names('x','Time [s]');
                        g.set_title(descriptor,'FontSize',8);
                        g.facet_grid(erb_table.roi,[]);
                        
                        g.draw();
                        set(gcf,'Position',[ 2350         288         888         428]);
                        if cfgPlot.save
                            g.export('export_path',descriptor_path,'file_type','pdf','file_name',['x-time_color-conditionSplitup_facet-roi_' descriptor,'_plot.pdf']);
                        end
                        
                    end
                    %%
                    if cfgPlot.layerplots
                        %%Roi-Condition-layer
                        figure
                        g = gramm('x',times_tr,'y',erb_table.erb,'color',erb_table.condition);
                        % g.geom_line('alpha',0.2);
                        g.stat_summary('type',statfun,'geom',{'line','point','errorbar'},'setylim',1);
                        g.set_names('x','Time [s]');
                        g.set_title(descriptor,'FontSize',8);
                        g.facet_grid(erb_table.roi,erb_table.layer);
                        
                        g.draw();
                        
                        set(gcf,'Position',[ 2350         288         888         428]);
                        if cfgPlot.save
                            g.export('export_path',descriptor_path,'file_type','pdf','file_name',['x-time_color-condition_facet-roi-layer_' descriptor,'_plot.pdf']);
                        end
                        
                    end
                    %%
                    if cfgPlot.layerplots && ~cfgPlot.bslcorrect
                        %% Layer: condition,roi
                        [~,t_ix] = min(abs(times_tr - 5)); % closest to 5s
                        figure
                        g = gramm('x',erb_table.layer,'y',erb_table.erb(:,t_ix),'color',erb_table.condition);
                        % g.geom_line('alpha',0.2);
                        g.stat_summary('type',statfun_trimmean,'geom',{'line','point','errorbar'},'setylim',1);
                        g.set_names('x','Layer (WM to CSF)');
                        g.set_title(descriptor,'FontSize',4);
                        g.facet_grid(erb_table.roi,[]);
                        
                        g.draw();
                        
                        set(gcf,'Position',        [2350         288         259         428]);
                        if cfgPlot.save
                            g.export('export_path',descriptor_path,'file_type','pdf','file_name',['x-layer_color-condition_facet-roi_' descriptor,'_plot.pdf']);
                        end
                        
                    end
                    %%
                    close all
                end
            end
        end
    end
end





%%  After we did all the work, reorder the plots

allpdf = dir(fullfile('plots','**','*.pdf'));

for d = 1:length(allpdf)
    fprintf('Copying %i/%i\n',d,length(allpdf))
    currd = allpdf(d);
    split = strsplit(currd.name,'_');
    ix_plotlabelend = find(cellfun(@(x)strcmp(x(1:4),'sub-'),split));
    %%
    % This script updates sam Lawrence Attention project (~28 subjects) to
    % the bids-data structure we use in the other projects
    % Then we call the coregistration visualization tools to make movies!
    %
    try
        run('code/setup_paths') % init paths and stuff
    end
    
    
    cfg = [];
    cfgPlot.autoRun = 0;
    cfgPlot.project = 'sam_coregistrations';
    cfgPlot.bidsdir = fullfile('/','project','3018029.10','sam_coregistrations','data','bids');
    cfgPlot.scriptdir = fullfile(pwd,'code');
    
    
    %% Generate the links
    
    %Generate folder
    if ~exist(cfgPlot.bidsdir,'dir')
        mkdir(cfgPlot.bidsdir)
    end
    attentiondir = '/project/3018028.04/SubjectData/';
    whatSubjectsExist = dir([attentiondir 'S*']);
    whatSubjectsExist = whatSubjectsExist([whatSubjectsExist.isdir]); % remove non-folders
    whatSubjectsExist = {whatSubjectsExist.name};
    for sub = whatSubjectsExist
        frompath = fullfile(attentiondir,sub{1},'Attention');
        topath = fullfile(cfgPlot.bidsdir,'derivates','preprocessing',['sub-' sub{1}(2:end)],'ses-01');
        % We make it modular in case I need other files later in bids format as
        % well
        moveStruct(1).from = fullfile(frompath,'Coregistrations','Anat2FuncBoundaries_recurs.mat');
        moveStruct(1).to   = fullfile(topath,'coreg',sprintf('sub-%s_ses-01_from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface.mat',sub{1}(2:end)));
        moveStruct(2).from = fullfile(frompath,'Niftis','Realigned','meanATTN_run1.nii');
        moveStruct(2).to   = fullfile(topath,'func',sprintf('sub-%s_ses-01_task-attention_desc-occipitalcropMeanBias_bold.nii',sub{1}(2:end)));
        for file = 1:length(moveStruct)
            if ~exist(fileparts(moveStruct(file).to),'dir')
                mkdir(fileparts(moveStruct(file).to))
            end
            [status,cmdout] = system(sprintf('ln -s %s %s',moveStruct(file).from,moveStruct(file).to));
            if status ~=0
                warning(cmdout)
            end
        end
        %     system
        
    end
    % ln -s /project/3018028.04/SubjectData/S01/Attention/Coregistrations/Anat2FuncBoundaries_recurs.mat
    % coreg/sub-01_ses-01_from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface.mat
    % ln -s /project/3018028.04/SubjectData/S01/Attention/Niftis/Realigned/meanATTN_run1.nii
    % func/sub-01_ses-01_task-attention_desc-occipitalcropMeanBias_bold.nii
    %%
    for sub = whatSubjectsExist(1:5)
        fprintf('making movies from sub %s\n',sub{1})
        subStr = {sprintf('sub-%s',sub{1}(2:end))};
        vis_surfaceCoregistration(cfgPlot.bidsdir,subStr,'task','attention','method','movie','boundaries',{'_desc-recursive_mode-surface'},...
            'axis','transversal')
        vis_surfaceCoregistration(cfgPlot.bidsdir,subStr,'task','attention','method','movie','boundaries',{'_desc-recursive_mode-surface'},...
            'axis','coronal')
        vis_surfaceCoregistration(cfgPlot.bidsdir,subStr,'task','attention','method','movie','boundaries',{'_desc-recursive_mode-surface'},...
            'axis','sagittal')
    end
    ix_desc  = find(cellfun(@(x)strcmp(x(1:5),'desc-'),split));
    
    splitdesc = strsplit(split{ix_desc},'-');
    ix_desc_localizer = cellfun(@(x)~isempty(x),strfind(splitdesc,'localizer'));
    
    ix_task = find(cellfun(@(x)strcmp(x(1:5),'task-'),split));
    
    folder = fullfile('plots_byType',strjoin(split(1:ix_plotlabelend-1),'_'),splitdesc{ix_desc_localizer},split{ix_desc}(6:end),split{ix_task}(6:end));
    
    name   = strjoin([split(ix_plotlabelend:end-1) split(1:ix_plotlabelend-1) {'plot.pdf'}],'_');
    if ~exist(folder,'dir')
        mkdir(folder)
    end
    
    system(sprintf('cp %s %s',fullfile(currd.folder,currd.name),fullfile(folder,name)));
end
