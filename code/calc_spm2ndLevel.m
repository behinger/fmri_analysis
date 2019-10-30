function calc_spm2ndLevel(datadir,subjectlist,varargin)

cfg = finputcheck(varargin, ...
    {
    'task'             'string',   {'sequential','sustained'}    [];... % rois from benson17 (V1=1,V2=2,V3=3)
    'TR','real',[],[];
    'conditions','cell',[],{'condition','contrast'} % specifies the factorial design
    'recalculate', 'boolean',[],1;... % always recalculate only if not specified otherwise
    });

if ischar(cfg)
    error(cfg)
end

assert(iscell(subjectlist))

for SID = subjectlist
    
    
    SID = SID{1};
    
    events = collect_events(datadir,SID);
    
    if cfg.task == "sustained"
        % we need to find the block onset
        stimOnsetIX = find(events.message == "stimOnset");
        onsetIX = diff(events{stimOnsetIX,'block'}) == 1;
        onsetIX = [1; stimOnsetIX(find([0; onsetIX]))];
        events.blockOnset = zeros(size(events,1),1);
        events.blockOnset(onsetIX) = 1; % to mark the onset
        if SID == "sub-05"
            % fix inconsistency during recording
            ix = events.subject == 5;
            events.run(ix)  = events.run(ix) + 1;
        end
    end
    niftis = [dir(fullfile(datadir,'derivates','preprocessing',SID,'ses-01','func',sprintf('*task-%s*run-*Realign_bold.nii',cfg.task)))];
    
    % bit weird if-combination but its late, should work [I mean I myself shouldnt be working] :)
    if isempty(cfg.TR)
        
        if cfg.task=="sequential" && SID== "sub-04"
            cfg.TR = 2.336;
        elseif cfg.task == "sequential"
            cfg.TR = 1.5;
        else
            
            error('please implement TR or read it from bids somehow?')
        end
    end
    %% generate condition
    conditionLevels = [];
    ndgridInput = {};
    
    for c = cfg.conditions
        nlevels = length(unique(events.(c{1})));
        conditionLevels = [conditionLevels {unique(events.(c{1}))}];
        ndgridInput{end+1} = 1:nlevels;
    end
    
    combinations = ndgrid_cell(ndgridInput{:});
    %     combis = cell2mat(combinations)
    %     combis(:,:)
    %% SPM
    % Run it once for all trials. Not sure why we would need one GLM per
    % run?
    for run_ix = 0%:8
        if run_ix == 0
            
            spmdatadir = fullfile(datadir,'derivates','spm',SID,'ses-01','GLM','run-all');
        else
            spmdatadir = fullfile(datadir,'derivates','spm',SID,'ses-01','GLM',sprintf('run-%i',run_ix));
        end
        
        fmri_spec = struct;
        fmri_spec.dir = cellstr(spmdatadir);
        fmri_spec.timing.units = 'secs';
        fmri_spec.timing.RT= cfg.TR;
        
        if run_ix == 0
            % 0 is all runs
            for run = unique(events.run)'
                
                % for each combination of conditions
                for ci = 1:numel(combinations{1})
                    % find the onsets
                    name = '';
                    ix  = ones(size(events,1),1);
                    for c = 1:length(cfg.conditions)
                        if isstr(events{1,cfg.conditions{c}}{1})
                            ix = ix & strcmp(events.(cfg.conditions{c}),conditionLevels{c}{combinations{c}(ci)});
                        else
                            ix = ix & events.(cfg.conditions{c}) == conditionLevels{c}(combinations{c}(ci));
                        end
                        name = [name '_' cfg.conditions{c} ':' conditionLevels{c}{combinations{c}(ci)}];
                    end
                    
                    
                    assert(sum(ix)~=0,'error event combination does not exist, could possible be exchanged for a warning though, if you know what you are doing')
                    
                    %subselect a single run
                    ix = ix & events.run == run;
                    
                    
                    if cfg.task == "sustained"
                        % take only block onsets :-)
                        ix = ix& events.blockOnset == 1;
                    end
                    onsets = events{ix,'onset'};
                    if isempty(onsets)
                        continue
                    end
                    
                    
                    
                    
                    
                    fmri_spec.sess(run).cond(ci).name = name(2:end);
                    
                    fmri_spec.sess(run).cond(ci).onset =  onsets;
                    fmri_spec.sess(run).cond(ci).duration = repmat(16,size(fmri_spec.sess(run).cond(ci).onset));
                    fmri_spec.sess(run).multi_reg = {fullfile(niftis(run).folder,'../','motion',sprintf('%s_ses-01_task-%s_run-%i_from-run_to-mean_motion.txt',SID,cfg.task,run))};
                    fmri_spec.sess(run).scans = {fullfile(niftis(run).folder,niftis(run).name)};
                    
                end
            end
            
            
        else
            fmri_spec.sess.cond.name = 'Stimulus';
            fmri_spec.sess.cond.onset =  events{events.run== run_ix & events.message=="stimOnset"&events.trial==1,'onset'}';
            fmri_spec.sess.cond.duration = repmat(16,size(fmri_spec.sess.cond.onset));
            fmri_spec.sess.scans = {fullfile(niftis(run_ix).folder,niftis(run_ix).name)};
            fmri_spec.cvi = 'AR(1)';
        end
    end
    if exist(fullfile(spmdatadir,'spmT_0001.nii'),'file')
        if ~cfg.recalculate
            warning('Old results found, will not recalculate')
            continue
        else
            warning('Old results found, folder deleted & starting recalculation')
            rmdir(spmdatadir,'s')
        end
    end
    matlabbatch = [];
    if ~exist(spmdatadir,'dir')
        mkdir(spmdatadir);
    end
    matlabbatch{1} = struct('spm',struct('stats',struct('fmri_spec',fmri_spec)));
    tmp = struct;
    tmp.stats.fmri_est.spmmat = cellstr(fullfile(spmdatadir,'SPM.mat'));
    matlabbatch{2} = struct('spm',tmp);
    
    % Contrasts
    %--------------------------------------------------------------------------
    

    nruns = length(unique(events.run));
    nconditions = length(fmri_spec.sess(1).cond);
    % stim vs. baseline [ ncond x1  nmotionReg x 0 nrun x 0]
%     matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [repmat([repmat(1,1,nconditions), repmat(0,1,6)],1,nruns) zeros(1,nruns);];    
%     matlabbatch{3}.spm.stats.con.spmmat = cellstr(fullfile(spmdatadir,'SPM.mat'));
%     matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Stim > Rest';
%     
    % simple effect
%     warning('not all stuff is implemented, i.e. main effects missing, interactions etc.')
%     for c = 1:length(cfg.conditions)
%         ref = combinations{c} == 1;
%         ref = ref(:)*2 -1; % flattening & effect coding
%         matlabbatch{3}.spm.stats.con.consess{end+1}.tcon.weights = [repmat([ref', repmat(0,1,6)],1,nruns) zeros(1,nruns)];
%         matlabbatch{3}.spm.stats.con.spmmat = cellstr(fullfile(spmdatadir,'SPM.mat'));
%         matlabbatch{3}.spm.stats.con.consess{end}.tcon.name = [cfg.conditions{c} ':' conditionLevels{c}{1} ' vs. others'];
%     end
    % Call script to set up design
    spm_jobman('run',matlabbatch);
end
end