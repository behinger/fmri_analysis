function manual_cropOccipital(bidsdir,subjectlist)
% Function that will plot the anatomical + functional and allow you to crop
% them to the occipital cortex.
% It  will then save them in a cropmarks_occipital.mat file and apply them
% using calc_cropOccipital
f_cropmark = fullfile(bidsdir,'derivates','preprocessing','cropmarks_occipital.mat');

for SID = subjectlist
    if exist(f_cropmark,'file')
        crop = load(f_cropmark);
        crop = crop.crop;
    else
        crop = table({},[],[],'VariableNames',{'SID','anat','func'});
    end
    
    ix = find(strcmp(SID{1},crop.SID));
    if ~isempty(ix)
        t_sub = crop(ix,:);
    else
        d = dir(fullfile(bidsdir,SID{1}, 'ses-01','anat',[SID{1} '_ses-01_*_T1w.nii']));
        spm_image('display',fullfile(d.folder,d.name))
        tmp_a = input('Subject not found, adding it to table. Anat {X:X, Y:Y, Z:Z}:');
        
        d = dir(fullfile(bidsdir,SID{1}, 'ses-01','func',[SID{1} '_ses-01_*_bold.nii']));
        spm_image('display',fullfile(d(1).folder,d(1).name))
        
        tmp_f = input('Subject not found, adding it to table. Func {X:X, Y:Y, Z:Z}:');
        t_sub = table(SID(1),tmp_a,tmp_f,'VariableNames',{'SID','anat','func'});
        
        % concatenate to already loaded and save changes
        crop = [crop; t_sub];
        save(f_cropmark,'crop')
    end
    calc_cropOccipital(bidsdir,SID{1},t_sub)
    
end