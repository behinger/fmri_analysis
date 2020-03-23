%%  For new projects
% make a new branch for your project and a copy of this file and edit away.
% If you change calculation functions, separate them in a own commit and
% make pull requests to the master branch! Then every project works on the
% same set of functions :-)
% Let us try not to break everything :S

try
    run('code/setup_paths') % init paths and stuff
end


    
%%
cfg = [];
cfg.autoRun = 0;
cfg.project = 'rivalry';
cfg.bidsdir = fullfile('/','project','3018029.10','binoc','data','bids');
cfg.scriptdir = fullfile(pwd,'code');

cfg.subjectlist = {'sub-01'};


    % Add some donders-grid things
    cfg = pipeline_config(cfg);
    % Add some donders-grid things
    cfg = pipeline_config(cfg);


if ~cfg.autoRun
    error('stopped on purpose') % stop the script here to not autorun :)
end
%%

% In case of 7T reconstruct subjectlist

%%
if 1 == 0
    %% only need to be run once
    % Link Sams Data to the new folder
   
    % Link functional
    % Link anatomical
    % Link ROIs
    % Link Freesurfer
    % Generate behavioural file
    d = dir('/project/3018028.04/SubjectData/');
    d = d([d.isdir]);
    d = d(~cellfun(@(x)any(strcmp(x,{'.','..','Common'})),{d.name}));
    %%
    
    for s= 1%:length(d)
        sPath = fullfile(d(s).folder,d(s).name);
        id = str2num(d(s).name(2:end));
        bids_sub = sprintf('sub-%02i_ses-01',id);
        bids_path = fullfile(cfg.bidsdir,sprintf('sub-%02i',id),'ses-01');
        preproc_path = fullfile(cfg.bidsdir,'derivates','preprocessing',sprintf('sub-%02i',id),'ses-01');
        freesurfer_path = fullfile(cfg.bidsdir,'derivates','freesurfer',sprintf('sub-%02i',id),'ses-01');
        
        % functional
        from = fullfile(sPath,'Rivalry','Niftis');
        to = fullfile(bids_path,'func');
        
        if ~exist(to,'dir');mkdir(to);end
        unix(['ln -s ' fullfile(from,'BR_run1.nii') ' ' fullfile(to,[bids_sub '_task-rivalry_run-1_bold.nii'])])
        unix(['ln -s ' fullfile(from,'BR_run2.nii') ' ' fullfile(to,[bids_sub '_task-rivalry_run-2_bold.nii'])])
        unix(['ln -s ' fullfile(from,'StimLoc.nii') ' ' fullfile(to,[bids_sub '_task-localizer_bold.nii'])])
        % anatomical
        from = fullfile(sPath,'Anatomy','Niftis');
        to = fullfile(preproc_path,'anat');
      
        if ~exist(to,'dir');mkdir(to);end
        unix(['ln -s ' fullfile(from,'MP2RAGE.nii') ' ' fullfile(to,[bids_sub '_desc-anatomical_T1w.nii'])]);
        to = fullfile(bids_path,'anat');
        if ~exist(to,'dir');mkdir(to);end
        unix(['ln -s ' fullfile(from,'MP2RAGE.nii') ' ' fullfile(to,[bids_sub '_desc-anatomical_T1w.nii'])]);
        
           
        % 3T to 7T anat
        from = fullfile(sPath,'Retinotopy','Anatomy');
        
        % sam named the freesurfer-subject = Freesurfer
            to = fullfile(preproc_path,'anat');
        if ~exist(to,'dir');mkdir(to);end
        % 3T anatomical
        unix(['ln -s ' fullfile(from,'InplaneAnat.nii.gz') ' ' fullfile(to,[bids_sub '_desc-3Tanatomical_T1w.nii'])]);
        
        % V1-V3 Labels
        to = fullfile(preproc_path,'label');
        if ~exist(to,'dir');mkdir(to);end
        unix(['ln -s ' fullfile(from,'V1.nii.gz') ' ' fullfile(to,[bids_sub '_desc-V1_space-3TANAT_label.nii.gz'])]);
        unix(['ln -s ' fullfile(from,'V2.nii.gz') ' ' fullfile(to,[bids_sub '_desc-V2_space-3TANAT_label.nii.gz'])]);
        unix(['ln -s ' fullfile(from,'V3.nii.gz') ' ' fullfile(to,[bids_sub '_desc-V3_space-3TANAT_label.nii.gz'])]);
        
            to = fullfile(preproc_path,'coreg');
                if ~exist(to,'dir');mkdir(to);end
        from = fullfile(sPath,'Attention','Coregistrations');

        % mappin 3T to 7T
        unix(['ln -s ' fullfile(from,'3TNu2Anat.mat') ' ' fullfile(to,[bids_sub '_from-3TANAT_to-ANAT.mat'])]);
        %%
        % localizer behavioural
        t = readtable('/project/3018028.04/SubjectData/Common/EventFiles/BR/StimLoc/c_clockwise.txt');
        t.Var4 = repmat("counter clockwise",size(t,1),1);
        t2 = readtable('/project/3018028.04/SubjectData/Common/EventFiles/BR/StimLoc/clockwise.txt');
        t2.Var4 = repmat("clockwise",size(t2,1),1);
        
        
        events = [t; t2];
        events.Properties.VariableNames = {'onset','duration','value','condition'};
        [~,IX] = sort(events.onset);
        events = events(IX,:);
        
        events.subject = repmat(s,size(events,1),1);
        events.run = repmat(1,size(events,1),1);
        events.task= repmat({'localizer'},size(events,1),1);
        events = removevars(events,'value');
        to = fullfile(bids_path,'func');

        writetable(events,fullfile(to,[bids_sub '_task-localizer_run-1_events.tsv']),'Delimiter','\t','FileType','text')
        %% Rivalry Behav Event file
        % Subject to process
        tAll = [];
        for runIx = 1:2
        
            tmp = load(fullfile(sPath,'Rivalry','BehaviouralData',['BR_MRI_S', num2str(s), '_Run', num2str(runIx), '.mat']));
            dominantOrientation = tmp.dominantOrientation;
            if 1 == 1
            dominantOrientation = medfilt1(dominantOrientation,5);% remove short offsets
            else
                dominantOrientation(dominantOrientation==0) = 3; %Sam's fix 
            end
            
            % Find locations of all switches
            switchInd = find(diff([0 dominantOrientation])~=0);
            numSwitches = length(switchInd);
            
            % For each switch identify what was being perceived
            percept = dominantOrientation([1 switchInd]);
            perceptList = {'no response','clockwise','counter clockwise','mixed'};
            percept = perceptList(percept+1);
            % For each percept figure when it started and out how long it was
            start = [0 switchInd] .* tmp.params.frameLength;
            duration= [switchInd(1) diff(switchInd) length(dominantOrientation)-switchInd(end)] .* tmp.params.frameLength;
            
            onset = start';
            duration = duration';
            condition = percept';
            t = table(onset,duration,condition);
            t.run = repmat(runIx,size(t,1),1);
            t.subject = repmat(s,size(t,1),1);
            t.task= repmat({'rivalry'},size(t,1),1);
            writetable(t,fullfile(to,[bids_sub '_task-rivalry_run-' num2str(runIx) '_events.tsv']),'Delimiter','\t','FileType','text')

            tAll = [tAll;t];
        end
        
%         %%
%         figure
%         g = gramm('x',tAll.duration,'color',tAll.percept);
%         g.stat_density('bandwidth',0.2)
%         g.facet_grid(tAll.run,[])
%         g.draw()
    end
   
end
    

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
%                     [~,out] = system([cfg.loopeval 'export SID="' SID{1} '";./calc_freesurfer_reconAll.sh'],'-echo');
                    % runs parrallel with freesurfer 6
                    [~,out] = system(['echo ''' cfg.loopeval 'export SID="' SID{1} '";./calc_freesurfer_reconAll.sh''' cfg.gridpipe_long_4cpu],'-echo');
                    
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
                calc_boundaryBasedRegistration(cfg.bidsdir,cfg.subjectlist)
            
           
            case 7
                % TVM recursive Boundary Registration.
                % Runs on Cluster
                calc_cluster_recursiveBoundaryRegistration(cfg.bidsdir,cfg.subjectlist,'task','rivalry')
            
            case 8
                calc_backupFreesurfer(cfg.bidsdir,cfg.subjectlist)
                calc_overwriteFreesurferBoundaries(cfg.bidsdir,cfg.subjectlist)
            case 9

                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist,'task','localizer','method','2d')
                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist,'task','sequential','method','movie','axis','transversal')
                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist,'task','sequential','method','movie','axis','coronal')
                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist,'task','sequential','method','movie','axis','sagittal')
                
            case 10
                % [~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaFullFunc.sh'],'-echo');
                 
                 % if not available go over cropped Anatomical
                 [~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaAnatCrop.sh'],'-echo');
                 

            case 11
                 [~,out] = system([cfg.loopeval './calc_createRetinotopyFromAtlas.sh'],'-echo');
                 [~,out] = system([cfg.loopeval './calc_align3TLabel2AnatCrop.sh'],'-echo');

                [~,out] = system([cfg.loopeval './calc_visualLabelToFunc.sh'],'-echo');
                
            case 12
                % can specify which label to move (asuming neuropythy
                % labels exist)
                 vis_volumeCoregistration(cfg.bidsdir,cfg.subjectlist,'plotLabel','V1')

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
            case -2
                % Event Related analysis
                events = collect_events(cfg.bidsdir,SID);
                evt_riv = events(events.task == "rivalry",:);
                calc_spm2ndLevel(cfg.bidsdir,{SID},evt_riv,'task','rivalry',...
                    'TR',3.408,...
                    'recalculate',1,'conditions',{'condition'}) % in this context we are fine with having the data once, no need to recalculate
                
                calc_spmContrast(cfg.bidsdir,cfg.subjectlist,'rivalry')
            case -1
                % zscore localizer & functionals, and add weighted versions
                % (weighting might be controversial)
                
                events = collect_events(cfg.bidsdir,SID);
                evt_loc = events(events.task == "localizer",:);
                calc_spm2ndLevel(cfg.bidsdir,{SID},evt_loc,'task','localizer',...
                    'TR',3.408,...
                    'recalculate',1,'conditions',{'condition'}) % in this context we are fine with having the data once, no need to recalculate
                
                calc_spmContrast(cfg.bidsdir,cfg.subjectlist,'localizer')
                calc_localizerWeightedFunc(cfg.bidsdir,cfg.subjectlist,'zscore',1,'weight',1,'software2nd','spm')


            case 0
                % I put it here, because its output goes into the tvm_layer
                % folder and is not preprocessing anymore imho
                calc_createROI(cfg.bidsdir,cfg.subjectlist,'topn',500,'alpha',0.05,'zstat_map',2:3)

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
