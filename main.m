clear all
close all

%% USER DEFINED CONSTANTS
% Randomization of data and encoding
conf.hamm_n = 15;   % Hamming code
conf.hamm_k = 11;   % Hamming code

conf.nsubc = 1600;
conf.f_c = 6000; % Carrier frequency
conf.fspacing = 5;
conf.fsampling = 48000;
conf.lpfx = 200; % Length in symbols of the prefix
conf.npreamble = 100;
conf.rolloff = 0.22;
conf.train_interval = 32;   % Must be divisor of conf.nofdm

% Audio configuration
conf.audiosystem = 'matlab'; % Values: 'matlab','native','bypass'
conf.nframes    = 1;       % number of frames to transmit
conf.bitsps     = 16;   % bits per audio sample
conf.offset     = 0;

%% TRANSMISSION BITS
% Read the image and extract bitstream
im = imread('lena.png');
[im_rows, im_cols, ~] = size(im);
txdata = de2bi(im, 8).';
txdata = txdata(:);

% Update configuration variables
conf.ndata = length(txdata);

% Encode and randomize bitstream
[txbits, conf] = encode_bitstream(txdata, conf);

%% DEPENDENT CONSTANTS CALCULATION
conf.bw = ceil((conf.nsubc+1)/2) * conf.fspacing;
conf.nbits = length(txbits);
conf.nsyms = conf.nbits / 2;
conf.os_factor = conf.fsampling / (conf.fspacing * conf.nsubc);
conf.ntraining = (conf.nofdm / conf.train_interval);
conf.filterlenght = 10 * conf.os_factor;    % Number of taps can be changed

%% TRANSMITTER
[tx, psym] = tx_routine(txbits, conf);

% Plot received signal for debgging
    fig = figure;
    plot(tx);
    title('Transmitted Audio')
    saveas(fig, 'audio_transmission.png');
%% AUDIO TRANSMISSION / BYPASS
    rx = audio_transmission(tx, conf, 6);
    
    %rx = simulate_channel(rx, conf);
%% RECEIVER
% The transmitted symbols are passed to the function only to produce
% graphs. Receiver and transmitter are completely independent
rxbits = rx_routine(rx, conf, psym);

% Extract databits, decode and derandomize
derandomized = xor(rxbits(1:conf.nencoded), lfsr_framesync(conf.nencoded));
decoded = decode(reshape(derandomized, conf.hamm_n, []).', conf.hamm_n, conf.hamm_k).';
rxdata = decoded(1:conf.ndata).';

%% EVALUATE PERFORMANCES
% Compute BER
disp(['BER on the raw bits: ', num2str(mean(rxbits ~= txbits))]);
disp(['BER on the data bits: ', num2str(mean(rxdata ~= txdata))]);

% Reconstruct and show image
rxdata = reshape(rxdata, 8, []).';
im = uint8(bi2de(rxdata));
im = reshape(im, im_rows, im_cols);
im_fig = figure;
imshow(im);
imwrite(im, 'lena_out.png');

