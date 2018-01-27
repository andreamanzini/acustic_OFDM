function rxbits = rx_routine(rx, conf, psym_tx)
%RX_ROUTINE Translate a received audio signals to a bitstream

    % Downconvert received signal
    time = (0 : length(rx) - 1) ./ conf.fsampling;
    downconverted = 2 * ofdmlowpass(rx .* exp(-1j * 2*pi * conf.f_c * time.'), conf, conf.bw*1.5);

    % Apply matched filter to detect the beginning of data
    h = rrc(conf.os_factor, conf.rolloff, conf.filterlenght);
    filtered_rx = conv(downconverted, h, 'same');

    % Detect beginning of data
    [beginning, in_theta] = frame_sync(filtered_rx, conf.os_factor);
    % Extract transmission symbols
    cutted = downconverted(beginning : beginning + (conf.nofdm+conf.ntraining) * (conf.nsubc+conf.lpfx) * conf.os_factor - 1);

    % Group the received time symbols in corresponding OFDM symbols
    ofdm_rx = reshape(cutted, (conf.nsubc + conf.lpfx) * conf.os_factor, []);
    % Discard cyclic prefix
    ofdm_rx = ofdm_rx(conf.lpfx*conf.os_factor+1:end,:);

    % Iterate over ofdm symbols and compute fft
    psym_rx = zeros(conf.nsubc, size(ofdm_rx,2));
    for i = 1:size(psym_rx,2)
        % FFT and downsampling of the received signal
        psym_rx(:,i) = osfft(ofdm_rx(:,i), conf.os_factor);
    end

    % Estimate channel for each subcarrier
    train = -2 .* (lfsr_framesync(conf.nsubc) - 0.5);
    channel = psym_rx(:,1:conf.train_interval+1:end) ./ repmat(train,1,conf.ntraining);
    
    % Estimate real channel using all the transmitted symbols (debugging)
    real_channel = psym_rx ./ psym_tx;
    
    % Channel equalization
    compensated = psym_rx;
    [r,c]=size(psym_rx);
    theta_hat = zeros(r, c);    % phase estimation
    abs_hat = zeros(r,c);       % abs estimation
    tr = 1; % variable to count the number of training symbols
    for start = 1 : conf.train_interval+1 : c
        
        % Update the channel estimation using the training symbols
        end_slice = start+conf.train_interval;
        theta_hat(:,start) = mod(angle(channel(:,tr)), 2*pi);
        abs_hat(:,start:end_slice) = repmat(abs(channel(:,tr)), 1, end_slice-start+1);
        tr = tr + 1;
        
        % Track phase
        for slice = start+1:end_slice
           for i=1:r   
                deltaTheta = 1/4*angle(-psym_rx(i,slice)^4) + pi/2*(-1:4);

                % Unroll phase
                [~, ind] = min(abs(deltaTheta - theta_hat(i,slice-1)));
                theta = deltaTheta(ind);

                % Lowpass filter phase
                theta_hat(i,slice) = mod(0.2*theta + 0.8*theta_hat(i,slice-1), 2*pi);
           end
        end
        
       % Compensate channel
       compensated(:, start:end_slice) = psym_rx(:, start:end_slice) ./ abs_hat(:, start:end_slice);
       compensated(:, start:end_slice) = compensated(:, start:end_slice).* exp(-1j .* theta_hat(:,start:end_slice));
    end
    % Discard training symbols
    compensated(:, 1:conf.train_interval+1:end) = [];
    
    % Vectorize psym
    fsym = compensated(:);

    % Demap symbols to bits
    rxbits = [ real(fsym) > 0 imag(fsym) > 0 ];
    rxbits = reshape(rxbits', 2*length(fsym), 1);
    
    % Generate Plots
    plot_channel(channel, real_channel, theta_hat, conf);

end