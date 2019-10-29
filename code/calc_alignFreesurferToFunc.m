% Align Freesurfer surface to functional data
function calc_alignFreesurferToFunc(datadir,subjectlist,varargin)
cfg = finputcheck(varargin, ...
    { 'task','string',[],'sustained'
    });
for SID = 1:length(subjectlist)
    % Relaignment configuration - using settings from petkok's code, assuming
    % they are fine...
    realignmentConfiguration = [];
    realignmentConfiguration.sep = [2 1];
    realignmentConfiguration.cost_fun = 'nmi';
    realignmentConfiguration.tol = [0.02 0.02 0.02 0.001 0.001 0.001];
    realignmentConfiguration.fwhm = [7 7];
    realignmentConfiguration.graphics = 0;
    %realignmentConfiguration.params = [0 0 0 0 0 0]; % default
    realignmentConfiguration.params = [-15 10 10 0 0 0]; % petkok option 
    
    configuration = [];
    configuration.i_SubjectDirectory = fullfile(datadir,'derivates');
    configuration.i_FreeSurferFolder = fullfile('freesurfer',subjectlist{SID},'ses-01');
    %configuration.i_FreeSurferFolder = 'Freesurfer_retinotopy/'; % Switch
    %to this if using MPRAGE (no MP2RAGE)
    

    p_meanrun= dir(fullfile(datadir,'derivates','preprocessing',subjectlist{SID},'ses-01','func',sprintf('*task-%s_acq-rsep3d08mmipat4x2partialbrain_desc-occipitalcropMean_bold.nii',cfg.task)));
%     p_meanrun= dir(fullfile(datadir,'derivates','preprocessing',subjectlist{SID},'ses-01','func',sprintf('*task-WM*_desc-occipitalcropMean_bold.nii')));

    if length(p_meanrun) ~=1
        error('could not find mean functional')
    end
    p_corrMat   = fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANAT_to-FUNCCROPPED_mode-image.mat']);
    p_boundaries= fullfile('preprocessing',subjectlist{SID},'ses-01','coreg',[subjectlist{SID} '_ses-01_from-ANAT_to-FUNCCROPPED_mode-surface.mat']);

    configuration.i_ReferenceVolume = fullfile('preprocessing',subjectlist{SID},'ses-01','func',p_meanrun.name);
    configuration.o_CoregistrationMatrix = p_corrMat;
    configuration.o_Boundaries = p_boundaries;
    
    tvm_registerVolumes(configuration,realignmentConfiguration);
    
    clear configuration; clear realignmentConfiguration;
end

