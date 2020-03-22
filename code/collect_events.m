function events = collect_events(datadir,SID)
searchPath = fullfile(datadir,SID,'ses-01','func','*run-*.tsv');
eventFiles = [dir(searchPath)];
if isempty(eventFiles)
    warning('no files found in %s, return empty',searchPath)
end
events = [];
for run = 1:length(eventFiles)
    t = readtable(fullfile(eventFiles(run).folder,eventFiles(run).name),'fileType','text');
    events = [events;t];
end