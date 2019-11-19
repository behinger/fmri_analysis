%%  For new projects
% make a new branch for your project and a copy of this file and edit away.
% If you change calculation functions, separate them in a own commit and
% make pull requests to the master branch! Then every project works on the
% same set of functions :-)
% Let us try not to break everything :S

try
    run('code/setup_paths') % init paths and stuff
end


cfg = [];
cfg.autoRun = 0;
cfg.project = 'sustained';
cfg.bidsdir = fullfile('/','project','3018029.10',cfg.project,'data','pilot','bids');
cfg.scriptdir = fullfile(pwd,'code');

cfg.subjectlist = {'sub-05'};

% Add some donders-grid things
cfg = pipeline_config(cfg);


if ~cfg.autoRun
    error('stopped on purpose') % stop the script here to not autorun :)
end
%%

% In case of 7T reconstruct subjectlist

%%

cfg.phase = 'preprocessing';
cfg.step = [1:2]; % Copy Anaotmical + run freesurfer => Cluster
cfg.step = [4] % realignFunctions => cluster
cfg.step = [3] % Manually Crop cortex
cfg.step = [5:7] % after Freesurfer is finished (step 2), calculate GM/WM boundaries => Partially on cluster

% Careful, currently both functions (via cropped anatomical and via fulll functional) are active. XXX todo
cfg.step = [8 10 11]; % align anatomical with functional for V1 ROI, calculate ROI, map ROI

cfg.step = 9; %visually check corregistration of boundaries
%XXX Todo: Visually check realignment using "theplot"



%% Phase 1
if strcmp(cfg.phase,'preprocessing')
    % path modifications
    
    for step =cfg.step
      
        switch step
            case 0
                % For 7T caipi data you want to run step 0 first :-)
%                 calc_CAIPI7tReconstruction(fullfile(cfg.bidsdir,'../','recon'),cfg.subjectlist) % run on cluster, returns

            case 1
                % simple modification to get a (betteR) T1 from the mp2rage anatomical scan
                % Not necessary anymore for newer MP2RAGEs
                %calc_modifyMP2RAGE(cfg.bidsdir,cfg.subjectlist)
            case 2
                % Segment Anatomical
                % recon-all to segment
                for SID =cfg.subjectlist
                    %locally
                    %[~,out] = system([cfg.loopeval 'export SID="' SID{1} '";./calc_runFreesurfer.sh'],'-echo');
                    % runs parrallel with freesurfer 6
                    [~,out] = system(['echo ''' cfg.loopeval 'export SID="' SID{1} '";./calc_runFreesurfer.sh''' cfg.gridpipe_long_4cpu],'-echo');
                    
                end
            case 3
                % crop the occipital cortex
                % manual input needed how to best save coordinates for croping to
                manual_cropOccipital(cfg.bidsdir,cfg.subjectlist)
                
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
                calc_boundaryBasedRegistration(cfg.bidsdir,cfg.subjectlist,'task',cfg.project)
            
           
            case 7
                % TVM recursive Boundary Registration.
                % Runs on Cluster
                calc_cluster_recursiveBoundaryRegistration(cfg.bidsdir,cfg.subjectlist,'task','sequential')
            
            case 8
                calc_backupFreesurfer(cfg.bidsdir,cfg.subjectlist)
                calc_overwriteFreesurferBoundaries(cfg.bidsdir,cfg.subjectlist)
            case 9

                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist)
                
                
            case 10
                % [~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaFullFunc.sh'],'-echo');
                 
                 % if not available go over cropped Anatomical
                 [~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaAnatCrop.sh'],'-echo');
                 

            case 11
                [~,out] = system([cfg.loopeval './calc_createRetinotopyFromAtlas.sh'],'-echo');
                [~,out] = system([cfg.loopeval './calc_visualLabelToFunc.sh'],'-echo');
                
            case 12
                % can specify which label to move (asuming neuropythy
                % labels exist)
                 vis_volumeCoregistration(cfg.bidsdir,cfg.subjectlist,'plotLabel','varea')

        end
        fprintf('Finished Step %i \n',step)
    end
end

%% Phase Univariate Modeling

% I replaced this with SPM, as I like their coding way much better.
% see the sequence_pilot_analysis_spmbatch file

% if strcmp(cfg.phase,'GLM')
%     % This is for Univariate modeling with FEAT. I now use SPM because I like the interface better
%     for step =cfg.step
%         fprintf('Running Step %i\n',step)
%         switch step
%             case 0 
%                 StepX_generateFSLEventfile(cfg.bidsdir,cfg.subjectlist,'condition','adaptation')
%             case 1
%                 for SID =cfg.subjectlist
%                     for run = [1:8]
%                         
%                         [~,out] = system([cfg.loopeval sprintf('export designfile="sequence_preprocessing";export runNum="%i";export SID="%s"',run,SID{1}) ';./Step1_FSL_RunFeat.sh'],'-echo');
%                     end
%                 end
% 
%             case 4
%                 % move the preprocessed trial files to
%                 % preprocessing/././func
%                 StepX_moveFeatToFunc(cfg.bidsdir,cfg.subjectlist)
%             case 5
%                 % OPTIONAL
%                 % run FEAT over the experimental runs
%                 for SID =cfg.subjectlist  
%                     numberOfRuns = [2 3 4 0]; %so far hardcoded
%                     runstring = int2str(numberOfRuns);
%                     [~,out] = system([cfg.loopeval sprintf('export designfile="adapt_statistics_%iruns";export runlist="%s";export SID="%s"',length(numberOfRuns(numberOfRuns~=0)),runstring,SID{1}) ';./Step1_FSL_RunFeat.sh'],'-echo');
%                 end
%                 
%             case 5
%                 
%             case 6
% %                 Step6_CreateLocaliserFunctionalFiles(cfg.bidsdir,cfg.subjectlist)
%             case 7
%                 % copy the FEAT functional files to a new folder
%                 % SubjectData/SID/FunctionalFiles
% %                 [~,out] = system([cfg.loopeval './Step7_CopyFunctionalFiles.sh'],'-echo');
% 
%         end
%         fprintf('Finished Step %i \n',step)
%     end
% end

%% Phase 5
if strcmp(cfg.phase,'laminar')
    for step =cfg.step
        fprintf('Running Step %i\n',step)
        switch step
            case -1
                % zscore localizer & functionals, and add weighted versions
                % (weighting might be controversial)
                
                % No localizer used for 
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


%%
% For ROI-wise Plots:
sustained_pilot_analysis_timecourse


events = collect_events(cfg.bidsdir,cfg.subjectlist{1});

% we need to find the block onset
stimOnsetIX = find(events.message == "stimOnset");
onsetIX = diff(events{stimOnsetIX,'block'}) == 1;
onsetIX = [1; stimOnsetIX(find([0; onsetIX]))];
events.blockOnset = zeros(size(events,1),1);
events.blockOnset(onsetIX) = 1; % to mark the onset
if cfg.subjectlist{1} == "sub-05"
    % fix inconsistency during recording
    ix = events.subject == 5;
    events.run(ix)  = events.run(ix) + 1;
end

% take only block onsets :-)
events = events(events.blockOnset == 1,:);

    
%For Whole-Brain SPM analysis
calc_spm2ndLevel(cfg.bidsdir,cfg.subjectlist,events,'task','sustained','TR',1.5,'conditions',{'stimulus','condition'},'recalculate',1)
% generate default contrasts (main effects)
calc_spmContrast(cfg.bidsdir,cfg.subjectlist)



% For Layer-wise Plots
layer_mainPlots