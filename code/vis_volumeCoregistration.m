function vis_volumeCoregistration(bidsdir,subjectlist)
cfg = finputcheck(varargin, ...
    { 'plotLabel','string',[],'varea'
    });
if ischar(cfg)
    error(cfg)
end
error('to be implemented automatically')
% does not exist yet!

%fsleyes anat/sub-*_ses-01_desc-anatomical_space-FUNCCROPPED_T1w.nii label/sub-*_ses-01_desc-varea_space-FUNCCROPPED_label.nii func/sub-*_ses-01_task-*_desc-occipitalcropMeanBias_bold.nii

% fsleyes anat/sub-*_ses-01_desc-occipitalcrop_T1w.nii func/sub-*_ses-01_task-sustained_desc-occipitalcropMeanBias_space-ANATCROPPED_bold.nii
                 % fsleyes anat/sub-*_ses-01_desc-occipitalcrop_space-ANAT_T1w.nii anat/sub-*_ses-01_desc-anatomical_T1w.nii 
                 % fsleyes anat/sub-*_ses-01_desc-anatomical_space-FUNCCROPPED_T1w.nii func/sub-*_ses-01_task-*_desc-occipitalcropMeanBias_bold.nii