function weights = getweights( mask_hr )
% GETWEIGHTS( mask_hr )
%--------------------------------------------------------------------------
% ARGUMENTS
% Mandatory
% 	mask_hr     the high resolution mask
%--------------------------------------------------------------------------
% OUTPUT
% 
%--------------------------------------------------------------------------
% EXAMPLES
% mask_hr = ones(3); mask_hr(3,3) = 0;
% getweights( mask_hr )
% %% 2D Weights
% % resolution added
% resAdd  = 1;
% % create a mask and show it
% Sig  = gensig([1,2], 3, [10,20], [100,150], {[40,30], [70,120]});
% mask = logical( Sig > 0.02 & Sig < 1.1 );
% 
% % enlarged domain
% [mask_hr, weights, old_weights] = mask_highres( mask, resAdd, 1 );
% subplot(2,1,1); imagesc(weights); title('New Weights')
% subplot(2,1,2); imagesc(old_weights); title('Old Weights')
% 
% %% 3D weights (the examples we considered today :))
% example_mask = ones(3,3,3);
% example_mask(1,1,1) = 0;
% 
% weights = getweights(example_mask)
% weights(2,2,2) % I.e. 7/8 like I said haha
% 
% % Your example (I think this was your example)
% example_mask = ones(3,3,3);
% example_mask(1,1,2) = 0;
% 
% weights = getweights(example_mask)
% weights(2,2,2) 
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport
%--------------------------------------------------------------------------

%%  Check mandatory input and get important constants
%--------------------------------------------------------------------------
Dim_hr = size(mask_hr); D = length(Dim_hr);

%%  Main Function Loop
%--------------------------------------------------------------------------

% Divide voxels in the high res mask in two in each dimension 
mask_with_divided_voxels = mask_highres_divide( mask_hr, 2 );

% Erode the new mask by one voxel
dilatedanddividedmask = dilate_mask( mask_with_divided_voxels, -1 );

% Sum up the numer of small voxels within each larger voxel
ones_array = ones( ones( 1, D ) * 2 );
sum_within_each_voxel_large = convn( dilatedanddividedmask, ones_array );

% The above has too much information due to the convolution we only want
% the corner sum. Then we need to divide by the total number of small
% voxels within each large voxel which is 2^D.
index = cell( [ 1 D ] );
for d = 1:D
    index{d} = 2:2:(2*Dim_hr(d));
end
weights = sum_within_each_voxel_large( index{:} ) / 2^D;

end
