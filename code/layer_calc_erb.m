function [erb_table,times_tr] = layer_calc_erb(cfgPlot,datadir,subjectlist,SID)


bidspath      = fullfile(datadir,'%s','%s',subjectlist{SID},'ses-01');
path_layer= sprintf(bidspath,'derivates','tvm_layers');


funclist = dir(fullfile(path_layer,'timecourse',sprintf('*_task-%s_*_desc-preproc-zscore%s_timecourse*',cfgPlot.task,cfgPlot.mask)));



funclist = {funclist.name};
assert(~isempty(funclist),'No Files Found')

runlist= regexp(strjoin(funclist),'_run-(.*?)_','tokens'); % find all rois of all strings, concatenate them before for one liner
runlist= cellfun(@(x)x{1},runlist,'UniformOutput',0); % get rid of the cells in cells (technicallity)

roilist= regexp(strjoin(funclist),'_roi-(.*?)_','tokens'); % find all rois of all strings, concatenate them before for one liner
roilist= cellfun(@(x)x{1},roilist,'UniformOutput',0); % get rid of the cells in cells (technicallity)

%%
warning('THIS HAS TO CHANGE!')
switch subjectlist{SID}
    case 'sub-01'
        times = -3:ceil(30/3.504);
        times_tr = times * 3.504;
    case 'sub-02'
        times = -3:ceil(30/2.3275);
        times_tr = times * 2.375;
    case 'sub-04'
        times = -3:ceil(30/2.375);
        times_tr = times * 2.375;
        
end
erb_table = [];
for runid = 1:length(runlist)
    tmp = load(fullfile(path_layer,'timecourse',funclist{runid}));
    cont_data =    tmp.timeCourses{1};
    % run EEGLAB ICA before cutting ERPs. just a random idea
    %     [~,~,~,~,~,~,cont_data]  = runica(cont_data);
    
    eventonsets = StepX_generateFSLEventfile(datadir,subjectlist(SID),'condition',cfgPlot.task);
    eventonsets = eventonsets{1};
    eventonsets = eventonsets(eventonsets.run == str2num(runlist{runid}),:);
    
    if size(cont_data,2) == 160 || size(cont_data,2)==241
        dummyvolumes = 0; % already removed
    elseif size(cont_data,2) == 163
        dummyvolumes = 3;
    else
        error('unknown number of volumes per run')
    end
    
    
    ix = round(times + eventonsets.times_volume) + 1 + dummyvolumes; % +1 because volume 0 starts at data entry 1 in matlab
    nanlist = (ix<1) | (ix>size(cont_data,2));
    erb= nan([size(cont_data,1) size(ix)]); % event related bold
    erb(:,~nanlist) = cont_data(:,ix(~nanlist));
    
    
    
    for k = 1:size(erb,1)
        data_table = eventonsets;
        
        bslcorrect = @(x)bsxfun(@minus,x,nanmean(x(:,1)));
        
        
        data_table.erb = squeeze(erb(k,:,:));
        data_table.erb_bsl = bslcorrect(squeeze(erb(k,:,:)));
        data_table.layer = repmat(k,size(data_table,1),1);
        data_table.roi= repmat(roilist(runid),size(data_table,1),1);
        data_table.run= repmat(str2num(runlist{runid}),size(data_table,1),1);
        
        erb_table = [erb_table; data_table];
        
    end
end