
try
    run('code/setup_paths') % init paths and stuff
end


cfg = [];
cfg.autoRun = 0;
cfg.project = 'wm';
cfg.bidsdir = fullfile('/','project','3018012.20','data','pilot','bids');
cfg.scriptdir = fullfile(pwd,'code');

cfg.subjectlist = {'sub-91'};

% Functions for GRID/cluster evluation
cfg.loopfun = @(cfg)['cd ' cfg.scriptdir ';export subjectlist="'  strjoin(cfg.subjectlist),'"; export bidsdir="' cfg.bidsdir '";'];
cfg.gridpipe_long_4cpu = sprintf('| qsub -l "nodes=1:ppn=4,walltime=22:00:00,mem=12gb" -o %s',fullfile(cfg.bidsdir,'logfiles/'));
cfg.gridpipe_long = sprintf('| qsub -l "nodes=1:walltime=22:00:00,mem=4GB,procs=1" -o %s',fullfile(cfg.bidsdir,'logfiles/'));
cfg.gridpipe_short = sprintf('| qsub -l "nodes=1:walltime=5:00:00,mem=4GB,procs=1" -o %s',fullfile(cfg.bidsdir,'logfiles/'));


cfg.loopeval = cfg.loopfun(cfg); % export variables and dirs


if ~cfg.autoRun
    error('stopped on purpose') % stop the script here to not autorun :)
end
%%

% In case of 7T reconstruct subjectlist
% calc_CAIPI7tReconstruction(fullfile(cfg.bidsdir,'../','recon'),cfg.subjectlist) % run on cluster, returns

%%

cfg.phase = 'preprocessing';
cfg.step = [1:2]; % Copy Anaotmical + run freesurfer => Cluster
cfg.step = [4] % realignFunctions => TODO:cluster
cfg.step = [3] % Manually Crop cortex
cfg.step = [5:7] % after Freesurfer is finished (step 2), calculate GM/WM boundaries => Partially on cluster

% Careful, currently both functions (via cropped anatomical and via fulll functional) are active. XXX todo
cfg.step = [8 10 11]; % align anatomical with functional for V1 ROI, calculate ROI, map ROI

cfg.step = 9; %visually check corregistration of boundaries
%XXX Todo: Visually check realignment using "theplot"

cfg.step = [2 4]

%% Phase 1
if strcmp(cfg.phase,'preprocessing')
    % path modifications
   %% 
    for step =cfg.step
      
        switch step
            case 2
                % Segment Anatomical
                % recon-all to segment
                for SID =cfg.subjectlist
                    %locally
                    [~,out] = system([cfg.loopeval 'export SID="' SID{1} '";./calc_freesurfer_reconAll.sh'],'-echo');
                    % runs parrallel with freesurfer 6
%                     [~,out] = system(['echo ''' cfg.loopeval 'export SID="' SID{1} '";./calc_freesurfer_reconAll.sh''' cfg.gridpipe_long_4cpu],'-echo'); 
                end
            case 3
                % crop the occipital cortex
                % input needed how to best save coordinates for croping to
                
                f_cropmark = fullfile(cfg.bidsdir,'derivates','preprocessing','cropmarks_occipital.mat');
                
                for SID = cfg.subjectlist
                    if exist(f_cropmark,'file')
                        crop = load(f_cropmark);
                        crop = crop.crop;
                    else
                        crop = table({},[],[],'VariableNames',{'SID','anat','func'});
                    end
                    
                    ix = find(strcmp(SID{1},crop.SID));
                    if ~isempty(ix)
                        t_sub = crop(ix,:);
                    else
                        d = dir(fullfile(cfg.bidsdir,SID{1}, 'ses-01','anat',[SID{1} '_ses-01_*_T1w.nii']));
                        spm_image('display',fullfile(d.folder,d.name))
                        tmp_a = input('Subject not found, adding it to table. Anat {X:X, Y:Y, Z:Z}:');
                        
                        d = dir(fullfile(cfg.bidsdir,SID{1}, 'ses-01','func',[SID{1} '_ses-01_*_bold.nii']));
                        spm_image('display',fullfile(d(1).folder,d(1).name))
                        
                        tmp_f = input('Subject not found, adding it to table. Func {X:X, Y:Y, Z:Z}:');
                        t_sub = table(SID(1),tmp_a,tmp_f,'VariableNames',{'SID','anat','func'});
                        
                        % concatenate to already loaded and save changes
                        crop = [crop; t_sub];
                        if ~exist(fileparts(f_cropmark),'dir')
                            mkdir(fileparts(f_cropmark))
                        end
                        save(f_cropmark,'crop')
                    end
                    calc_cropOccipital(cfg.bidsdir,SID{1},t_sub)
                    
                end
                
            case 4
                % SPM linear realign of functional scans to mean functional
                % scan. Output mean nifti
                calc_realignFunctionals(cfg.bidsdir,cfg.subjectlist)
            case 5
                % Rough alignment of mp2rage anatomical to mean functional
                calc_alignFreesurferToFunc(cfg.bidsdir,cfg.subjectlist)
                               
                
            case 6
                [~,out] = system([cfg.loopeval './calc_biascorrectMeanFunc.sh'],'-echo');

                % Boundary / Gradient based Surface / Volume alignment
                calc_boundaryBasedRegistration(cfg.bidsdir,cfg.subjectlist,'task','sequential')
            
           
            case 7
                % TVM recursive Boundary Registration.
                % TODO: The clustereval should be pulled out to this script
                calc_cluster_recursiveBoundaryRegistration(cfg.bidsdir,cfg.subjectlist,'task','sequential')
            
            case 8
                calc_backupFreesurfer(cfg.bidsdir,cfg.subjectlist)
                calc_overwriteFreesurferBoundaries(cfg.bidsdir,cfg.subjectlist)
            case 9

                    vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist{1},'boundary_identifier','%s_ses-01_from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface','axis','z','task','sequential')
                
                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist{1},'boundary_identifier','%s_ses-01_from-ANAT_to-FUNCCROPPED_mode-surface','axis','z','task','sequential')
                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist{1},'boundary_identifier','%s_ses-01_from-ANAT_to-FUNCCROPPED_desc-BBR_mode-surface','axis','z','task','sequential')
                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist{1},'boundary_identifier','%s_ses-01_from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface','axis','z','task','sequential')
                %                 Step9_visualiseRecursiveRegistration(cfg.bidsdir,cfg.subjectlist,'slicelist',23,'boundary_identifier','Anat2FuncBoundaries_recurs_sam','functional_identifier','meanWM_run1_sam.nii')
                
                
            p_meanrun= dir(fullfile(cfg.bidsdir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','func',sprintf('*task-%s*_desc-occipitalcropMeanBias_bold.nii','sustained')));
            boundaries = dir(fullfile(cfg.bidsdir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','coreg','*_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-BBR_mode-surface.mat'))
            config = struct('i_SubjectDirectory',fullfile(cfg.bidsdir,'derivates'),...
                    'i_ReferenceVolume',fullfile('preprocessing',cfg.subjectlist{1},'ses-01','func',p_meanrun.name),...
                    'i_Boundaries',fullfile('preprocessing',cfg.subjectlist{1},'ses-01','coreg',boundaries.name),...
                    'o_RegistrationMovie','test_bbr.mp4')
                config.i_Boundaries = {config.i_Boundaries}
                tvm_makeRegistrationMovieWithMoreBoundaries(config)
%                 
%                 
%                 
%                  p_meanrun= dir(fullfile(cfg.bidsdir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','func',sprintf('*task-%s*_desc-occipitalcropMeanBias_bold.nii','sustained')));
%                 anat= dir(fullfile(cfg.bidsdir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','anat','sub*_ses-01_desc-anatomical_T1w.nii'))
%                 coreg= dir(fullfile(cfg.bidsdir,'derivates','preprocessing',cfg.subjectlist{1},'ses-01','coreg','*_ses-01_from-ANAT_to-FUNCCROPPED_mode-image.mat'))
%                 [~,outname,~] = fileparts(coreg.name);
%                 config = struct('i_SubjectDirectory',fullfile(cfg.bidsdir,'derivates'),...
%                     'i_MoveVolumes',     fullfile('preprocessing',cfg.subjectlist{1},'ses-01','label','sub-01_ses-01_desc-varealabel_space-ANAT_label.nii'),...
%                     'i_ReferenceVolume',          fullfile('preprocessing',cfg.subjectlist{1},'ses-01','anat',anat.name),...
%                     'i_CoregistrationMatrix',fullfile('preprocessing',cfg.subjectlist{1},'ses-01','coreg',coreg.name),...
%                     'i_InverseRegistration',true,...
%                     'i_InterpolationMethod','NearestNeighbours',...
%                     'o_OutputVolumes',         fullfile('preprocessing',cfg.subjectlist{1},'ses-01','label_in_anat.nii'))
%                 
%                 tvm_resliceVolume(config)
                
                
                
            case 10
                 [~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaFullFunc.sh'],'-echo');
                 
                 % if not available go over cropped Anatomical
                 [~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaAnatCrop.sh'],'-echo');
                 
                % fsleyes anat/sub-*_ses-01_desc-occipitalcrop_T1w.nii func/sub-*_ses-01_task-sustained_desc-occipitalcropMeanBias_space-ANATCROPPED_bold.nii
                 % fsleyes anat/sub-*_ses-01_desc-occipitalcrop_space-ANAT_T1w.nii anat/sub-*_ses-01_desc-anatomical_T1w.nii 
                 % fsleyes anat/sub-*_ses-01_desc-anatomical_space-FUNCCROPPED_T1w.nii func/sub-*_ses-01_task-*_desc-occipitalcropMeanBias_bold.nii
            case 11
                [~,out] = system([cfg.loopeval './calc_createRetinotopyFromAtlas.sh'],'-echo');
                [~,out] = system([cfg.loopeval './calc_visualLabelToFunc.sh'],'-echo');
                %fsleyes anat/sub-*_ses-01_desc-anatomical_space-FUNCCROPPED_T1w.nii label/sub-*_ses-01_desc-varea_space-FUNCCROPPED_label.nii func/sub-*_ses-01_task-*_desc-occipitalcropMeanBias_bold.nii


%                 tvm_labelToVolume

        end
        fprintf('Finished Step %i \n',step)
    end
end

%% Phase Univariate Modeling
if strcmp(cfg.phase,'GLM')
    % This is for Univariate modeling with FEAT. I now use SPM because I like the interface better
    for step =cf% calc_CAIPI7tReconstruction(fullfile(cfg.bidsdir,'../','recon'),cfg.subjectlist) % run on cluster, returnsg.step
        fprintf('Running Step %i\n',step)
        switch step
            case 0 
                StepX_generateFSLEventfile(cfg.bidsdir,cfg.subjectlist,'condition','adaptation')
            case 1
                for SID =cfg.subjectlist
                    for run = [1:8]
                        
                        [~,out] = system([cfg.loopeval sprintf('export designfile="sequence_preprocessing";export runNum="%i";export SID="%s"',run,SID{1}) ';./Step1_FSL_RunFeat.sh'],'-echo');
                    end
                end

            case 4
                % move the preprocessed trial files to
                % preprocessing/././func
                StepX_moveFeatToFunc(cfg.bidsdir,cfg.subjectlist)
            case 5
                % OPTIONAL
                % run FEAT over the experimental runs
                for SID =cfg.subjectlist  
                    numberOfRuns = [2 3 4 0]; %so far hardcoded
                    runstring = int2str(numberOfRuns);
                    [~,out] = system([cfg.loopeval sprintf('export designfile="adapt_statistics_%iruns";export runlist="%s";export SID="%s"',length(numberOfRuns(numberOfRuns~=0)),runstring,SID{1}) ';./Step1_FSL_RunFeat.sh'],'-echo');
                end
                
            case 5
                
            case 6
%                 Step6_CreateLocaliserFunctionalFiles(cfg.bidsdir,cfg.subjectlist)
            case 7
                % copy the FEAT functional files to a new folder
                % SubjectData/SID/FunctionalFiles
%                 [~,out] = system([cfg.loopeval './Step7_CopyFunctionalFiles.sh'],'-echo');

        end
        fprintf('Finished Step %i \n',step)
    end
end

%% Phase 5
if strcmp(cfg.phase,'laminar')
    for step =cfg.step
        fprintf('Running Step %i\n',step)
        switch step
            case -1
                % zscore localizer & functionals, and add weighted versions
                % (weighting might be controversial)
                
                % No localizer used for 
                
                calc_spm2ndLevel(cfg.bidsdir,{SID},'task','sequential','recalculate',0) % in this context we are fine with having the data once, no need to recalculate
                
                
                calc_localizerWeightedFunc(cfg.bidsdir,cfg.subjectlist,'zscore',1,'weight',1,'software2nd','spm')


            case 0
                % I put it here, because its output goes into the tvm_layer
                % folder and is not preprocessing anymore imho
                calc_createROI(cfg.bidsdir,cfg.subjectlist,'topn',500)

            case 1
                layer_tvmPipeline(cfg.bidsdir,cfg.subjectlist)
            case 2
                layer_createSpatialglmX(cfg.bidsdir,cfg.subjectlist)
            case 3
                layer_timecourse(cfg.bidsdir,cfg.subjectlist)
          
        end
        fprintf('Finished Step %i \n',step)
    end
end