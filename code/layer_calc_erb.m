function [erb_table,times_seconds] = layer_calc_erb(funclist,events,TR,fromTo)

% funclistName = cellfun(@(x)fileparts(x),funclist,'UniformOutput',0)
assert(~isempty(funclist),'No Files Found')

runlist= regexp(strjoin(funclist),'_run-(.*?)_','tokens'); % find all rois of all strings, concatenate them before for one liner
runlist= cellfun(@(x)x{1},runlist,'UniformOutput',0); % get rid of the cells in cells (technicallity)

roilist= regexp(strjoin(funclist),'_roi-(.*?)_','tokens'); % find all rois of all strings, concatenate them before for one liner
roilist= cellfun(@(x)x{1},roilist,'UniformOutput',0); % get rid of the cells in cells (technicallity)

%%

times_tr = fromTo(1):ceil(fromTo(2)/TR);
times_seconds = times_tr * TR;


erb_table = [];
for runid = 1:length(runlist)
    tmp = load(funclist{runid});
    cont_data =    tmp.timeCourses{1};
    % run EEGLAB ICA before cutting ERPs. just a random idea
    %     [~,~,~,~,~,~,cont_data]  = runica(cont_data);
    
    
    eventsRun = events(events.run == str2num(runlist{runid}),:); 
    
    ix = round(times_tr + eventsRun.onsetTR) + 1; % +1 because volume 0 starts at data entry 1 in matlab
    nanlist = (ix<1) | (ix>size(cont_data,2));
    erb= nan([size(cont_data,1) size(ix)]); % event related bold
    erb(:,~nanlist) = cont_data(:,ix(~nanlist));
    
    
    
    for k = 1:size(erb,1)
        data_table = eventsRun;
        
        data_table.erb = squeeze(erb(k,:,:));
%         data_table.erb_bsl = bslfunction(squeeze(erb(k,:,:)));
        data_table.layer = repmat(k,size(data_table,1),1);
        data_table.roi= repmat(roilist(runid),size(data_table,1),1);
        data_table.run= repmat(str2num(runlist{runid}),size(data_table,1),1);
        
        erb_table = [erb_table; data_table];
        
    end
end