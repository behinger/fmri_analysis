function ContrastAnalysis_new(subject,numWM,numloc)

subject1 = subject(5:end)
if subject(6) == '0'
    subject2 = subject(7);
else
    subject2 = subject(6:7);
end


timecourseDir = ['/project/3018012.20/data/bids/derivates/tvm_layers/sub-',subject1,'/ses-01/timecourse'];
behDir = ['/project/3018012.20/Replication3T_ExpCode/Working_memory_experiment/MRI_data/s',subject2];
addpath(timecourseDir)
addpath(behDir)

contrast_name = {};
for loc_num = 1:numloc
    contrast_name{loc_num} = dir(fullfile(timecourseDir, [subject,'_ses-01_desc-localizer_Topvoxels-500_-1*03+1*08_roi-V1_task-localizer_run-',num2str(loc_num),'_desc-preproc-zscore-tweight_timecourse.mat']));
end

contrast = {};

for i = 1:numloc
    contrast_new = load(contrast_name{i}.name)
    contrast_new = contrast_new.timeCourses{1, 1}
    contrast{i}=contrast_new
end

for ii = 1:2
    contrast{ii} = contrast{ii}(2:4,4:259,:);
    contrast{ii} = reshape(contrast{ii},3,8,32);
end

contrast_params = [];
for con =1:2
    load(['WM_Localiser_S',subject2,'_Contrast_',num2str(con)])
    contrast_params = [contrast_params;params.contrast]
end

scanProp_r1 = repmat([contrast_params(1,:)],1,16)
scanProp_r2 = repmat([contrast_params(2,:)],1,16)
scanProp = [scanProp_r1 ;scanProp_r2];

timecourseHigh = [];
timecourseLow = [];

for run = 1:numloc
    for trial = 1:length(scanProp)
        if scanProp(run,trial) == 0.3
            timecourseLow = [timecourseLow;contrast{run}(:,:,trial)]
        elseif scanProp(run,trial) == 0.8
            timecourseHigh = [timecourseHigh; contrast{run}(:,:,trial)]
        end
    end
end

timecourseLow = reshape(timecourseLow,32,3,8)
timecourseHigh = reshape(timecourseHigh,32,3,8)

figure(1)
title('Average High Low')
plot(1:8,reshape(mean(mean(timecourseHigh)),8,1,1))
hold on
plot(1:8,reshape(mean(mean(timecourseLow)),8,1,1))
legend('high', 'low')



