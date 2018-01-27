function rx = simulate_channel(rx, conf)
%SIMULATE_CHANNEL Simulate a channel with a double convolution

    rx = conv(rx, exp(linspace(0,-3,800)));
    ch = zeros(1000,1);
    ch(1:100:end) = exp(linspace(0,-1,10));
    rx = conv(rx, ch);

end

