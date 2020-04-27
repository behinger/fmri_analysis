function layer_to_csv
TR = 3.408;


cfg.subjectlist = {'sub-01','sub-02','sub-03','sub-04','sub-05','sub-06','sub-07','sub-08','sub-10','sub-11','sub-13','sub-14','sub-15','sub-16','sub-18','sub-19','sub-21','sub-22',...
    'sub-23','sub-24','sub-25','sub-26','sub-27','sub-28','sub-29'};
cfg.subjectid = cellfun(@(x)str2num(x{1}{1}),regexp(cfg.subjectlist,'sub-([\d]{2})','tokens'));
cfg.bidsdir = fullfile('/','project','3018029.10','binoc','data','bids');
for SID = 1:length(cfg.subjectlist)
    
    bidspath      = fullfile(cfg.bidsdir,'%s','%s',cfg.subjectlist{SID},'ses-01');
    path_layer= sprintf(bidspath,'derivates','tvm_layers');
    funclist = dir(fullfile(path_layer,'timecourse',sprintf('*_desc-preproc-*_timecourse*')));
    funclist = fullfile({funclist.folder},{funclist.name});
    events = collect_events(cfg.bidsdir,cfg.subjectlist{SID});
    events.onsetTR = events.onset/TR;
    
    runlist= extractInfo(funclist,'run');
    roilist= extractInfo(funclist,'roi');
    desclist= extractInfo(funclist,'desc');
    tasklist= extractInfo(funclist,'task');
    
    
    for f = 1:length(funclist)
        select = events.subject == cfg.subjectid(SID)  & strcmp(events.task,tasklist{f}) & events.run == str2num(runlist{f});
        f_events = events(select,:);
        if isempty(f_events)
            break
        end
        assert(~isempty(f_events))
        data = load(funclist{f});
        target_dir = fullfile(path_layer,'export');
        if ~exist(target_dir)
            mkdir(target_dir)
        end
        [~,n] = fileparts(funclist{f});
        %
        target_file = fullfile(target_dir,n);
        % write data
        dlmwrite([target_file '_data.csv'],data.timeCourses{1})
        % write events
        writetable(f_events,[target_file '_events.csv'])
    end
end


%%
end


function list = extractInfo(funclist,target)
list= regexp(strjoin(funclist),['_' target '-(.*?)_'],'tokens'); % find all rois of all strings, concatenate them before for one liner
list= cellfun(@(x)x{1},list,'UniformOutput',0); % get rid of the cells in cells (technicallity)
end