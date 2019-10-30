function vis_volumeCoregistration(bidsdir,subjectlist,varargin)
cfg = finputcheck(varargin, ...
    { 'plotLabel','string',[],''
    });
if ischar(cfg)
    error(cfg)
end





for s = subjectlist
    bidspath = fullfile(bidsdir,'derivates','preprocessing',s{1},'ses-01');
    command = ['fsleyes ' fullfile(bidspath,'func','*occipitalcropMeanBias_bold.nii') ...
        ' ' fullfile(bidspath,'anat','*FUNCCROPPED_T1w.nii')];
    if ~isempty(cfg.plotLabel)
        command = [command ' ' fullfile(bidspath,'label',sprintf('*desc-%s_*FUNCCROPPED_label.nii',cfg.plotLabel))];
    end
    
    fprintf(command)
    %system(command)  % for some reason I cannot start fsleyes directly from matlab :shrug:
end

% fsleyes anat/sub-*_ses-01_desc-occipitalcrop_T1w.nii func/sub-*_ses-01_task-sustained_desc-occipitalcropMeanBias_space-ANATCROPPED_bold.nii
% fsleyes anat/sub-*_ses-01_desc-occipitalcrop_space-ANAT_T1w.nii anat/sub-*_ses-01_desc-anatomical_T1w.nii
% fsleyes anat/sub-*_ses-01_desc-anatomical_space-FUNCCROPPED_T1w.nii func/sub-*_ses-01_task-*_desc-occipitalcropMeanBias_bold.nii