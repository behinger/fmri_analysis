function ContrastAnalysis_angles(subject,numWM,numloc)

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

timecourse135_name = {};
timecourse45_name = {};

for wm_num = 1:numloc
    timecourse135_name{wm_num} = dir(fullfile(timecourseDir, [subject,'_ses-01_desc-localizer_Topvoxels-500_1*135+-1*45_roi-V1_task-localizer_run-',num2str(wm_num),'_desc-preproc-zscore_timecourse.mat']))
    timecourse45_name{wm_num} = dir(fullfile(timecourseDir, [subject,'_ses-01_desc-localizer_Topvoxels-500_-1*135+1*45_roi-V1_task-localizer_run-',num2str(wm_num),'_desc-preproc-zscore_timecourse.mat']))
end

timecourse135 = {};
timecourse45 = {};

for i = 1:length(timecourse135_name)
    timecourse135_new = load(timecourse135_name{i}.name);
    timecourse135_new = timecourse135_new.timeCourses{1, 1};  
    timecourse135{i} = timecourse135_new;
    timecourse45_new = load(timecourse45_name{i}.name);
    timecourse45_new = timecourse45_new.timeCourses{1, 1};      
    timecourse45{i} = timecourse45_new;
end

for ii = 1:length(timecourse135)
    timecourse135{ii} = timecourse135{ii}(2:4,4:259,:);
    timecourse135{ii} = reshape(timecourse135{ii},3,8,32);
    timecourse45{ii} = timecourse45{ii}(2:4,4:259,:); 
    timecourse45{ii} = reshape(timecourse45{ii},3,8,32);
end

contrast_params = [];
for con =1:2
    load(['WM_Localiser_S',subject2,'_Contrast_',num2str(con)])
    contrast_params = [contrast_params;params.contrast]
end

contrast_params = [contrast_params(1,1),contrast_params(1,1),contrast_params(1,2),contrast_params(1,2);contrast_params(2,1),contrast_params(2,1),contrast_params(2,2),contrast_params(2,2)];

scanProp_r1 = repmat([contrast_params(1,:)],1,8)
scanProp_r2 = repmat([contrast_params(2,:)],1,8)
scanProp = [scanProp_r1 ;scanProp_r2];

scanWM = repmat([45,135],2,16);

timecourseHigh = [];
timecourseLow = [];

h=1;
l=1;
for run = 1:numloc
    for trial = 1:length(scanProp)
        if scanProp(run,trial) == 0.3
            if scanWM(run,trial) == 45
                timecourseLow(:,:,l) = timecourse45{run}(:,:,trial)
                l = l+1
            elseif scanWM(run,trial) == 135
                timecourseLow(:,:,l) = timecourse135{run}(:,:,trial)
                l= l+1
            end
        elseif scanProp(run,trial) == 0.8
            if scanWM(run,trial) == 45
                timecourseHigh(:,:,h) = timecourse45{run}(:,:,trial)
                h = h+1
            elseif scanWM(run,trial) == 135
                timecourseHigh(:,:,h) = timecourse135{run}(:,:,trial)
                h = h+1
            end 
        end
    end
end

figure(1)
title('Average High Low')
plot(1:8,mean(mean(timecourseHigh,3)))
hold on
plot(1:8,mean(mean(timecourseLow,3)))
legend('high', 'low')


AVhigh = mean(timecourseHigh,3);
AVlow = mean(timecourseLow,3);
SEhigh = std(timecourseHigh,[],3)/sqrt(32*numloc); 
SElow = std(timecourseLow,[],3)/sqrt(32*numloc);

AVhigh = mean(AVhigh(:,2:5),2); 
AVlow = AVlow(:,2:5); 
SEhigh = mean(SEhigh(:,2:5),2);
SElow = SElow(:,2:5);


ContrastEffect = mean(AVhigh,2)-mean(AVlow,2);
ContrastEffectSE = (mean(SEhigh,2)+mean(SElow,2))/2

figure(2)
title('Contrast Effect')
bar(AVhigh)
errorbar(AVhigh,SEhigh)
xlim([0 4])
legend('TR 2:5')

save([subject,'_contrastAngles'])



end



