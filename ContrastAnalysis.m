function ContrastAnalysis(subject,numWM,numloc)

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




% contrast_name = dir(fullfile(timecourseDir, '*desc-preproc-zscore-tweight-localizer -1*0.3+1*0.8Thresh0_-localizer -1*0.3+1*0.8Thresh0_timecourse.mat'));
contrast_name = {};
for loc_num = 1:numloc
    contrast_name{loc_num} = dir(fullfile(timecourseDir, [subject,'_ses-01_desc-localizer_Topvoxels-500_ALL_roi-V1_task-localizer_run-',num2str(loc_num),'_desc-preproc-zscore-tweight_timecourse.mat']));
%     contrast_name{loc_num} = dir(fullfile(timecourseDir, [subject,'_ses-01_desc-localizer_Topvoxels-500_-1*03+1*08_roi-V1_task-localizer_run-',num2str(loc_num),'_desc-preproc-zscore-tweight_timecourse.mat']));

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

contrast_params = [contrast_params(1,1),contrast_params(1,1),contrast_params(1,2),contrast_params(1,2);contrast_params(2,1),contrast_params(2,1),contrast_params(2,2),contrast_params(2,2)];

scanProp_r1 = repmat([contrast_params(1,:)],1,8)
scanProp_r2 = repmat([contrast_params(2,:)],1,8)
scanProp = [scanProp_r1 ;scanProp_r2];

high = ones(3,8,32);
low = ones(3,8,32);

h = 1;
l = 1;

for t = 1:size(scanProp,1)
    for tt = 1:size(scanProp,2)
        if scanProp(t,tt) == 0.8
            high(:,:,h) = contrast{t}(:,:,tt);
            h = h+1;
        elseif scanProp(t,tt) == 0.3
            low(:,:,l) = contrast{t}(:,:,tt);
            l = l+1;
        end
    end
end



figure(1)
title('Average High Low')
plot(1:8,mean(mean(high,3)))
hold on
plot(1:8,mean(mean(low,3)))
legend('high', 'low')



AVhigh = mean(high,3);
AVlow = mean(low,3);
SEhigh = std(high,[],3)/sqrt(16*numloc); %taking into account the 4 TRs that im averaging across
SElow = std(low,[],3)/sqrt(16*numloc);

% % AVhigh = AVhigh(:,2:4); 
% % AVlow = AVlow(:,2:4); 
% % SEhigh = SEhigh(:,2:4);
% % SElow = SElow(:,2:4);

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

save([subject,'_contrast'])

end

