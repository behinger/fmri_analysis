function allDat = calc_erb(act,events_onset,TR,fromTo)


allDat = [];
for block = 1:height(events_onset)
    tmp = events_onset(block,:);
    ix_time = (fromTo(1):fromTo(2))/TR;%-3/TR:1/TR:TR:20/TR;
    ix_time = unique(round(ix_time))*TR;
    ix_tr = unique(round(ix_time/TR + tmp.onsetTR));
    
    erb = nan(1,length(ix_tr));
    erb(ix_tr>0 & ix_tr<=size(act,2)) = act(tmp.run,max(1,ix_tr(1)):min(size(act,2),ix_tr(end)));
    
    
    % bslcorrect =@(x,times)bsxfun(@minus,x,mean(x(:,times>=28 & times <=30),2));
    erb_bsl = erb - mean(erb(ix_time>=-1.5 & ix_time <=1.5));
    tmpOut = [];
    for k = 1:length(ix_tr)
        
    tmp.erb = erb(k);
    tmp.erb_bsl = erb_bsl(k);
    tmp.time = ix_time(k);
    tmpOut = [tmpOut;tmp];
    end
    allDat = [allDat;tmpOut];
end

