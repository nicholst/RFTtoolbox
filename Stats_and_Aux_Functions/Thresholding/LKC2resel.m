function resel_vec = LKC2resel( LKCs )
% LKC2RESEL( LKCs ) takes in a vector of LKCs and returns the 
% corresponding vector of resels for use in SPM.
%--------------------------------------------------------------------------
% ARGUMENTS
% Mandatory
%  LKCs   a structure containing
%      LKCs.Lhat = L1,..., L_D
%      LKCs.L0 = L0 (the zeroth LKC)
%--------------------------------------------------------------------------
% OUTPUT
%  resel_vec     the vector of resels
%--------------------------------------------------------------------------
% DEVELOPER NOTES: Once we get rid of the SPM dependence this function will
% be deprecated
%--------------------------------------------------------------------------
% EXAMPLES
% FWHM = 3; Dim = [5,5];
% resels = spm_resels(FWHM,Dim, 'B')
% LKCs = resel2LKC(resels)
% resel_vec = LKC2resel(LKCs)
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport
%--------------------------------------------------------------------------

%%  Check mandatory input and get important constants
%--------------------------------------------------------------------------
% Get rid of zero (high LKCs)
LKCs.hatL = LKCs.hatL(LKCs.hatL > 0);

% Ensure that the vector of LKCs is a row vector
if size(LKCs.hatL,1) > 1
    LKCs.hatL = LKCs.hatL';
end

% Compute the number of dimensions
D = length(LKCs.hatL);

%%  Main function
%--------------------------------------------------------------------------
% Calculate scaling factors to convert between resels and LKCs see e.g.
% Worsley 1992 (3D brain paper).
scaling_vec = repmat(sqrt(4*log(2)), 1, D).^(1:D);

% Initialise the resel vector
resel_vec = zeros(1,4);

% Set the non-zero LKCs
resel_vec(2:(D+1)) = LKCs.hatL./scaling_vec;
resel_vec(1) = LKCs.L0;
end

