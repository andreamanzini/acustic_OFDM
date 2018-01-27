function Y = osifft(X,OS_FACTOR)
%   OSIFFT(X,,f_sp,f_s) is the inverse transform of X with an over sampling 
%   factor of OS_FACTOR.
%
%   OS_FACTOR = f_sampling / (f_spacing * N)
%
N = length(X);

XL = zeros(N*OS_FACTOR,1);

center = ceil(N/2);

XL(1:(N-center))     = X(center+1:end);
XL(end-center+1:end) = X(1:center);

Y = ifft(XL);