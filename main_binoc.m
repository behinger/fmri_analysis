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

% No MPRAGE2 for 'sub-09'
% Sub-21: Strong front-back aliasing effect throughout
cfg.subjectlist = {'sub-01','sub-02','sub-03','sub-04','sub-05','sub-06','sub-07','sub-08','sub-10','sub-11','sub-13','sub-14','sub-15','sub-16','sub-18','sub-19','sub-21','sub-22',...
    'sub-23','sub-24','sub-25','sub-26','sub-27','sub-28','sub-29'};

% cfg.subjectlist = {'sub-07','sub-11'}

    % Add some donders-grid things
    cfg = pipeline_config(cfg);


if ~cfg.autoRun
    error('stopped on purpose') % stop the script here to not autorun :)
end
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

cfg.step = [-1 3 4] % wait until realignment is finished
cfg.step = [5  6 7 11]

%% Phase 1
if strcmp(cfg.phase,'preprocessing')
    % path modifications
    
    for step =cfg.step
      
        switch step
            case -1 
                calc_symlinkRawData(cfg.bidsdir); 
            case 0
                % For 7T caipi data you want to run step 0 first :-)
%                 calc_CAIPI7tReconstruction(fullfile(cfg.bidsdir,'../','recon'),cfg.subjectlist) % run on cluster, returns

            case 1
                % simple modification to get a (betteR) T1 from the mp2rage anatomical scan
                % Not necessary anymore for newer MP2RAGEs; not necessary
                % for Sam's data. already run.
                %calc_modifyMP2RAGE(cfg.bidsdir,cfg.subjectlist)
            case 2
                % Segment Anatomical
                % recon-all to segment
                for SID =cfg.subjectlist
                    %locally
                    if 1 == 0
                        [~,out] = system([cfg.loopeval 'export SID="' SID{1} '";./calc_freesurfer_reconAll.sh'],'-echo');
                    end
                    % runs parrallel with freesurfer 6
                    [~,out] = system(['echo ''' cfg.loopeval 'export SID="' SID{1} '";./calc_freesurfer_reconAll.sh''' cfg.gridpipe_long_4cpu],'-echo');
                    
                end
            case 3
                % crop the occipital cortex
                % manual input needed how to best save coordinates for croping to
                manual_cropOccipital(cfg.bidsdir,cfg.subjectlist,1)
                
%                 manual_cropOccipital(cfg.bidsdir,{'sub-02'},1,0)
                
            case 4
                % SPM linear realign of functional scans to mean functional
                % scan. Output mean nifti
                 for SID =cfg.subjectlist
                    qsubfeval(@calc_realignFunctionals, cfg.bidsdir, SID, 'memreq', 3000 * 1024 ^ 2, 'timreq', 60*60*10, 'compile', 'no');
                 end
                if 1==0
                    % run locally
                 calc_realignFunctionals(cfg.bidsdir,cfg.subjectlist)
                end
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

                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist,'method','2d','boundaries',{'_desc-recursive_mode-surface'})
                
                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist(1:5),'method','movie','axis','transversal')
                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist(1),'method','movie','axis','coronal')
                vis_surfaceCoregistration(cfg.bidsdir,cfg.subjectlist(1),'method','movie','axis','sagittal')
                
%             case 10
                
            case 10
                % [~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaFullFunc.sh'],'-echo');
                 
                 % if not available go over cropped Anatomical
                 %[~,out] = system([cfg.loopeval './calc_alignAnat2Func_viaAnatCrop.sh'],'-echo');
%                   [~,out] = system([cfg.loopeval './calc_alignAnat2Func.sh'],'-echo');
%                     calc_alignAnat2Func(cfg) % we need some algorithm for some subject, other algorithm for other subjects :|

            case 11
                 [~,out] = system([cfg.loopeval './calc_createRetinotopyFromAtlas.sh'],'-echo');
                 calc_alignAnat2Func_viaBBR(cfg.bidsdir,cfg.subjectlist)

                 % SUB 21!
%                  [~,out] = system([cfg.loopeval './calc_align3TLabel2AnatCrop.sh'],'-echo');

%                 [~,out] = system([cfg.loopeval './calc_visualLabelToFunc.sh'],'-echo');
                
            case 12
                % can specify which label to move (asuming neuropythy
                % labels exist)
                
                % Sub 02 => Cutout too small
                
                
                % sub 07 bad => directly over Anat good results
                % sub 11 bad => directly over Anat Good results
                % sub 15 bad
                % sub 16 bad => Visual cortex is cut off on top
                % sub 22 bad
                % sub 23 bad
                % sub 24 bad
                % sub 26 bad
                % sub 27 bad
                % sub 28 bad
                
                
                
                 vis_volumeCoregistration(cfg.bidsdir,cfg.subjectlist,'plotLabel',{'varea'})

        end
        fprintf('Finished Step %i \n',step)
    end
end


%% Phase 5
cfg.step = [0 2 3]
cfg.phase = 'laminar'
if strcmp(cfg.phase,'laminar')
    for step =cfg.step
        fprintf('Running Step %i\n',step)
        switch step
            case -2
                %%
                for SID  = cfg.subjectlist(2:end)
                % Event Related analysis
                events = collect_events(cfg.bidsdir,SID{1});
                evt_riv = events(events.task == "rivalry",:);
                calc_spm2ndLevel(cfg.bidsdir,SID,evt_riv,'task','rivalry',...
                    'TR',3.408,...
                    'recalculate',1,'conditions',{'condition'}) % in this context we are fine with having the data once, no need to recalculate
                
                calc_spmContrast(cfg.bidsdir,SID,'rivalry')
                end
            case -1
                %% zscore localizer & functionals, and add weighted versions
                % (weighting might be controversial)
                %
                for SID  = cfg.subjectlist(1:end)
%%
                events = collect_events(cfg.bidsdir,SID{1});
                evt_loc = events(events.task == "localizer",:);
                
                calc_spm2ndLevel(cfg.bidsdir,SID,evt_loc,'task','localizer',...
                    'TR',3.408,'smooth',0,...
                    'recalculate',1,'conditions',{'condition'}) % in this context we are fine with having the data once, no need to recalculate
                
                calc_spmContrast(cfg.bidsdir,SID,'localizer')
                calc_localizerWeightedFunc(cfg.bidsdir,SID,'zscore',1,'weight',1,'software2nd','spm')
                end

            case 0
                % I put it here, because its output goes into the tvm_layer
                % folder and is not preprocessing anymore imho
                calc_createROI(cfg.bidsdir,cfg.subjectlist,'topn',500,'alpha',0.05,'zstat_map',1:3)

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
