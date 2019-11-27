function debug_alignment(bidsdir,subjectlist)



for s = subjectlist
    bidspath = fullfile(bidsdir,'derivates','preprocessing',s{1},'ses-01');
    for k = 1:3
        func = fullfile(bidspath,'func','*occipitalcropMeanBias_bold.nii');
        funcinanat = fullfile(bidspath,'func','*occipitalcropMeanBias_space-ANATCROPPED_bold.nii');
        anatCropped = fullfile(bidspath,'anat','*ANAT_T1w.nii');
        anat = fullfile(bidsdir,s{1},'ses-01','anat','*_T1w.nii');
    switch k 
        case 1
            a = func;
            b = anatCropped;
        case 2 
            a = anatCropped;
            b = anat;
        case 3 
            a = anat;
            b = funcinanat;
    end
    command = ['fsleyes '  a ' ' b];
    fprintf(['\n' command '\n'])
    %system(command)  % for some reason I cannot start fsleyes directly from matlab :shrug:
end

% fsleyes anat/sub-*_ses-01_desc-occipitalcrop_T1w.nii func/sub-*_ses-01_task-sustained_desc-occipitalcropMeanBias_space-ANATCROPPED_bold.nii
% fsleyes anat/sub-*_ses-01_desc-occipitalcrop_space-ANAT_T1w.nii anat/sub-*_ses-01_desc-anatomical_T1w.nii
% fsleyes anat/sub-*_ses-01_desc-anatomical_space-FUNCCROPPED_T1w.nii func/sub-*_ses-01_task-*_desc-occipitalcropMeanBias_bold.nii

end