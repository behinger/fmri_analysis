function calc_symlinkRawData(bidsdir)
   
    % Link functional
    % Link anatomical
    % Link ROIs
    % Link Freesurfer
    % Generate behavioural file
    d = dir('/project/3018028.04/SubjectData/');
    d = d([d.isdir]);
    d = d(~cellfun(@(x)any(strcmp(x,{'.','..','Common'})),{d.name}));
    %%
    
    for s= 1:length(d)
        sPath = fullfile(d(s).folder,d(s).name);
        
        id = str2num(d(s).name(2:end));
        if id == 17
            continue
        end
        bids_sub = sprintf('sub-%02i_ses-01',id);
        bids_path = fullfile(bidsdir,sprintf('sub-%02i',id),'ses-01');
        preproc_path = fullfile(bidsdir,'derivates','preprocessing',sprintf('sub-%02i',id),'ses-01');
        freesurfer_path = fullfile(bidsdir,'derivates','freesurfer',sprintf('sub-%02i',id),'ses-01');
        
        % functional
        from = fullfile(sPath,'Rivalry','Niftis');
        to = fullfile(bids_path,'func');
        
        if ~exist(to,'dir');mkdir(to);end
        unix(['ln -s ' fullfile(from,'BR_run1.nii') ' ' fullfile(to,[bids_sub '_task-rivalry_run-1_bold.nii'])])
        unix(['ln -s ' fullfile(from,'BR_run2.nii') ' ' fullfile(to,[bids_sub '_task-rivalry_run-2_bold.nii'])])
        unix(['ln -s ' fullfile(from,'StimLoc.nii') ' ' fullfile(to,[bids_sub '_task-localizer_run-1_bold.nii'])])
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
        events.onset = events.onset+3*3.408;
        events.subject = repmat(id,size(events,1),1);
        events.run = repmat(1,size(events,1),1);
        events.task= repmat({'localizer'},size(events,1),1);
        events = removevars(events,'value');
        to = fullfile(bids_path,'func');

        writetable(events,fullfile(to,[bids_sub '_task-localizer_run-1_events.tsv']),'Delimiter','\t','FileType','text')
        %% Rivalry Behav Event file
        % Subject to process
        tAll = [];
        for runIx = 1:2
        
            tmp = load(fullfile(sPath,'Rivalry','BehaviouralData',['BR_MRI_S', num2str(id), '_Run', num2str(runIx), '.mat']));
            %%
            dominantOrientation = tmp.dominantOrientation;
            if 1 == 0
                %%
                figure
                set(gcf,'Color',[1 1 1])
                dominantOrientation2 = medfilt1(dominantOrientation,5);% remove short offsets
                for k = 1:2
                    subplot(2,1,k)
                    switch k
                        case 1
                            domPlot = dominantOrientation;
                        case 2
                            domPlot = dominantOrientation2;
                    end
                    
                    plot(1/60*(1:length(dominantOrientation))*0.016,domPlot,'o-')
                    xlabel('time [min]')
                    xlim([2.3 5.5])
                    set(gca,'YTick',[0 1 2 3])
                    set(gca,'YTickLabel',{'no button pressed','counter clockwise','mixed','clockwise'})
                    box off
                end
            end
               
            if 1 == 1
            dominantOrientation = medfilt1(dominantOrientation,5);% remove short offsets
            else
                dominantOrientation(dominantOrientation==0) = 2; %Sam's fix 
            end
         
            
%             hold on
%             plot(dominantOrientation)
            %%
            
            % Find locations of all switches
            switchInd = find(diff([0 dominantOrientation])~=0);
            numSwitches = length(switchInd);
            
            % For each switch identify what was being perceived
            percept = dominantOrientation([1 switchInd]);
            perceptList = {'no response','counter clockwise','mixed','clockwise'};
            percept = perceptList(percept+1);
            % For each percept figure when it started and out how long it was
            start = [0 switchInd] .* tmp.params.frameLength;
            duration= [switchInd(1) diff(switchInd) length(dominantOrientation)-switchInd(end)] .* tmp.params.frameLength;
            
            onset = start';
            duration = duration';
            condition = percept';
            t = table(onset,duration,condition);
            t.run = repmat(runIx,size(t,1),1);
            t.subject = repmat(id,size(t,1),1);
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