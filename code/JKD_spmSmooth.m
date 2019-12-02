function JKD_spmSmooth(bidsdir,subjectlist,varargin)

cfg = finputcheck(varargin, ...
    {
    'task'             'string',   {'localizer','WM'}    [];... % rois from benson17 (V1=1,V2=2,V3=3)
    'FWHM','real',[], 4.0
    });

if ischar(cfg)
    error(cfg)
end    
    
for SID = subjectlist
    
    
    SID = SID{1};
    
    
    niftis = [dir(fullfile(bidsdir,'derivates','preprocessing',SID,'ses-01','func',sprintf('*task-%s*run-*Realign_bold.nii',cfg.task)))];
    for run = 1:2
        
        matlabbatch{run}.spm.spatial.smooth.data = {fullfile(niftis(run).folder,niftis(run).name)};
        matlabbatch{run}.spm.spatial.smooth.fwhm = [cfg.FWHM cfg.FWHM cfg.FWHM];
        matlabbatch{run}.spm.spatial.smooth.dtype = 0;
        matlabbatch{run}.spm.spatial.smooth.im = 0;
        matlabbatch{run}.spm.spatial.smooth.prefix = 's';
    end
    spm_jobman('run',matlabbatch);

end
end