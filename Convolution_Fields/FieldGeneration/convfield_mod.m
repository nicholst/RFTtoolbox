function [ smooth_data, xvals_vecs ] = convfield( lat_data, Kernel, spacing, D, derivtype, usespm, truncation, adjust_kernel)
% CONVFIELD( lat_data, FWHM, spacing, D, derivtype ) generates a
% convolution field (at a given spacing) derived from lattice data smoothed 
% with an isotropic Gaussian kernel with specified FWHM.
%--------------------------------------------------------------------------
% ARGUMENTS
% lat_data      a Dim by nsubj array of data
% FWHM          the FWHM of the kernel with which to do smoothing
% spacing       the interval at which to compute the convolution field.
%               I.e. if size(lat_data) = [10,20] and spacing = 0.1 the field 
%               will be evaluated at the points 1:0.1:10. Default is 0.1.
% D             the dimension of the data, if this is left blank it is
%               assumed that nsubj = 1 and that the convolution field has 
%               the same numberof dimesions as lat_data
% derivtype     0/1/2, 0 returns the convolution field, 1 it's derivative
%               and 2 it's second derivative (at all points). Default is 0
%               i.e to return the field! Note if D > 1 then  derivtype = 2
%               has not been implemented yet.
% usespm        0/1. Whether to use spm_smooth or the inbuilt matlab
%               function convn. This is only relevant in 3D.
% adjust_kernel    a D by 1 vector that allows you to compute the
%               convolution field at an offset. This is useful for computing 
%               derivatives numerically. Default is not to use this feature.
%--------------------------------------------------------------------------
% OUTPUT
% smooth_data   an array of dimension D + 1, where the length of the dth
%               dimension for d = 1,...,D is length(1:spacing:Dim(d)) and the
%               length of the last dimension is nsubj
%--------------------------------------------------------------------------
% EXAMPLES
% %%% 1D
% %% Smoothing with increased resolution
% nvox = 100; xvals = 1:nvox;
% xvals_fine = 1:0.01:nvox;
% FWHM = 3;
% lat_data = normrnd(0,1,1,nvox);
% smooth_data = convfield( lat_data, FWHM, 0.01, 1);
% plot(xvals_fine,smooth_data)
% 
% %% Smoothing with the same resolution
% lat_data = normrnd(0,1,1,nvox);
% cfield = spm_conv(lat_data, FWHM);
% plot(xvals,cfield)
% hold on
% smooth_data = convfield( lat_data', FWHM, 1, 1 );
% plot(xvals, smooth_data)
% 
% %% Multiple subjects
% nsubj = 3; nvox = 100;
% lat_data = normrnd(0,1,nvox,nsubj);
% cfield = spm_conv(lat_data(:,1), FWHM);
% plot(1:nvox,cfield)
% hold on
% smooth_data = convfield( lat_data, FWHM, 1, 1 );
% plot(1:nvox,smooth_data(:,1))
% 
% %% 1D derivatives
% nvox = 100; h = 0.01; xvals = 1:nvox; xvals_fine = 1:0.01:nvox;
% lat_data = normrnd(0,1,nvox,1);
% smoothedfield = convfield( lat_data, FWHM, h, 1);
% deriv1 = convfield( lat_data, FWHM, h, 1, 1 );
% deriv2 = diff(smoothedfield)/h;
% plot(xvals_fine, deriv1 + 0.5)
% hold on 
% plot(xvals_fine(1:end-1), deriv2)
% 
% % 1D derivative (multiple subjects)
% nvox = 100; FWHM = 3; xvals = 1:nvox; lat_data = normrnd(0,1,1,nvox);
% aderiv = @(x) applyconvfield( x, lat_data, @(y) GkerMVderiv(y, FWHM) )
% deriv = convfield( lat_data, FWHM, h, 1, 1 );
% deriv(1), aderiv(1)
% 
% %% 2D
% Dim = [50,50];
% lat_data = normrnd(0,1,Dim)
% cfield = spm_conv(lat_data, FWHM);
% surf(cfield)
% smooth_data = convfield( lat_data, FWHM, 1, 2); %Same as spm_conv
% surf(smooth_data)
% fine_data = convfield( lat_data, FWHM, 0.25, 2); %Convolution eval
% surf(fine_data)
% 
% % Matching to applyconvfield
% cfield = @(x) applyconvfield(x, lat_data, FWHM);
% smooth_data(20,20)
% cfield([20,20]')
% smooth_data(1,10)
% cfield([1,10]')
% 
% % 2D derivatives
% Dim = [50,50];
% lat_data = normrnd(0,1,Dim);
% derivfield = convfield( lat_data, FWHM, 1, 2, 1)
% surf(reshape(derivfield(1,:), Dim))
% spacing = 0.01; resAdd = floor(1/spacing-1);
% smoothfield100 = convfield( lat_data, FWHM, spacing, 2, 0);
% derivfield100 = convfield( lat_data, FWHM, spacing, 2, 1);
% point = [500,500]
% ((smoothfield100(point(1), point(2) + 1) - smoothfield100(point(1),point(2)))/(1/(resAdd +1)))
% ((smoothfield100(point(1)+1, point(2)) - smoothfield100(point(1),point(2)))/(1/(resAdd +1)))
% derivfield100(:,point(1), point(2))
% % note that it's still not perfect because it's still a discrete
% % approximation, but that's why we want to use derivfield in the first
% % place!!
% 
% % 2D derivatives (multiple subjects)
% Dim = [5,5]; nsubj = 20;
% lat_data = normrnd(0,1,[Dim, nsubj]);
% derivfield = convfield( lat_data, FWHM, 1, 2, 1)
% 
% %% 3D
% %Compare to SPM
% Dim = [10,10,10];
% FWHM = 3;
% lat_data = normrnd(0,1,Dim);
% subplot(1,2,1)
% spm_smooth_field = zeros(Dim); 
% spm_smooth(lat_data, spm_smooth_field, FWHM)
% surf(spm_smooth_field(:,:,5));
% title('Lattice Eval')
% subplot(1,2,2)
% cfield = convfield( lat_data, FWHM, 1, 3); %Convolution eval
% surf(cfield(:,:,5))
% title('Convolution Field Eval (no smoothing)')
% 
% % Fine evaluation
% Dim = [10,10,10];
% spacing = 0.1; D = length(Dim); FWHM = 3; 
% slice = Dim(end)/2; fine_slice = Dim(end)/2/spacing;
% lat_data = normrnd(0,1,Dim);
% subplot(1,3,1)
% spm_smooth_field = zeros(Dim); 
% spm_smooth(lat_data, spm_smooth_field, FWHM)
% surf(spm_smooth_field(:,:,slice));
% title('Lattice Eval')
% subplot(1,3,2)
% cfield = convfield( lat_data, FWHM, spacing, D, 0, 0); %Convolution eval
% surf(cfield(:,:,fine_slice))
% title('Convolution Field Eval (Convn)')
% subplot(1,3,3)
% cfield_withspm = convfield( lat_data, FWHM, spacing, D, 0, 1); %Convolution eval (using spm_smooth)
% surf(cfield_withspm(:,:,fine_slice))
% title('Convolution Field Eval (SPM\_smooth)')
% 
% 
% % Compare to applyconvfield
% lat_data = normrnd(0,1,Dim);
% acfield = @(x) applyconvfield(x, lat_data, FWHM);
% Dim = [10,10,10];
% spacing = 1; D = length(Dim); FWHM = 3; 
% cfield = convfield( lat_data, FWHM, 1, D, 0, 0); 
% cfield_withspm = convfield( lat_data, FWHM, 1, D, 0, 1);
% acfield([5,5,5]')
% cfield(5,5,5)
% cfield_withspm(5,5,5) %Even within the image the spm_smooth version is
% % off ( as SPM does something weird in the z-direction)
% acfield([1,1,10]')
% cfield(1,1,10)
% cfield_withspm(1,1,10) %SPM_smooth version is quite off on the boundary!
% 
% % Note that the differneces in spm_smooth appear to go away as the FWHM or the
% % spacing increases, so the spm_smooth version does well to evaluate ifne
% % convolution fields and does so very efficiently. So the difference could 
% % be caused by a truncation issue in spm_smooth?
% 
% % % 3D derivatives (1 subject)
% Dim = [5,5,5]; D = length(Dim); FWHM = 3;
% lat_data = normrnd(0,1,Dim);
% derivfield = convfield( lat_data, FWHM, 1, D, 1)
% aderiv = @(x) applyconvfield( x, lat_data, @(y) GkerMVderiv(y, FWHM)  )
% dfeval = derivfield(:,3,3,3)
% aceval = aderiv([3,3,3]')
% spacing = 0.05;
% spaced_point = spacep( [3,3,3]', spacing);
% cfield_fine = convfield( lat_data, FWHM, spacing, D);
% pointeval = cfield_fine(spaced_point(1),spaced_point(2),spaced_point(3));
% plusxeval = cfield_fine(spaced_point(1)+1,spaced_point(2),spaced_point(3));
% plusyeval = cfield_fine(spaced_point(1),spaced_point(2)+1,spaced_point(3));
% pluszeval = cfield_fine(spaced_point(1),spaced_point(2),spaced_point(3)+1);
% derivx = (plusxeval - pointeval)/spacing
% derivy = (plusyeval - pointeval)/spacing
% derivz = (pluszeval - pointeval)/spacing
% 
% % 3D derivatives (Multiple subjects)
% Dim = [5,5,5]; D = length(Dim); FWHM = 3; nsubj = 2;
% lat_data = normrnd(0,1,[Dim,nsubj]);
% derivfields = convfield( lat_data, FWHM, 1, D, 1)
% aderiv = @(x) applyconvfield( x, lat_data(:,:,:,2), @(y) GkerMVderiv(y, FWHM)  )
% dfeval = derivfields(:,3,3,3,2)
% aceval = aderiv([3,3,3]')
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport, Fabian Telschow                                              
%--------------------------------------------------------------------------
if nargin < 3
    spacing = 0.1;
end
if nargin < 5
    derivtype = 0;
end
if nargin < 6
    usespm = 1;
end

if nargin < 8
    use_adjust = 0;
else
    if any(adjust_kernel)
        use_adjust = 1;
    end
    if size(adjust_kernel,1) == 1
        adjust_kernel = adjust_kernel';
    end
    if length(adjust_kernel) ~= D
        error('The kernel adjustment must be of the right dimension')
    end
end

slatdata = size(lat_data);
D_latdata = length(slatdata);

if nargin < 4
    D = D_latdata;
end

% Default Kernel
if isnumeric(Kernel)
    FWHM = Kernel;
    if nargin < 7
        truncation = -1;
    end
    if truncation == -1
        sigma = FWHM2sigma(FWHM);
        truncation = ceil(4*sigma);
    end
    
    if derivtype == 0
        Kernel = @(x) GkerMV(x,FWHM);
    elseif derivtype == 1
        Kernel = @(x) GkerMVderiv(x,FWHM);
    elseif derivtype == 2
        Kernel = @(x) GkerMVderiv2(x,FWHM);
    else
        error('This setting has not been coded yet')
    end
else
    % Need a default for truncation for no gaussian kernels!
    if derivtype == 1
        Kernel = @(x) getderivs( Kernel(x), D );
    elseif derivtype > 1
        error('derivtype > 1 for non-isotropic or non-Gaussian kernels has not been implemented yet')
    end
end


if D > 1
    if D_latdata == D
        nsubj = 1;
        Dim = slatdata;
    else
        nsubj = slatdata(end);
        Dim = slatdata( 1 : end-1 );
    end
else
    vert2horz = 0;
    if D_latdata == 2 && slatdata(1) == 1
        nsubj = 1;
        Dim = slatdata(slatdata > 1);
        vert2horz = 1; % I.e. if a horizontal field is entered it returns one as well
    elseif D_latdata == 2 && slatdata(2) == 1
        nsubj = 1;
        Dim = slatdata(slatdata > 1);
    else %I.e. if D_lat_data == 2 and slatdata(1) and slatdata(2) are both > 1
        % or if D_lat_data > 2 and there are some 1 dimensional dimensions
        % hanging around for some reason.
        slatdata_squeezed = size(squeeze(lat_data));
        Dim = slatdata_squeezed(1);
        nsubj = slatdata_squeezed(2);
    end
end

if D == 3 && (spacing < 0.05)
    error('In 3D you shouldn''t use such high spacing for memory reasons')
end

resAdd = floor(1/spacing-1); %Ensures that the spacing fits between the voxels by rounding if necessary
dx = 1/(resAdd+1); %Gives the difference between voxels (basically dx = spacing if spacing evenly divides the voxel)

xvals_vecs  = cell(1,D);
if use_adjust
    for d = 1:D
        xvals_vecs{d} = (1:dx:Dim(d)) + adjust_kernel(d);
    end
else
    for d = 1:D
        xvals_vecs{d} = 1:dx:Dim(d);
    end
end

% Dimensions for field with increased resolution
Dimhr = ( Dim - 1 ) * resAdd + Dim; %Dimhr = Dim with high resolution

gridside  = -truncation:dx:truncation;

% convolution kernel and derivatives to be used with convn
if D == 1
    % increase the resolution of the raw data by introducing zeros
    expanded_lat_data = zeros( [ Dimhr, nsubj] );
    expanded_lat_data( 1:(resAdd + 1):end, : ) = lat_data;
     
    if use_adjust
%         gridside = gridside + adjust_kernel; 
        gridside = fliplr(gridside - adjust_kernel);
        %Note need to flip here as convn flips h around before dragging it across the data!
    end
    
    h = Kernel(gridside);
    smooth_data = convn( expanded_lat_data', h, 'same' )';
    
    if vert2horz && nsubj == 1
        smooth_data = smooth_data';
    end
elseif D == 2
    expanded_lat_data = zeros( [ Dimhr, nsubj ] );
    expanded_lat_data( 1:( resAdd + 1 ):end, 1:( resAdd + 1 ):end, : ) = lat_data;
    
    % grid for convolution kernel
    [x,y] = meshgrid( gridside, gridside );
    xvals = [x(:), y(:)]';
    
    if use_adjust
        xvals = xvals + adjust_kernel;
    end
    % convolution kernels to be used with convn
    if derivtype == 0
        h = reshape( Kernel(xvals), size(x) )';
%         h = fliplr(h); h = flipud(h);
        smooth_data  = convn( expanded_lat_data, h, 'same' );
    elseif derivtype == 1
        smooth_data = zeros( [D, size(expanded_lat_data)]);
        dh  = Kernel(xvals);
        dxh = reshape( dh(1,:), size(x) );
        dyh = reshape( dh(2,:), size(x) );
        
%         smooth_data(1,:,:,:)  = convn( expanded_lat_data, dxh, 'same' );
%         smooth_data(2,:,:,:) = convn( expanded_lat_data, dyh, 'same' );
        smooth_data(1,:,:,:)  = convn( expanded_lat_data, dyh, 'same' );
        smooth_data(2,:,:,:) = convn( expanded_lat_data, dxh, 'same' );
    else
        error('Higher derivatives are not supported')  
    end
elseif D == 3
    expanded_lat_data = zeros( [ Dimhr, nsubj ] );
    expanded_lat_data( 1:( resAdd + 1 ):end, 1:( resAdd + 1 ):end, 1:( resAdd + 1 ):end, : ) = lat_data;
    
    % grid for convolution kernel
    [x,y,z] = meshgrid( gridside, gridside, gridside );
    xvals = [x(:), y(:), z(:)]';
    
    if use_adjust
        xvals = xvals + adjust_kernel;
    end
    % convolution kernels to be used with convn
    if derivtype == 0
        if usespm == 1
            smooth_data = zeros(size(expanded_lat_data));
            for L = 1:nsubj
                smooth_subj_data = zeros(Dimhr);
                spm_smooth(expanded_lat_data(:,:,:,L), smooth_subj_data, FWHM/spacing)
                smooth_data(:,:,:,L) = smooth_subj_data;
            end
            smooth_data = smooth_data/spacing^3;
        else
            h   = reshape( Kernel(xvals), size(x) );
            smooth_data  = convn( expanded_lat_data, h, 'same' );
        end
    elseif derivtype == 1 % Need to modify the spm_ccode in order to get this to work faster!
        smooth_data = zeros( [D, size(expanded_lat_data)]);
        dh  = Kernel(xvals);
        dxh = reshape( dh(1,:), size(x) );
        dyh = reshape( dh(2,:), size(x) );
        dzh = reshape( dh(3,:), size(x) );

%         smooth_data(1,:,:,:,:) = convn( expanded_lat_data, dxh, 'same' );
%         smooth_data(2,:,:,:,:) = convn( expanded_lat_data, dyh, 'same' );

%       Needs to be this way round because of the way that meshgrid works!
        smooth_data(1,:,:,:,:) = convn( expanded_lat_data, dyh, 'same' );
        smooth_data(2,:,:,:,:) = convn( expanded_lat_data, dxh, 'same' );
        smooth_data(3,:,:,:,:) = convn( expanded_lat_data, dzh, 'same' );
    else
        error('Higher derivatives are not supported')
    end
else
    error('D != 1,2,3 has not been implemented yet!')
end

end
