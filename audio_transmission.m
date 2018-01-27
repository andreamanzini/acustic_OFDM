function rx = audio_transmission(tx, conf, bypass_snr)
% Audio stream preparation, transmission and recording

    % normalize values
    peakvalue       = max(abs(tx));
    normtxsignal    = tx / ((peakvalue) + 0.05);
    
    % create vector for transmission
    paddedtx = [ zeros(conf.fsampling*2,1) ; normtxsignal ;  zeros(conf.fsampling,1) ]; % add padding before and after the signal
    rawtxsignal = [  paddedtx zeros(size(paddedtx)) ]; % add second channel: no signal
    txdur       = length(rawtxsignal)/conf.fsampling; % calculate length of transmitted signal
    
%     wavwrite(rawtxsignal,conf.fsampling,16,'out.wav')   
    audiowrite('out.wav',rawtxsignal,conf.fsampling)  
    
    % Platform native audio mode 
    if strcmp(conf.audiosystem,'native')
        
        % Windows WAV mode 
        if ispc()
            disp('Windows WAV');
            wavplay(rawtxsignal,conf.fsampling,'async');
            disp('Recording in Progress');
            rawrxsignal = wavrecord((txdur+1)*conf.fsampling,conf.fsampling);
            disp('Recording complete')
            rx = rawrxsignal(1:end,1);

        % ALSA WAV mode 
        elseif isunix()
            disp('Linux ALSA');
            cmd = sprintf('arecord -c 2 -r %d -f s16_le  -d %d in.wav &',conf.fsampling,ceil(txdur)+1);
            system(cmd); 
            disp('Recording in Progress');
            system('aplay  out.wav')
            pause(2);
            disp('Recording complete')
            rawrxsignal = wavread('in.wav');
            rx    = rawrxsignal(1:end,1);
        end
        
    % MATLAB audio mode
    elseif strcmp(conf.audiosystem,'matlab')
        disp('MATLAB generic');
        playobj = audioplayer(rawtxsignal,conf.fsampling,conf.bitsps);
        recobj  = audiorecorder(conf.fsampling,conf.bitsps,1);
        record(recobj);
        disp('Recording in Progress');
        playblocking(playobj)
        pause(0.5);
        stop(recobj);
        disp('Recording complete')
        rawrxsignal  = getaudiodata(recobj,'int16');
        rx     = double(rawrxsignal(1:end))/double(intmax('int16')) ;
        
    elseif strcmp(conf.audiosystem,'bypass')
        rawrxsignal = awgn(rawtxsignal(:,1), bypass_snr, 'measured');
        rx = rawrxsignal;
    end
end

