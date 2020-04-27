function calc_spm2ndLevel(bidsdir,subjectlist,events,varargin)

cfg = finputcheck(varargin, ...
    {
    'task'             'string',   {},    [];... % rois from benson17 (V1=1,V2=2,V3=3)
    'TR','real',[],[];
    'smooth','boolean',[],0;...
    'duration','real',[],[];
    'conditions','cell',[],{'condition','contrast'} % specifies the factorial design
    'recalculate', 'boolean',[],1;... % always recalculate only if not specified otherwise
    });

if ischar(cfg)
    error(cfg)
end

assert(~isempty(cfg.TR))
assert(iscell(subjectlist))
assert(istable(events));
assert(all(ismember(cfg.conditions,events.Properties.VariableNames)))
for SID = subjectlist
    
    
    SID = SID{1};
    
    
    niftis = [dir(fullfile(bidsdir,'derivates','preprocessing',SID,'ses-01','func',sprintf('*task-%s*run-*Realign_bold.nii',cfg.task)))];
    
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
    
    
    spmdatadir = fullfile(bidsdir,'derivates','spm',SID,'ses-01','GLM',events.task{1});
    
    
    fmri_spec = struct;
    fmri_spec.dir = cellstr(spmdatadir);
    fmri_spec.timing.units = 'secs';
    fmri_spec.timing.RT= cfg.TR;
    fmri_spec.bases.hrf.derivs = [1 0]; % temporal derivation
    
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
            
            
            onsets = events{ix,'onset'};
            if isempty(onsets)
                warning(sprintf('No events found for run %i, name:%s',run,name(2:end)))
                continue
            end
            
            
            
            
            if ~isfield(fmri_spec,'sess') || (run>1 && length(fmri_spec.sess) == run-1)
                %                         fmri_spec.sess(run).cond = []
                fmri_spec.sess(run).cond.name = name(2:end);
            else
                fmri_spec.sess(run).cond(end+1).name = name(2:end);
            end
            
            fmri_spec.sess(run).cond(end).onset =  onsets;
            fmri_spec.sess(run).cond(end).duration = events{ix,'duration'};
            fmri_spec.sess(run).multi_reg = {fullfile(niftis(run).folder,'../','motion',sprintf('%s_ses-01_task-%s_run-%i_from-run_to-mean_motion.txt',SID,cfg.task,run))};
            fmri_spec.sess(run).scans = {fullfile(niftis(run).folder,niftis(run).name)};
            fmri_spec.sess(run).hpf = 128;
               

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
    if cfg.smooth ==1
    
    spatial.smooth.data = {fmri_spec.sess(:).scans{:}};
    for run = 1:length(fmri_spec.sess)
        for i = 1:length(fmri_spec.sess(run).scans)
            [fp,fn,ext] = fileparts(fmri_spec.sess(run).scans{i});
            fmri_spec.sess(run).scans{i} = fullfile(fp,['s_' fn ext]);
        end
    end
    
    spatial.smooth.fwhm   = [2 2 2];
    spatial.smooth.dtype  = 0; % output data type = same as input
    spatial.smooth.im     = 0; % no implicit masking
    spatial.smooth.prefix = 's_';
    
    matlabbatch{end+1} = struct('spm',struct('spatial',spatial));
    end
    
    matlabbatch{end+1} = struct('spm',struct('stats',struct('fmri_spec',fmri_spec)));
    tmp = struct;
    tmp.stats.fmri_est.spmmat = cellstr(fullfile(spmdatadir,'SPM.mat'));
    matlabbatch{end+1} = struct('spm',tmp);
    
    % Generate the designmatrices + Fit them!
    spm_jobman('run',matlabbatch);
    % recommended to run  calc_spmContrast now
    
end
end
