function Y = osfft(X,OS_FACTOR)
%   OSFFT(X,OS_FACTOR) is the inverse transform of X with a over sampling 
%   factor of OS_FACTOR.
%
%   OS_FACTOR = f_sampling / (f_spacing * N)
%
Nos = length(X);

N = Nos / OS_FACTOR;

center = ceil(N/2);

assert(mod(N,1) == 0)

Y = zeros(N,1);

YL = fft(X);

Y(1:center)        = YL(end-center+1:end);
Y(center+1:end)    = YL(1:(N-center));