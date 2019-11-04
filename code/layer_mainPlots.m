bidsdir = cfg.bidsdir;
subjectlist = {'sub-04'};%cfg.subjectlist;



bslcorrect = @(x)bsxfun(@minus,x,trimmean(x(:,times_tr/TR>=-1.5 & times_tr/TR <=1.5),20)); %
bsl_statfun_trimmean = @(y)([trimmean(bslcorrect(y),20);bootci(500,{@(ty)trimmean(ty,20),bslcorrect(y)},'alpha',0.05)]);

statfun_trimmean = @(y)([trimmean((y),20);bootci(500,{@(ty)trimmean(ty,20),(y)},'alpha',0.05)]);

cfgPlot = [];
cfgPlot.layerplots = 1;
cfgPlot.save = 1;

for SID = 1:length(subjectlist)
    
    for bslcorrect = 0:1;
        cfgPlot.bslcorrect
        % cfgPlot.task = 'localizer';
        for task = {'localizer','adaptation'}
            cfgPlot.task = task{1};
            
            for tweight = 0:1
                for topvoxel= 0:1
                    for localizer={'AllGtrBase','45Gtr135','135Gtr45'}
                        %%
                        cfgPlot.tweight = tweight;
                        cfgPlot.topvoxel = topvoxel;
                        if cfgPlot.tweight
                            cfgPlot.mask = '-t*';
                        else
                            cfgPlot.mask = '-l*';
                            
                        end
                        cfgPlot.mask = [cfgPlot.mask localizer{1} '*'];
                        
                        if cfgPlot.topvoxel
                            cfgPlot.mask = [cfgPlot.mask 'topVoxels*'];
                        else
                            cfgPlot.mask =[cfgPlot.mask '0.01_*'];
                        end
                        
                        if cfgPlot.bslcorrect
                            statfun = bsl_statfun_trimmean;
                        else
                            statfun = statfun_trimmean;
                        end
                        bidspath      = fullfile(bidsdir,'%s','%s',subjectlist{SID},'ses-01');
                        path_layer= sprintf(bidspath,'derivates','tvm_layers');
                        funclist = dir(fullfile(path_layer,'timecourse',sprintf('*_task-%s_*_desc-preproc-zscore%s_timecourse*',cfgPlot.task,cfgPlot.mask)));
                        funclist = {funclist.name};
                        
                        [erb_table,times_tr] = layer_erb(cfgPlot,bidsdir,subjectlist,SID);
                        
                        %%
                        
                        tmp = strsplit(funclist{1},'_');
                        if cfgPlot.bslcorrect
                            tmp{5} = [tmp{5} '-bsl1'];
                        end
                        descriptor = strjoin(tmp([1,2,3,5]),'_');
                        
                        descriptor_path = fullfile('plots',tmp{[1,2,3,5]});
                        if ~exist(descriptor_path,'dir')
                            mkdir(descriptor_path)
                        end
                        
                        
                        %% ROI-Split up timecourse
                        figure
                        g = gramm('x',times_tr,'y',erb_table.erb,'color',erb_table.roi);
                        % g.geom_line('alpha',0.2);
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
    
    
end


%%  After we did all the work, reorder the plots

allpdf = dir(fullfile('plots','**','*.pdf'));

for d = 1:length(allpdf)
    fprintf('Copying %i/%i\n',d,length(allpdf))
    currd = allpdf(d);
    split = strsplit(currd.name,'_');
    ix_plotlabelend = find(cellfun(@(x)strcmp(x(1:4),'sub-'),split));
    
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
