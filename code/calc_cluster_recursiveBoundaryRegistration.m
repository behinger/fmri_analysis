% Recursive boundary registration (non-linear distortion correction) to
% align freesurfer boundaries to functional data
function calc_cluster_recursiveBoundaryRegistration(datadir,subjectlist,varargin)
cfg = finputcheck(varargin, ...
    { 'task','string',[],'WM'
    });
if ischar(cfg)
    error(cfg)
end

% Subjects to process

registrationConfiguration = cell(length(subjectlist), 1);
subjectConfigurations = cell(length(subjectlist), 1);

% Push on grid
memoryRequirement = 300 * 1024 ^ 2; %300MB
timeRequirement = 20 * 600; %2 hours 
compilation = 'no';

for SID = 1:length(subjectlist)
    % Relaignment configuration - using settings from petkok's code, assuming
    % they are fine...
    
    
    p_meanrun= dir(fullfile(datadir,'derivates','preprocessing',subjectlist{SID},'ses-01','func',sprintf('*task-%s*_desc-occipitalcropMean_bold.nii',cfg.task)));
    p_meanrun = dir(fullfile(datadir,'derivates','preprocessing',subjectlist{SID},'ses-01','anat', [subjectlist{SID},'_ses-01_desc-IrEPImasked_space-FUNCCROPPED.nii']));

    assert(~isempty(p_meanrun))
    i_boundaries= fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANAT_to-FUNCCROPPED_desc-BBR_mode-surface.mat']);
%     warning(' MODIFIED TO NOT USE BBR BUT SPM SURFACE')
%     i_boundaries= fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANAT_to-FUNCCROPPED_mode-surface.mat']);
    %formerly: sub-003_ses-01_from-ANATCROPPED_to-FUNCCROPPED_mode-surface
    o_boundaries= fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface.mat']);

    

    
    configuration = [];
    configuration.i_SubjectDirectory = fullfile(datadir,'derivates');
    configuration.i_ReferenceVolume = fullfile('preprocessing',subjectlist{SID},'ses-01','anat',p_meanrun.name); %fullfile('../',subjectlist{SID},'ses-01','extra_data', 'flip40_10_masked_bet.nii');
    %xxx

    configuration.i_Boundaries = i_boundaries;
    configuration.o_Boundaries = o_boundaries;
    
    subjectConfigurations{SID} = configuration;
    
    configuration = [];
    configuration.ReverseContrast       = true;
    configuration.ContrastMethod        = 'gradient';
    configuration.OptimisationMethod    = 'GreveFischl';
    configuration.Mode                  = 'rsxt';
    configuration.NumberOfIterations    = 6; % 6 = default, 8 = recommended for whole brain.
    configuration.Accuracy              = 30;
    configuration.DynamicAccuracy       = true;
    configuration.MultipleLoops         = true;
    configuration.qsub                  = false;
    configuration.Display              	= 'on';
    
    registrationConfiguration{SID} = configuration;
          
    clear configuration; 
%     tvm_recursiveBoundaryRegistration(subjectConfigurations{SID}, registrationConfiguration{SID})
    qsubfeval(@tvm_recursiveBoundaryRegistration, subjectConfigurations{SID}, registrationConfiguration{SID}, 'memreq', memoryRequirement, 'timreq', timeRequirement, 'compile', compilation);
end



