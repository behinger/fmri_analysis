function vis_surfaceCoregistration(bidsdir,subjectlist,varargin)
% plots various surfaceCoregistration things. Also maybe in the future add
% a movie
cfg = finputcheck(varargin, ...
    { 'task','string',[],'sustained'
    'method','string',{'movie','2d'},'surfaceOnSlice'
    'axis','string',{'coronal','sagittal','transversal','x','y','z'},'transversal'
    });
if ischar(cfg)
    error(cfg)
end


for boundary = {'_mode-surface';'_desc-BBR_mode-surface';'_desc-recursive_mode-surface'}'
    loop_boundaryIdentifier = ['%s_ses-01_from-ANAT_to-FUNCCROPPED' boundary{1}];
    
    plot_surfaceCoregistration(bidsdir,subjectlist{1},'boundary_identifier',loop_boundaryIdentifier,...
        'axis',cfg.axis,'task',cfg.task,'method',cfg.method)
    
end
