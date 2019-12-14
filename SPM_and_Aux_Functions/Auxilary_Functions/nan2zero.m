function vec = nan2zero( vec )
% ZERO2NAN(vec) sets all of the nans to zeros.
%--------------------------------------------------------------------------
% ARGUMENTS
% vec       A vector.
%--------------------------------------------------------------------------
% OUTPUT
% 
%--------------------------------------------------------------------------
% EXAMPLES
% nan2zero([1,5.1,0, nan, 0.0001])
%--------------------------------------------------------------------------
% AUTHOR: Sam Davenport.

vec(isnan(vec)) = 0;

end

