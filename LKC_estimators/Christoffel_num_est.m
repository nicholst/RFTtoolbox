function [ Gamma_est, xvals ] = Christoffel_num_est( lat_data, Kernel, resadd,...
                                                  enlarge, h )
% Christoffel_num_est( lat_data, Kernel, resadd, enlarge, h ) calculates an
% estimate of the Christoffel symbols from the induced Riemannian metric
% of a convolution field..
% This function uses the fact that convolution fields can be calculated
% everywhere and therefore numerical approximations can be very accurate.
%
%--------------------------------------------------------------------------
% ARGUMENTS
% Mandatory
%  lat_data  data array T_1 x ... x T_D x N. Last index enumerates the
%            samples. Note that N > 1 is required!
%  Kernel    either an object of class SepKernel or a numeric.
%            If class SepKernel all fields for first and second derivatives
%            must be specified.
%
%            If Kernel is numeric, the convolution field is generated by 
%            smoothing with an isotropic Gaussian kernel with FWHM = Kernel.
%            Truncation and adjust_kernel are set to be default values.
% Optional
%  resadd    the amount of voxels added equidistantly inbetween the
%            existing voxels. Default is 1.
%  enlarge   a numeric which must be a positive integer or zero. The
%            convolution field is computed on a domain enlarged in each
%            direction by 'enlarge' voxels. Note if resadd ~=0 the added
%            voxels are in high resolution. Default 0. 
% h          a numeric used to calculate the derivatives i.e. via
%            X(v+h)-X(v))/h. Default is 0.00001. Avoid taking h to be
%            too small for numerical precision reasons
%--------------------------------------------------------------------------
% OUTPUT
%   Gamma_est   an array of size hrT_1 x ... x hrT_D x D x D x D. Containing
%               the Christoffel symbols at each voxel from the chosen
%               increased resolution defined by resadd.
% -------------------------------------------------------------------------
% DEVELOPER TODOs:
%--------------------------------------------------------------------------
% EXAMPLES
%--------------------------------------------------------------------------
% AUTHOR: Fabian Telschow
%--------------------------------------------------------------------------


%% Check mandatory input and get important constants
%--------------------------------------------------------------------------

% Size of the domain
s_lat_data = size( lat_data );

% Dimension of the domain
D = length( s_lat_data( 1:end-1 ) );

if D < 3
    error("Don't waste your time. You do not need them.")
end
if D > 3
    error("Not implemented for D>3.")
end

% Get variable domain counter
index  = repmat( {':'}, 1, D );

% Check that method is implemented for dimension D
if D ~= 3
    error( 'D must be 3. Other dimensions are not implemented yet.')
end

%% Add/check optional values
%--------------------------------------------------------------------------

if ~exist( 'resadd', 'var' )
   % Default number of resolution increasing voxels between observed voxels
   resadd = 1;
end

if ~exist( 'enlarge', 'var' )
   % Default number of resolution increasing voxels between observed voxels
   enlarge =  ceil( resadd / 2 );
end

if ~exist( 'h', 'var' )
   % Default number of resolution increasing voxels between observed voxels
   h =  0.00001;
end

%% Main function
%--------------------------------------------------------------------------

% Get the convolution fields and their derivatives
if isa( Kernel, 'SepKernel' ) || isnumeric( Kernel )
    [ Y, xvals ] = convfield( lat_data, Kernel, resadd, D, 0,...
                                         enlarge );
    % Get the estimates of the covariances
    stdY   = std( Y,  0, D+1 );
    % Standardize the field
    Y = ( Y - mean( Y, D+1 ) ) ./ stdY;
    
    if isnumeric( Kernel )
        Kernel = SepKernel( D, Kernel );
    end

else
    error( "The 'Kernel' must be either a numeric or a kernel structure!" )
end

% Get size of the resolution increased domain
sY = size( Y );

% Allocate output the entries of the Riemannian metric
Gamma_est = zeros( [ sY( 1:end-1 ) D D D ] );

%%%%%% BEGIN compute the Riemannian metric
for dd = 1:D
    % Obtain the variance 1 field at an offset of h*e_dd everywhere
    % where e_d is the standard basis vector in the dth direction
    shift_Kernel = Kernel;
    shift_Kernel.adjust = h * sbasis( dd, D )';

    % Calculate values of shifted normalized field in e_dd direction
    shift_ddplusY = convfield( lat_data, shift_Kernel, resadd, D, 0, enlarge );
    shift_std = sqrt( var( shift_ddplusY, 0, D+1 ) );
    shift_ddplusY = ( shift_ddplusY - mean( shift_ddplusY, D+1 ) ) ./ shift_std;
    
    for d = 1:D
        for k = 1:D
            % Calculate values of shifted normalized field in ++ directions
            shift_Kernel.adjust = h * ( sbasis( k, D )' + sbasis( d, D )' );
            shift_plplY = convfield( lat_data, shift_Kernel, resadd, D, 0, enlarge );
            shift_std = sqrt( var( shift_plplY, 0, D+1 ) );
            shift_plplY = ( shift_plplY - mean( shift_plplY, D+1 ) ) ./ shift_std;

            % Calculate values of shifted normalized field in -- directions
            shift_Kernel.adjust = -h * ( sbasis( k, D )' + sbasis( d, D )' );
            shift_mnmnY = convfield( lat_data, shift_Kernel, resadd, D, 0, enlarge );
            shift_std = sqrt( var( shift_mnmnY, 0, D+1 ) );
            shift_mnmnY = ( shift_mnmnY - mean( shift_mnmnY, D+1 ) ) ./ shift_std;

            % Calculate values of shifted normalized field in +- directions
            shift_Kernel.adjust = h * ( sbasis( k, D )' - sbasis( d, D )' );
            shift_plmnY = convfield( lat_data, shift_Kernel, resadd, D, 0, enlarge );
            shift_std = sqrt( var( shift_plmnY, 0, D+1 ) );
            shift_plmnY = ( shift_plmnY - mean( shift_plmnY, D+1 ) ) ./ shift_std;
            
            % Calculate values of shifted normalized field in -+ directions
            shift_Kernel.adjust = -h * ( sbasis( k, D )' - sbasis( d, D )' );
            shift_mnplY = convfield( lat_data, shift_Kernel, resadd, D, 0, enlarge );
            shift_std = sqrt( var( shift_mnplY, 0, D+1 ) );
            shift_mnplY = ( shift_mnplY - mean( shift_mnplY, D+1 ) ) ./ shift_std;
            
            % Compute partial derivative of Y with respect to t_dd
            partial_ddY = ( shift_ddplusY - Y ) / h;
            
            % Compute second derivative of 
            partial_kdY = ( shift_plplY - shift_mnplY - shift_plmnY + shift_mnmnY ) / 4 / h;
            Gamma_est( index{:}, k, d, dd ) = vectcov( partial_kdY, partial_ddY, D+1, 1 );
            
        end
    end
end
clear fieldsplush fieldseval fieldsplush_std
%%%%%% END compute the Riemannian metric

return