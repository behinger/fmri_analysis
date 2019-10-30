function cfg = pipeline_config(cfg)
% Functions for GRID/cluster evluation
cfg.loopfun = @(cfg)['cd ' cfg.scriptdir ';export task="' cfg.project '";export subjectlist="'  strjoin(cfg.subjectlist),'"; export bidsdir="' cfg.bidsdir '";'];
cfg.gridpipe_long_4cpu = sprintf('| qsub -l "nodes=1:ppn=4,walltime=22:00:00,mem=12gb" -o %s',fullfile(cfg.bidsdir,'logfiles/'));
cfg.gridpipe_long = sprintf('| qsub -l "nodes=1:walltime=22:00:00,mem=4GB,procs=1" -o %s',fullfile(cfg.bidsdir,'logfiles/'));
cfg.gridpipe_short = sprintf('| qsub -l "nodes=1:walltime=5:00:00,mem=4GB,procs=1" -o %s',fullfile(cfg.bidsdir,'logfiles/'));


cfg.loopeval = cfg.loopfun(cfg); % export variables and dirs