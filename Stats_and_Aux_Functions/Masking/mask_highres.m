function [ mask_hr, weights ] = mask_highres( mask, resadd,...
                                                           enlarge, plots )
% mask_highres( mask, resadd, enlarge, plots ) computes a high resolution
% version of a mask. It has an option to enlarge the mask region by 'resadd'.
% If 'resadd' is used every voxel is considered to have 1/(resadd+1)^D, where
% D is the dimension of the mask volume.
% Optionally, 'weights' can be output, which assign the weights This is used in LKC estimation, since in this toolbox voxels are usually
% interpreted as the center values of rectangular domains.
%
%--------------------------------------------------------------------------
% ARGUMENTS
% Mandatory
%   mask    an logical T_1 x ... x T_D array.
%   resadd  the amount of equidistant voxels introduced inbetween the
%           voxels  
% Optional
%   enlarge numeric denoting the amount of voxels added by dilating the
%           high resolution mask. Default ceil(resadd/2), which if resadd
%           is odd means that the boundary voxels are exactly half the
%           distance between the voxels shifted with respect to the
%           original mask voxels.
%   plots logical to show educational plots explaining the code of
%               the function. Default is 0, i.e. no plots.
%--------------------------------------------------------------------------
% OUTPUT
%   mask_hr  an logical hr_T_1 x ... x hr_T_D array representing the mask
%            on a resolution increased grid
%   weights  an hr_T_1 x ... x hr_T_D array giving the number of neighbours
%            of each voxel within the mask
%--------------------------------------------------------------------------
% DEVELOPER TODOs:
% -------------------------------------------------------------------------
% EXAMPLES
% showplots of the mask
% show_plot = 1;
% 
% %%% 1D
% % resolution added
% resadd  = 1;
% enlarge = 0;
% % create a mask and show it
% Sig  = gensig([1,2], 3, [10,20], [100,150], {[40,30], [70,120]});
% mask = logical( Sig > 0.02 );
% mask = mask(50,:)';
% plot( mask )
% clear Sig
% 
% mask_hr = mask_highres( mask, resadd, enlarge, show_plot );
% 
% %%% 2D
% % resolution added
% resadd  = 3;
% % create a mask and show it
% Sig  = gensig([1,2], 3, [10,20], [100,150], {[40,30], [70,120]});
% mask = logical( Sig > 0.02 & Sig < 1.1 );
% imagesc( mask )
% clear Sig
% 
% % enlarged domain
% mask_hr = mask_highres( mask, resadd, 1, show_plot );
% % non enlarged domain
% mask_hr = mask_highres( mask, resadd, 0, show_plot );
% 
% % resolution added
% resadd  = 3;
% enlarge = 1;
% % create a mask and show it
% mask = logical( ones(50,50) );
% mask(:,50) = 0;
% imagesc( mask )
% clear Sig
% 
% % enlarged domain
% mask_hr = mask_highres( mask, resadd, 1, show_plot );
% % non enlarged domain
% mask_hr = mask_highres( mask, resadd, 0, show_plot );
% 
% %%% 3D
% % resolution added
% resadd  = 3;
% % create a mask and show it
% siz = 13;
% dx  = 0.25;
% [x,y,z] = meshgrid( -siz:dx:siz, -siz:dx:siz, -siz:dx:siz );
% xvals = [x(:), y(:), z(:)]';
% h     = reshape( GkerMV( xvals, 5 ), size(x) );
% mask  = logical( h > 0.002 );
% imagesc( mask(:,:,53) )
% clear h
% 
% % enlarged domain
% mask_hr = mask_highres( mask, resadd, 1, 0 );
% % non enlarged domain
% mask_hr = mask_highres( mask, resadd, 0, 0 );
%--------------------------------------------------------------------------
% AUTHORS: Fabian Telschow, Samuel Davenport
%--------------------------------------------------------------------------


%%  Check mandatory input and get important constants
%--------------------------------------------------------------------------

% Check whether the mask is logical
if ~islogical( mask )
    error( "The mask must be a logical array!" );
end

% Get the size of the mask
s_mask = size( mask );

% Get the dimension
D = length( s_mask );
horz2vert = 0;
if D == 2 && s_mask(2) == 1
    D = 1;
elseif D == 2 && s_mask(1) == 1
    D = 1; %Fix to allow row vector masks
    mask = mask';
    s_mask = fliplr(s_mask);
    horz2vert = 1;
end

% Check whether resadd is numeric
if ~isnumeric( resadd )
    error( "resadd must be a positive natural number!" );
else
    % Ensure that resadd is a positive integer
    resadd = ceil( abs( resadd ) );
end


%% Add/check optional input
%--------------------------------------------------------------------------
if ~exist( 'enlarge', 'var' )
   % Default option of 'enlarge'
%    enlarge = 0;
    enlarge = ceil(resadd/2);
end

if ~isnumeric( enlarge )
    error( "enlarge must be a postive integer!" )
else
    if enlarge ~= ceil( enlarge ) || enlarge < 0
       error( "enlarge must be a postive integer!" )
    end
end

if ~exist( 'plots', 'var' )
   % Default option of 'enlarge'
   plots = 0;
end


%% Main function
%--------------------------------------------------------------------------

%%%%%% return the input mask if resadd = 0
if resadd == 0
    mask_hr = mask;
    weights = mask_hr;
    return
end

%%%%%% resadd > 0 cases
% size of the output array
s_hr = ( s_mask - 1 ) * resadd + s_mask;
if enlarge ~= 0
    if D == 1
        s_hr = s_hr + [ 2 * enlarge, 0 ];
    else
        s_hr = s_hr + 2 * enlarge;
    end
end

% return logical array of size s_hr, if mask is always 1
if all( mask(:) )
    mask_hr = true( s_hr );
    weights = mask_hr;
    return
end

%%% if the mask is non-trivial use a dilation trick
% create index to fill the original mask at the correct voxels of the high
% resolution mask
index = cell( [ 1 D ] );
for d = 1:D
    index{d} = ( enlarge + 1 ):( resadd + 1 ):( s_hr(d) - enlarge );
end

% fill the resolution increased mask with the values from the original mask
% at the correct locations
mask_hr = false( s_hr );
mask_hr( index{:} ) = mask;

if plots
    old_mask_hr = mask_hr;
end

% fill the zero values of the resolution increased mask, which belong to
% the mask. Note that this enlarges the mask by resadd
mask_hr = logical( imdilate( mask_hr, ones( ones([ 1 D ]) ...
                                              * (2*ceil(resadd/2)+1) ) ) );

if enlarge ~= ceil(resadd/2)
    % number of voxels which the inverse mask or the normal mask needs to
    % be shifted in order to obtain the correct mask. If positiv mask is
    % dilated by that amount. If negative ~mask is dilated and then the
    % negative is taken, since we need to erode voxels.
    denlarge = enlarge - ceil(resadd/2);
    
    if denlarge < 0
        mask_hr = ~logical( imdilate( ~mask_hr, ones( ones([ 1 D ]) ...
                                                * (2*(-denlarge)+1) ) ) );
    else
        mask_hr = logical( imdilate( mask_hr, ones( ones([ 1 D ]) ...
                                              * (2*denlarge+1) ) ) );
    end
end

% show plots explaining the output
if plots
    if D == 1
        figure,clf,
        plot( old_mask_hr ),
        title( 'fill mask into high res grid' )
        figure,clf,
        plot( mask_hr )
        title( 'output high res mask' )
        figure,clf,
        plot( double( mask_hr ) + double( old_mask_hr ) )
        title( 'Original mask on high res + Output high res mask' )
    elseif D == 2
        figure,clf,
        imagesc( old_mask_hr ),
        colorbar,
        title( 'fill mask into high res' )
        figure,clf,
        imagesc( mask_hr ),
        colorbar,
        title( 'output high res mask' )
        figure,clf,
        imagesc( double( mask_hr ) + double( old_mask_hr ) ),
        colorbar,
        title( 'Original mask on high res + Output high res mask' )
    elseif D == 3
        
    end
end

if mod(resadd, 2) == 0 
    weights = NaN;
else
    weights = getweights(mask_hr);
end

% In 1D transpose to ensure you return row vectors if you entered a
% mask that was a row_vector.
if horz2vert 
    mask_hr = mask_hr';
    weights = weights';
end

% Old weight calculations
old_weights = convn( mask_hr, ones( [ones( [ 1 D ] )*3 1] ), 'same' );
old_weights( ~mask_hr ) = 0;
switch D
    case 1
        old_weights( old_weights == 3 ) = 1;
        old_weights( old_weights == 2 ) = 1 / 2;
    case 2
        old_weights( old_weights == 4 ) = 1 / 4;
        old_weights( old_weights == 5 ) = 1 / 4;
        old_weights( old_weights == 6 ) = 1 / 2;
        old_weights( old_weights == 7 ) = 1 / 2;
        old_weights( old_weights == 8 ) = 3 / 4;
        old_weights( old_weights == 9 ) = 1;
    case 3
        % note that this is only approximate. Getting the correct weights
        % requires more thought, As an example weights=26 can lead to a
        % weight of 1/2 or 3/4 depending on how the voxels are spread.
        % Maybe we fix that later.
        tmp = old_weights;
        old_weights( mask_hr )   = 1/2;
        old_weights( tmp == 27 ) = 1;
        old_weights( tmp == 8 )  = 1/8;
end
        
return

% Deprecated
