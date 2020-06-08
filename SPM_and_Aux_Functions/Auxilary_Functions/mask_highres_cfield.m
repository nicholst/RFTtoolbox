function [ out ] = mask_highres_cfield( mask, resadd, enlarge )
% MASK_HIGHRES_CFIELD( mask, resadd, enlarge )
%--------------------------------------------------------------------------
% ARGUMENTS
% Mandatory
%   mask 
%   resadd
%--------------------------------------------------------------------------
% OUTPUT
%   mask_hr
%--------------------------------------------------------------------------
% EXAMPLES
% 
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport
%--------------------------------------------------------------------------

%%  Check mandatory input and get important constants
%--------------------------------------------------------------------------
% Get dimensions
Dim = size(mask); D = length(Dim);

%%  add/check optional values
%--------------------------------------------------------------------------
if ~exist( 'enlarge', 'var' )
   % default option of enlarge
   enlarge = ceil(resadd/2);
end

%%  Main Function Loop
%--------------------------------------------------------------------------
% Get the box kernel
RK = @(y)boxker(y, 0.5, 1);

mask_hr = convfield_dep(mask, RK, resadd, D, 0, enlarge)

end
