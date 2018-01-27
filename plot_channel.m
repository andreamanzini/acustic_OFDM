function [ output_args ] = plot_channel( channel, real_channel, theta_hat, conf)
%PLOT_CHANNEL_EST Generate some useful plot

    % Normalize channel estimations
    channel = channel ./ repmat(max(abs(channel(:))),size(channel,1),size(channel,2));
    real_channel = real_channel ./ repmat(max(abs(real_channel(:))),size(real_channel,1),size(real_channel,2));

    % Compare channel estimation with real channel over time
    % Plot an high frequency because it's usually more difficult to track them
    sub_tracked = conf.nofdm - 10;  
    nsymbol = (1:size(real_channel,2));
    fig1 = figure;
    subplot(2,1,1);
    hold on;
    plot(nsymbol, abs(real_channel(sub_tracked,:)));
    plot(nsymbol(1:conf.train_interval+1:end), abs(channel(sub_tracked,:)), 'o');
    legend('real', 'estimated');
    title('Gain Estimation Performances');
    xlabel('ofdm_symbol');
    subplot(2,1,2);
    hold on;
    plot(nsymbol, mod(angle(real_channel(sub_tracked,:)), 2*pi) / pi);
    plot(nsymbol(1:conf.train_interval+1:end), mod(angle(channel(sub_tracked,:)), 2*pi) / pi, 'o');
    plot(nsymbol, theta_hat(sub_tracked,:) / pi, '.-');
    legend('real', 'estimated', 'tracked');
    title('Phase Estimation Performances')
    xlabel('ofdm_symbol');
    saveas(fig1, 'channel_estimation_performances.png');
    
    % Plot channel estimation over frequency
    frequencies = conf.f_c - (conf.nsubc - 1)/2 * conf.fspacing : conf.fspacing : conf.f_c + (conf.nsubc - 1)/2 * conf.fspacing;
    fig2 = figure;
    subplot(2,1,1);
    plot(frequencies, abs(channel));
    title('Channel gain');
    xlabel('Frequency [Hz]');
    subplot(2,1,2);
    plot(frequencies, unwrap(angle(channel)));
    title('Channel phase');
    xlabel('Frequency [Hz]')
    saveas(fig2,'channel_over_frequency.png');
    
    % Plot delay Spread
    fig3=figure;
    time = (0:conf.nsubc-1) ./ (conf.fsampling / conf.os_factor) * 1000;
    hold on;
    for i = 1:size(channel,2)
        y = abs(ifft(channel(:,i), 'symmetric'));
        plot(time(1:end-500), y(1:end-500) ./ max(y(:)), '.-');
    end
    title('Delay spread');
    xlabel('Time [ms]')
    saveas(fig3, 'delay_spread.png');
    
    % Plot channel for some subcarriers over time
    nsymbol = (1:size(real_channel,2));
    time = (nsymbol - 1) .* ( conf.nofdm ./ (conf.fsampling / conf.os_factor) ) * 1000;
    fig4 = figure;
    subplot(2,1,1);
    plot(time, abs(real_channel(1:200:end,:)) ./ repmat(max(abs(real_channel(1:200:end,:))), numel(1:200:size(real_channel,1)), 1) );
    title('Gain of real_channel on single subcarriers');
    xlabel('Time [ms]');
    subplot(2,1,2);
    plot(time, unwrap(angle(real_channel(1:200:end,:))));
    title('Phase of real_channel on single subcarriers')
    xlabel('Time [ms]');
    saveas(fig4, 'channel_over_time.png');

end

