function events = collect_events(datadir,SID)

% eventFiles = [dir(fullfile(datadir,SID,'ses-01','func','*run-*events.tsv'))];
eventFiles = [dir(fullfile(datadir,'derivates','preprocessing',SID,'ses-01','func','*.tsv'))];
events = [];
for run = 1:length(eventFiles)
    t = readtable(fullfile(eventFiles(run).folder,eventFiles(run).name),'fileType','text');
    events = [events;t];
end