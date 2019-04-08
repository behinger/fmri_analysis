
function safeQuit(cfg)

% Close window
Screen('Close');
Screen('Closeall');
%
% Clean up
try
    jheapcl; % clean the java heap space
catch
    disp('Could not clean java heap space');
end
cfg.bitsi_buttonbox.close
cfg.bitsi_scanner.close
disp('Quit safely');
end