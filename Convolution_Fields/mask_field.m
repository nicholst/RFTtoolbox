function mfield_out = mask_field( x, mask, xvals_vecs, asnan )
% MASK_FIELD( x, mask, xvals_vecs, asnan ) generates an indicator of
% whether a given point x is within 0.5 distance of a voxel that lies in
% the mask. Note that mask_field (like the applyconvfields) is designed to
% be used locally. If you would like to generate a high resolution mask 
% over the whole field you should use mask_highres
%--------------------------------------------------------------------------
% ARGUMENTS
% Mandatory
%  x
%  mask
% Optional
%  xvals_vecs
%  asnan
%--------------------------------------------------------------------------
% OUTPUT
% 
%--------------------------------------------------------------------------
% EXAMPLES
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport
%--------------------------------------------------------------------------
if nargin < 4
    asnan = 1;
end

% Let RK be the box kernel
RK = @(y)boxker(y, 0.5, 1);

% Calulate the masked_field handle (if xvals_vecs is not an input don't use
% it when computing the field)
if ~exist('xvals_vecs', 'var')
    mfield = @(tval) applyconvfield(tval, nan2zero(mask), RK, NaN, 1);
else
    mfield = @(tval) applyconvfield(tval, nan2zero(mask), RK, NaN, 1, ...
                                                               xvals_vecs);
end

% Divide to normalize (as at edges of the box kernel voxels can be counted
% twice)
if ~asnan 
    mfield_out = inf2zero(mfield(x)./mfield(x));
else
    mfield_out = inf2nan(mfield(x)./mfield(x)); %Returns NaN outside of the mask!
end

end

