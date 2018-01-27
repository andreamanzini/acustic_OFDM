function [txbits, conf] = encode_bitstream(txdata, conf)
%ENCODE_BITSTREAM Encode the data bits with the specified Hamming code and add a
%randomization of the final bits to avoid peaks in time domain.

    % Insert padding into the txdata to align with hamming encoding
    padded = zeros(ceil(conf.ndata / conf.hamm_k) * conf.hamm_k, 1);
    padded(1:conf.ndata) = txdata;
    padded = reshape(padded, conf.hamm_k, []).';
    encoded = encode(padded, conf.hamm_n, conf.hamm_k).';
    
    % Update configuration variables
    conf.nencoded = numel(encoded);
    conf.nofdm = ceil(conf.nencoded / 2 / conf.nsubc);
    
    % Randomize txdata in order to reduce peaks in time domain
    randomized = xor(encoded(:), lfsr_framesync(conf.nencoded));
    
    % Insert padding to align with the ofdm symbol length
    % The padding is random and not zero to avoid peaks
    txbits = randi([0,1], conf.nofdm * conf.nsubc * 2, 1);
    txbits(1:conf.nencoded) = randomized;

end

