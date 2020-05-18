function out = calc_spmSummary(bidsdir,subjectlist,task,contrast)
for sIX= 1:length(subjectlist)
    %%
    SID = subjectlist(sIX);
    spmdatadir = fullfile(bidsdir,'derivates','spm',SID{1},'ses-01','GLM');
    
    
    nii = load_untouch_nii(fullfile(spmdatadir,task,sprintf('spmT_%04i.nii',contrast)));
    
    for maskIX = 1:3
        switch maskIX
            case 1
                mask= load_untouch_nii(fullfile(bidsdir,'derivates','tvm_layers',SID{1},'ses-01','mask',[SID{1}, '_ses-01_desc-localizer ALLTopvoxels500_roi-V1_mask.nii']));
            case 2
                mask= load_untouch_nii(fullfile(bidsdir,'derivates','tvm_layers',SID{1},'ses-01','mask',[SID{1}, '_ses-01_desc-localizer 1*clockwise+-1*counter clockwiseTopvoxels500_roi-V1_mask.nii']));
            case 3
                mask= load_untouch_nii(fullfile(bidsdir,'derivates','tvm_layers',SID{1},'ses-01','mask',[SID{1}, '_ses-01_desc-localizer -1*clockwise+1*counter clockwiseTopvoxels500_roi-V1_mask.nii']));
        end
        out(maskIX,sIX) = mean(nii.img(mask.img(:)==1));
    end
    % funcmask = load_untouch_nii(fullfile(spmdatadir,masktask,sprintf('spmT_%04i.nii',maskcontrast)))
    % spatmask = load_untouch_nii(fullfile(bidsdir,'derivates','preprocessing',SID{1},'ses-01','label',[SID{1},'_ses-01_desc-vareaV1_space-FUNCCROPPED_label.nii']))
    
    
end