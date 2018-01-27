function [tx, psym] = tx_routine(txbits, conf)
%TX_ROUTINE Prepare the bitstream for transmission

    % Map QPSK symbols
    symbols = ((2*txbits(1:2:end)-1) + 1j*(2*txbits(2:2:end)-1));
    % Normalize power
    symbols = symbols/(sqrt(2));
    
    % Insert training symbols
    % Reshape symbols to insert train every train_interval symbols
    psym = reshape(symbols, conf.nsubc * conf.train_interval, []);
    % Insert training symbols
    train = -2 .* (lfsr_framesync(conf.nsubc) - 0.5);
    trained = vertcat(repmat(train, 1, size(psym, 2)), psym);
    % Build ofdm symbols matrix. Rows are ofdm symbols
    psym = reshape(trained, conf.nsubc, []);

    % Iterate over each OFDM symbols in a for loop
    ofdm_sym = zeros(conf.nsubc * conf.os_factor, size(psym,2));
    for i = 1:size(psym,2)
        % IFFT trasform and upsampling of the current OFDM symbol
        ofdm_sym(:,i) = osifft(psym(:,i), conf.os_factor);
    end

    % Add cyclic prefix
    pfx_added = vertcat(ofdm_sym(end-conf.lpfx*conf.os_factor+1:end, :), ofdm_sym);

    % Serialize ofdm symbols in time
    ofdm_vec = pfx_added(:);

    % Generate preamble with BPSK encoding
    preamble = -2 .* (lfsr_framesync(conf.npreamble) - 0.5);
    % Scale preamble to the maximum ofdm power
    preamble = preamble ./ max(preamble) .* max(abs(ofdm_vec));

    % Upsampling of preamble sequence
    upsampled = zeros(conf.npreamble * conf.os_factor, 1);
    upsampled(1:conf.os_factor:end) = preamble;

    % Tx pulse shaping of premble sequence
    h = rrc(conf.os_factor, conf.rolloff, conf.filterlenght);
    tx_filtered = conv(upsampled, h, 'same');

    % Add preamble to the ofdm symbols in time
    baseband = [tx_filtered; ofdm_vec];
    
    % Upconversion of signal
    time = (0 : length(baseband) - 1) ./ conf.fsampling;
    tx = real(baseband .* exp(1j * 2*pi * conf.f_c * time.'));

end

