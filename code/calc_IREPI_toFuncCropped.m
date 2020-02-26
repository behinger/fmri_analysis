function calc_IREPI_toFuncCropped(bidsdir,subjectlist)

error('dont use deprecated'
warning('Karolis! Replace this file')
f_cropmark = fullfile(bidsdir,'derivates','preprocessing','cropmarks_occipital_sub003.mat');
crop = load(f_cropmark);
crop = crop.crop;





for SID = subjectlist
    anatdir = fullfile(bidsdir,'derivates','preprocessing',SID{1},'ses-01','anat');
    i_filename = fullfile(anatdir,[SID{1},'_ses-01_desc-IrEPImasked.nii']);
    i_filename = fullfile(anatdir,'../func',[SID{1},'_ses-01_task-WM_desc-occipitalcropMeanBias_bold.nii']);
    o_filename = fullfile(anatdir,[SID{1},'_ses-01_desc-IrEPImasked_space-FUNCCROPPED.nii']);
    
    ix = find(strcmp(SID{1},crop.SID));
    
    t_sub = crop(ix,:);
    
    
    
    vols = spm_vol(i_filename);
    
    for iVol = 1:length(vols)
        %%
        oldVol = vols(iVol);
        img = spm_read_vols(vols(iVol));
        
        newVol = oldVol;
        newVol.fname = o_filename;
        
        shiftBy = [t_sub.func{1}(1) t_sub.func{2}(1) t_sub.func{3}(1)];
        shiftBy
%         shiftBy = [35 -20 0]
        newVol.mat(1:3,4) = newVol.mat(1:3,4) + shiftBy'-1;
               
        spm_write_vol(newVol,img);
    end
    
    
end
