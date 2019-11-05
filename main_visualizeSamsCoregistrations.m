%%
% This script updates sam Lawrence Attention project (~28 subjects) to
% the bids-data structure we use in the other projects
% Then we call the coregistration visualization tools to make movies!
%
try
    run('code/setup_paths') % init paths and stuff
end


cfg = [];
cfg.autoRun = 0;
cfg.project = 'sam_coregistrations';
cfg.bidsdir = fullfile('/','project','3018029.10','sam_coregistrations','data','bids');
cfg.scriptdir = fullfile(pwd,'code');


%% Generate the links

%Generate folder
if ~exist(cfg.bidsdir,'dir')
    mkdir(cfg.bidsdir)
end
attentiondir = '/project/3018028.04/SubjectData/';
whatSubjectsExist = dir([attentiondir 'S*']);
whatSubjectsExist = whatSubjectsExist([whatSubjectsExist.isdir]); % remove non-folders
whatSubjectsExist = {whatSubjectsExist.name};
for sub = whatSubjectsExist
    frompath = fullfile(attentiondir,sub{1},'Attention');
    topath = fullfile(cfg.bidsdir,'derivates','preprocessing',['sub-' sub{1}(2:end)],'ses-01');
    % We make it modular in case I need other files later in bids format as
    % well
    moveStruct(1).from = fullfile(frompath,'Coregistrations','Anat2FuncBoundaries_recurs.mat');
    moveStruct(1).to   = fullfile(topath,'coreg',sprintf('sub-%s_ses-01_from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface.mat',sub{1}(2:end)));
    moveStruct(2).from = fullfile(frompath,'Niftis','Realigned','meanATTN_run1.nii');
    moveStruct(2).to   = fullfile(topath,'func',sprintf('sub-%s_ses-01_task-attention_desc-occipitalcropMeanBias_bold.nii',sub{1}(2:end)));
    for file = 1:length(moveStruct)
        if ~exist(fileparts(moveStruct(file).to),'dir')
            mkdir(fileparts(moveStruct(file).to))
        end
        [status,cmdout] = system(sprintf('ln -s %s %s',moveStruct(file).from,moveStruct(file).to));
        if status ~=0
            warning(cmdout)
        end
    end
%     system

end
% ln -s /project/3018028.04/SubjectData/S01/Attention/Coregistrations/Anat2FuncBoundaries_recurs.mat
% coreg/sub-01_ses-01_from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface.mat
% ln -s /project/3018028.04/SubjectData/S01/Attention/Niftis/Realigned/meanATTN_run1.nii 
% func/sub-01_ses-01_task-attention_desc-occipitalcropMeanBias_bold.nii
%%
for sub = whatSubjectsExist(1:5)
    fprintf('making movies from sub %s\n',sub{1})
    subStr = {sprintf('sub-%s',sub{1}(2:end))};
    vis_surfaceCoregistration(cfg.bidsdir,subStr,'task','attention','method','movie','boundaries',{'_desc-recursive_mode-surface'},...
        'axis','transversal')
    vis_surfaceCoregistration(cfg.bidsdir,subStr,'task','attention','method','movie','boundaries',{'_desc-recursive_mode-surface'},...
        'axis','coronal')
    vis_surfaceCoregistration(cfg.bidsdir,subStr,'task','attention','method','movie','boundaries',{'_desc-recursive_mode-surface'},...
        'axis','sagittal')
end