function vis_surfaceCoregistration(bidsdir,subjectlist)
% plots various surfaceCoregistration things. Also maybe in the future add
% a movie

plot_surfaceCoregistration(bidsdir,subjectlist{1},'boundary_identifier','%s_ses-01_from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface','axis','z','task','sequential')

plot_surfaceCoregistration(bidsdir,subjectlist{1},'boundary_identifier','%s_ses-01_from-ANAT_to-FUNCCROPPED_mode-surface','axis','z','task','sequential')
plot_surfaceCoregistration(bidsdir,subjectlist{1},'boundary_identifier','%s_ses-01_from-ANAT_to-FUNCCROPPED_desc-BBR_mode-surface','axis','z','task','sequential')
plot_surfaceCoregistration(bidsdir,subjectlist{1},'boundary_identifier','%s_ses-01_from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface','axis','z','task','sequential')
%                 Step9_visualiseRecursiveRegistration(bidsdir,subjectlist,'slicelist',23,'boundary_identifier','Anat2FuncBoundaries_recurs_sam','functional_identifier','meanWM_run1_sam.nii')

% 
% p_meanrun= dir(fullfile(bidsdir,'derivates','preprocessing',subjectlist{1},'ses-01','func',sprintf('*task-%s*_desc-occipitalcropMeanBias_bold.nii','sustained')));
% boundaries = dir(fullfile(bidsdir,'derivates','preprocessing',subjectlist{1},'ses-01','coreg','*_ses-01_from-ANATCROPPED_to-FUNCCROPPED_desc-BBR_mode-surface.mat'))
% config = struct('i_SubjectDirectory',fullfile(bidsdir,'derivates'),...
%     'i_ReferenceVolume',fullfile('preprocessing',subjectlist{1},'ses-01','func',p_meanrun.name),...
%     'i_Boundaries',fullfile('preprocessing',subjectlist{1},'ses-01','coreg',boundaries.name),...
%     'o_RegistrationMovie','test_bbr.mp4')
% config.i_Boundaries = {config.i_Boundaries}
% tvm_makeRegistrationMovieWithMoreBoundaries(config)
%
%
%
%                  p_meanrun= dir(fullfile(bidsdir,'derivates','preprocessing',subjectlist{1},'ses-01','func',sprintf('*task-%s*_desc-occipitalcropMeanBias_bold.nii','sustained')));
%                 anat= dir(fullfile(bidsdir,'derivates','preprocessing',subjectlist{1},'ses-01','anat','sub*_ses-01_desc-anatomical_T1w.nii'))
%                 coreg= dir(fullfile(bidsdir,'derivates','preprocessing',subjectlist{1},'ses-01','coreg','*_ses-01_from-ANAT_to-FUNCCROPPED_mode-image.mat'))
%                 [~,outname,~] = fileparts(coreg.name);
%                 config = struct('i_SubjectDirectory',fullfile(bidsdir,'derivates'),...
%                     'i_MoveVolumes',     fullfile('preprocessing',subjectlist{1},'ses-01','label','sub-01_ses-01_desc-varealabel_space-ANAT_label.nii'),...
%                     'i_ReferenceVolume',          fullfile('preprocessing',subjectlist{1},'ses-01','anat',anat.name),...
%                     'i_CoregistrationMatrix',fullfile('preprocessing',subjectlist{1},'ses-01','coreg',coreg.name),...
%                     'i_InverseRegistration',true,...
%                     'i_InterpolationMethod','NearestNeighbours',...
%                     'o_OutputVolumes',         fullfile('preprocessing',subjectlist{1},'ses-01','label_in_anat.nii'))
%
%                 tvm_resliceVolume(config)