function [ pad_data, locs ] = pad_vals( data, padn, val )
% PAD_VALUES(  data, padn, val ) pads is a function which allows to pad
% specified values to the boundary of an data array.
%
%--------------------------------------------------------------------------
% ARGUMENTS
% Mandatory
%   data   a Dim x nsubj array of data
%
% Optional
%   padn   either a numeric, a 1 x D vector or a 2 x D array containing
%          the value for how many voxels are padded to the sides in each
%          dimension.
%          If it is a numeric there are 'padn' voxels padded to each side
%          of the data array.
%          If it is a vector there are padn(d) voxels padded to the sides
%          of the dth dimension.
%          If it is a 2 x D array there are padn(1,d) voxels padded to the
%          left and padn(2,d) to the right of the dth dimension.
%          Default is 1.
%   val    The value, which is padded to the array. Default 0.
%
%--------------------------------------------------------------------------
% OUTPUT
%   pad_data  is Dim + padn array where voxels according to 'padn' are
%             padded to the sides.
%   locs      is a cell array containing the locations of the original data
%             within the pad_data array
%--------------------------------------------------------------------------
% DEVELOPER TODOs:
% - write examples
%--------------------------------------------------------------------------
% EXAMPLES
% 
%--------------------------------------------------------------------------
% AUTHOR: Fabian Telschow  
%--------------------------------------------------------------------------


%% Check mandatory input and get important constants
%--------------------------------------------------------------------------

% Get size of the input data
sdata = size( data );

% get dimension of the input data
D = length( sdata );
if D == 2 && ( sdata(1) == 1 || sdata(2) == 1 )
    D = 1;
end

%% Add/check optional values
%--------------------------------------------------------------------------

% Default value of padn
if ~exist( 'padn', 'var' )
   % Default option of opt1
   padn = 1;
end

% Default value of padn
if ~exist( 'val', 'var' )
   % Default option of opt1
   val= 0;
end

% transform padn into a 2 x D array
if isnumeric( padn )
    if numel( padn ) == 1
        padn = padn * ones( [ 2 D ] );
    elseif all( size( padn ) == [ 1 D ] )
        padn = [ padn; padn ];
    elseif all( size( padn ) == [ D 1 ] )
        padn = [ padn', padn' ]';
    elseif ~all( size( padn ) == [ 2 D ] )
        error( strcat( "The dimensions of padn are wrong. ",...
                       "Please, refer to the description" ) )
    end
else
    error( strcat( "padn needs to be a numeric array",...
                   "Please, refer to the description" ) )
end

%% Main function  
%--------------------------------------------------------------------------

% Make a larger image so that masked voxels at the boundary of the image
% will be judged to be on the boundary
if D == 1
    if  sdata(1) == 1
        pad_data = val * ones( sdata + [ 0 sum( padn )] );
    else
        pad_data = val * ones( sdata + [ sum( padn ) 0] );
    end
else
    pad_data = val * ones( sdata + sum( padn ) );    
end

% Get the locations to place the inner (original) data
locs = cell( 1, D );
for d = 1:D
   locs{d} = padn(1,d) + ( 1:sdata(d) );
end

% Set the inner locations to be the data
pad_data( locs{:} ) = data;

return