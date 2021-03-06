
cfg.datadir = fullfile('/project/3018029.10/sustained/','data','pilot','bids');
SID = 'sub-05'
niftis = [dir(fullfile(cfg.datadir,'derivates','preprocessing',SID,'ses-01','func','*task-sus*run-*Realign_bold.nii'))];
mask_varea = dir(fullfile(cfg.datadir,'derivates','preprocessing',SID,'ses-01','label','*desc-varea_space-FUNCCROPPED_label.nii'));
mask_eccen = dir(fullfile(cfg.datadir,'derivates','preprocessing',SID,'ses-01','label','*desc-eccen_space-FUNCCROPPED_label.nii'));
% Pilot analysis for sub1 - Sub 3 (4?) With the flickering
% cfg.bidsdir = fullfile('/project/3018028.04/benehi/sustained/','data','pilot','bids');


nifti_varea= nifti(fullfile(mask_varea.folder,mask_varea.name));
nifti_eccen= nifti(fullfile(mask_eccen.folder,mask_eccen.name));

ix_v1= nifti_varea.dat(:) == 1; % V1
ix_ec10 = nifti_eccen.dat(:) <10; % V1

voxel_select_ix = find(ix_v1 & ix_ec10);


%% Load Event Files

events = collect_events(fullfile(cfg.datadir),SID)

if SID == "sub-01"
    events.Properties.VariableNames{3} = 'condition';
    % to be backwards compatible with sub-01;
    events.message = repmat("stimOnset",size(events,1),1);
    events.block = repmat(1:12,1,size(events,1)/12)';
    
end

if SID == "sub-05"
    ix = events.message == "maskOnset";
    events(ix,'message') = repmat({'stimOffset'},sum(ix),1);
    % Fix the irrgularity at recording time
    
    ix = events.subject == 5;
    events.run(ix)  = events.run(ix) + 1;
    
end
stimOnsetIX = find(events.message == "stimOnset");
onsetIX = diff(events{stimOnsetIX,'block'}) == 1;
onsetIX = [1; stimOnsetIX(find([0; onsetIX]))];
events.trial = nan(size(events,1),1);
events.trial(onsetIX) = 1; % to mark the onset

%% Voxel selection

calc_spm2ndLevel(cfg.bidsdir,cfg.subjectlist,'task','sustained','TR',1.5,'conditions',{'stimulus','condition'},'recalculate',0)
% generate default contrasts (main effects)
% calc_spmContrast(cfg.bidsdir,cfg.subjectlist)

tmpT = nifti(fullfile(cfg.datadir,'derivates','spm',SID,'ses-01','GLM','run-all','spmT_0001.nii'));

[~,I] = sort(tmpT.dat(voxel_select_ix));
ixTop200 = voxel_select_ix(I(end-200:end));




%% ZScore, Highpassfilter & mean ROI
if SID == "sub-01"
    TR = 3.408;
else
    TR = 1.5;
end
act = [];
tic
for run = 1:max(unique(events.run))
    fprintf('run %i \t toc: %f.2s\n',run,toc)
    
    nifti_bold = nifti(fullfile(niftis(run).folder,niftis(run).name));
    timecourse = double(nifti_bold.dat);
    timecourse = bold_ztransform(timecourse);
    timecourse = permute(timecourse,[4,1,2,3]);
    size_tc= size(timecourse);
    timecourse(:) = tvm_highPassFilter(timecourse(:,:),TR,1/100);
    for tr = 1:size(nifti_bold.dat,4)
        
        tmp = timecourse(tr,:,:,:);
        act(run,tr) = nanmean(tmp(ixTop200));
    
    end
end
%%  CUT ERP


events_onset = events(events.trial == 1,:);
allDat = [];
for block = 1:height(events_onset)
    tmp = events_onset(block,:);
    ix_time = -3*TR:TR:20*TR;
    ix_tr = round(ix_time/TR + tmp.onset/TR);
    tmp.erb = nan(1,length(ix_tr));
    tmp.erb(ix_tr>0 & ix_tr<=size(act,2)) = act(tmp.run,max(1,ix_tr(1)):min(size(act,2),ix_tr(end)));
    
    allDat = [allDat;tmp];
end




%%
%  bslcorrect =@(x,times)100*bsxfun(@rdivide,x,mean(x(:,times>=-1.5 & times <=1.5),2))-100;
bslcorrect =@(x,times)bsxfun(@minus,x,nanmean(x(:,times>=-1.5 & times <=1.5),2));


allDat.erb_bsl = bslcorrect(allDat.erb,ix_time);

% plotData  = allDat.erb;
plotData  = allDat.erb_bsl;

%% Condition
figure
g = gramm('x',ix_time,'y',plotData,'color',allDat.condition);
g.stat_summary('type','bootci','geom','errorbar','setylim',1,'dodge',0.5);
g.stat_summary('type','ci','geom','point','setylim',1);
g.stat_summary('type','ci','geom','line','setylim',1);
g.draw();
g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('%s_ses-01_desc-condition_plot.pdf',SID));


%% Condition single trial
figure
g = gramm('x',ix_time,'y',plotData,'color',allDat.condition);
g.geom_line('alpha',0.5);
g.stat_summary('type','bootci','geom','errorbar','setylim',0,'dodge',0.5);
g.stat_summary('type','ci','geom','point','setylim',0);

g.stat_summary('type','ci','geom','line','setylim',0);
g.draw();
g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('%s_ses-01_desc-conditionSingletrial_plot.pdf',SID));
%% Condition / stimulus
figure
g = gramm('x',ix_time,'y',plotData,'color',allDat.condition)
g.stat_summary('type','bootci','geom','errorbar','setylim',1,'dodge',0.5);
g.stat_summary('type','ci','geom','point','setylim',1,'dodge',0);
g.stat_summary('type','ci','geom','line','setylim',1,'dodge',0);
g.facet_wrap(allDat.stimulus);
% g.axe_property('Ylim',[-0.38 1.6])
g.draw();
g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('%s_ses-01_desc-conditionStimulustype_plot.pdf',SID));
%%
figure
g = gramm('x',allDat.condition,'y',median(plotData(:,ix_time >= 6 & ix_time<=21),2),'color',allDat.stimulus);
g.stat_summary('type','bootci','geom','errorbar','dodge',0.2);
g.stat_summary('geom','point','dodge',0.2);
g.geom_point('alpha',0.2,'dodge',0.05);
%g.axe_property('Xlim',[0.2 0.9]);
g.draw();

g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('%s_ses-01_desc-meanConditionAttention_plot.pdf',SID));
%%
figure
g = gramm('x',(allDat.run-1)*12+allDat.block,'y',median(plotData(:,ix_time >= 6 & ix_time<=21),2),'color',allDat.condition,'marker',allDat.stimulus,'linestyle',allDat.stimulus);
g.geom_point()
g.stat_glm()
g.draw();
g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('%s_ses-01_desc-meanTime_plot.pdf',SID));
