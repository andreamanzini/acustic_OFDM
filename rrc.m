function h = rrc(os_factor, rolloff_factor, filterlength)
% Returns a the FIR coefficients of a Root Raised Cosine filter.
% os_factor is the oversampling factor, typically set to 4.
% rolloff_factor is a in [0; 1]. UMTS for instance uses a rolloff factor of 0.22.
% filterlength is the _onesided_ filterlength, i.e. the total number of taps is 2*filterlength+1.
%
% Note that the current implementation of this function does not handle the case when the denominator becomes zero,
% which means that the rolloff_factor must be chosen so that os_factor/(4*rolloff_factor) is not be an integer.
% In this case, choose a slightly different rolloff factor, or fix this implementation...

n = (-filterlength : filterlength)' / os_factor;

if rolloff_factor == 0, % special case, just return a sinc
	h = sinc(n);
else
	if floor(os_factor/(4*rolloff_factor)) == os_factor/(4*rolloff_factor), error('os_factor/(4*rolloff_factor) must not be an integer.'); end
	h = (4*rolloff_factor/pi * cos((1+rolloff_factor)*pi*n) + (1-rolloff_factor)*sinc((1-rolloff_factor)*n)) ./ (1 - (4*rolloff_factor*n).^2);
end

% Normalize to a total power of 1.
h = h / sqrt(sum(abs(h).^2));