function [peaklocs, peakvals] = findconvpeaks(lat_data, Kernel, ...
        peak_est_locs, field_type, mask, boundary, truncation, xvals_vecs )
% FINDCONVPEAKS( lat_data, Kprime, xvals_vecs, peak_est_locs, Kprime2, truncation, mask )
% calculates the locations of peaks in a convolution field.
%--------------------------------------------------------------------------
% ARGUMENTS
% Mandatory
%  lat_data  A D by nsubj matrix array giving the value of the lattice
%            field at every point.
%  Kernel    either an object of class SepKernel or a numeric.
%            If class SepKernel:
%              if derivtype = 0: the fields 'kernel' and 'truncation' must
%                                be specified.
%              if derivtype = 1: the fields 'dkernel' and 'dtruncation'
%                                must be specified.
%              if derivtype = 2: the fields 'd2kernel' and 'd2truncation'
%                                must be specified.
%
%            If Kernel is numeric, the convolution field is generated by 
%            smoothing with an isotropic Gaussian kernel with FWHM = Kernel.
%            Truncation and adjust_kernel are set to be default values.
% Optional 
%  peak_est_locs a D by npeaks matrix giving the initial estimates of the
%               location of the peaks. If this is instead an integer: top
%               then the top number of maxima are considered and initial
%               locations are estimated from the underlying data. If this
%               is not specified then it is set to 1, i.e. only considering
%               the maximum.
%  field_type    Either 'Z' (mean field) or 'T' (t field). Default is 'Z'. 
%               If 'Z' lat_data is treated as a single observation of data
%               on a lattice. If 'T' lat_data is treated as multiple
%               observations corresponding to nsubj = lat_data(end)
%               subjects
%  xvals_vecs    a D-dimensional cell array whose entries are vectors giving the
%               xvalues at each each dimension along the lattice. It assumes
%               a regular, rectangular lattice (though within a given
%               dimension the voxels can be spaced irregularly).
%               I.e suppose that your initial lattice grid is a
%               4by5 2D grid with 4 voxels in the x direction and 5 in
%               the y direction. And that the x-values take the values:
%               [1,2,3,4] and the y-values take the values: [0,2,4,6,8].
%               Then you would take xvals_vecs = {[1,2,3,4], [0,2,4,6,8]}.
%               The default is to assume that the spacing between the
%               voxels is 1. If only one xval_vec direction is set the
%               others are taken to range up from 1 with increment given by
%               the set direction.
%  truncation
%  mask
%--------------------------------------------------------------------------
% OUTPUT
% peak_locs   the true locations of the top peaks in the convolution field.
%--------------------------------------------------------------------------
% EXAMPLES
%--------------------------------------------------------------------------
% AUTHOR: Samuel Davenport
%--------------------------------------------------------------------------

%%  Check mandatory input and get important constants
%--------------------------------------------------------------------------
if ~exist('field_type', 'var')
    field_type = 'Z';
end

% Ensure that field_type is of the right input
if ~ischar(field_type) || (~(strcmp(field_type, 'Z') || strcmp(field_type, 'T')))
    error('The only fields supported are mean and t fields')
end

% Get rid of any singleton dimensions
lat_data = squeeze(lat_data);

% Calculate the size of the data including number of subjects
Ldim = size(lat_data);

% Calculate the dimensions of the data
if strcmp(field_type, 'Z')
    % Calculate the number of dimensions of the data
    D = length(Ldim);
    
    % Dealing with 1D dimension issues
    % Turn the lattice data into a column vector
    if D == 2 && (Ldim(1) == 1)
        lat_data = lat_data';
        Ldim = fliplr(Ldim);
    end
    if D == 2 && (Ldim(2) == 1) %I.e. we're in 1D
        % Set D = 1;
        D = 1; 
        Ldim = Ldim(1);
    end
elseif strcmp(field_type, 'T')
    % For t fields Ldim(end) is the number of subjects
    Ldim = Ldim(1:end-1);
    
    % Calculate the number of dimensions of the data
    D = length(Ldim);
end

%%  add/check optional values
%--------------------------------------------------------------------------
if ~exist('peak_est_locs', 'var')
    % default option of peak_est_locs
    peak_est_locs = 1; %Default is to just consider the maximum.
end
if ~exist('mask', 'var') || isequal(mask, NaN)
    if D == 1
        mask = ones(Ldim,1); % In 1D use column vectors
%         if strcmp(field_type, 'Z')
%             mask = ones(1,Ldim); % In 1D use row vectors for 1D fields
%         elseif strcmp(field_type, 'T')
%             mask = ones(Ldim,1); % In 1D use row vectors for T fields
%         end
    else
        mask = ones(Ldim);
    end
else
    % Ensure that the mask is a column vector in 1D (for use in applyconvfield)
    if D == 1 && size(mask,1) == 1
        mask = mask';
    end
end

% Obtain the boundary of the mask (if this is not supplied)
if ~exist('boundary', 'var') || isnan(boundary)
    boundary = bndry_voxels( logical(mask), 'full' );
end

if ~exist('truncation', 'var')
    truncation = -1;
end

% Setting up xvals_vecs
if ~exist('xvals_vecs', 'var')
    xvals_vecs = {1:Ldim(1)};  %The other dimensions are taken case of below.
end
if ~iscell(xvals_vecs)
    xvals_vecs = {xvals_vecs};
end

if length(xvals_vecs) < D
    increm = xvals_vecs{1}(2) - xvals_vecs{1}(1);
    for d = (length(xvals_vecs)+1):D
        xvals_vecs{d} = xvals_vecs{1}(1):increm:(xvals_vecs{1}(1)+increm*(Ldim(d)-1));
    end
end

xvals_vecs_dims = zeros(1,D); xvals_starts_at = zeros(1,D);
for d = 1:D
    % Calculate the xvals_vecs dimension in each direction (for comparison
    % to Ldim)
    xvals_vecs_dims(d) = length(xvals_vecs{d});
    
    % Obtain the xvalue_start values
    xvals_starts_at(d) = xvals_vecs{d}(1);
end

%% Error checking
%--------------------------------------------------------------------------
if isnan(sum(lat_data(:)))
    error('Can''t yet deal with nans')
end
if ~isequal(xvals_vecs_dims, Ldim)
    error('The dimensions of xvals_vecs must match the dimensions of lat_data')
end

%%  main function
%--------------------------------------------------------------------------
% Define convolution field
if strcmp(field_type, 'Z')
    cfield = @(tval) applyconvfield(tval, lat_data, Kernel, mask, ...
                                                   truncation, xvals_vecs);
elseif strcmp(field_type, 'T')
    cfield = @(tval) applyconvfield_t( tval, lat_data, Kernel, ...
                                            mask, truncation, xvals_vecs );
end

% Mask the field (if necessary)
if ~isequal(mask, ones(Ldim)) && ~isequal(mask, ones([1, Ldim]))
    masked_field = @(x) mask_field( x, mask, xvals_vecs ).*cfield(x);
else
    masked_field = cfield;
end

% At the moment this is just done on the initial lattice. Need to
% change so that it's on the field evaluated on the lattice.
if (D > 2 || isnumeric(peak_est_locs))  && (isequal(size(peak_est_locs),...
                   [1,1])) && (floor(peak_est_locs(1)) == peak_est_locs(1))
    % Set the number of maxima to define
    numberofmaxima2find = peak_est_locs;
    
    % Calculate the field on the lattice
    resadd = 0; % Initialize with no points between the original points
    if strcmp(field_type, 'Z')
        lat_eval = convfield( lat_data.*mask, Kernel, resadd, D );
    elseif strcmp(field_type, 'T')
        lat_eval = convfield_t( lat_data.*mask, Kernel, resadd );
    end
    
    % Find the top local maxima of the field on the lattice
    max_indices = lmindices(lat_eval, numberofmaxima2find, mask); 
    
    % In D = 1 you need to transpose (CHECK THIS) Note the transpose here! 
    % It's necessary for the input to other functions.
    if D == 1
        max_indices = max_indices'; 
    end
    
    % Reset this in case there are less maxima than desired
    numberofmaxima2find = size(max_indices,2);
    
    % Initialize a matrix to store peak locations
    peak_est_locs = zeros(D, numberofmaxima2find);
    for I = 1:D
        peak_est_locs(I, :) = xvals_vecs{I}(max_indices(I,:));
    end
elseif iscell(peak_est_locs)
    % For D = 1, if you want to calculate multiple peaks you need to enter
    % a cell array (to differentiate between this and the top number of
    % peaks).
    peak_est_locs = cell2mat(peak_est_locs);
end

% Obtain the box sizes within which to search for the maximum
% Assign boxsize of 0.5 for voxels on the boundary and 1.5 for voxels not
% on the boundary.
npeaks = size(peak_est_locs, 2); % Calculate the number of estimates
s_mask = size(mask);             % Obtain the size of the mask

% Set the default box sizes within which to search for maxima
box_sizes = repmat({1.5}, 1, npeaks);

% For peaks initialized on the boundary change their box sizes to 0.5
for I = 1:npeaks
    if D > 1
        converted_index = convind( peak_est_locs(:,I) - xvals_starts_at' + 1, s_mask );
    else
        converted_index = peak_est_locs(:,I) - xvals_starts_at' + 1;
    end
    if boundary(round(converted_index)) % Need to come back to this an make it more general
        box_sizes{I} = 0.5;
    end
end

% Find local maxima
[ peaklocs, peakvals ] = findlms( masked_field, peak_est_locs, box_sizes );

end

% DEPRECATED:
%     top = peak_est_locs;
% %     xvalues_at_voxels = xvals2voxels( xvals_vecs );
%     teval_lat = smoothtstat(lat_data, Kernel);
% %     if D < 3
% %         teval_lat = tcf(xvalues_at_voxels);
% %     else
% %         smoothed_field = zeros([Ldim, nsubj]);
% %         smoothing_store = zeros(Ldim);
% %         for subj = 1:nsubj
% %             spm_smooth(lat_data(:,:,:,subj), smoothing_store, Kernel);
% %             smoothed_field(:,:,:,subj) = smoothing_store;
% %         end
% %         teval_lat = mvtstat(smoothed_field, Ldim);
% %     end


% options = optimoptions(@fmincon,'Display','off'); %Ensures that no output is displayed.
% for peakI = 1:npeaks
%     peaklocs(:, peakI) = fmincon(@(tval) -tcf(tval), peak_est_locs(:, peakI), A, b, [], [], [], [], [], options);
%     peakvals(peakI) = tcf(peaklocs(:, peakI));
% end
% [ peaklocs, peakvals ] = findlms( masked_field, peak_est_locs, 1.5 );
% npeaks = size(peak_est_locs, 2);
% peaklocs = zeros(D, npeaks);
% peakvals = zeros(1, npeaks); 
% 
% A = [eye(D);-eye(D)];
% b = [Ldim(:)+0.5;ones(D,1)-0.5];
% b = zeros(2*D,1);
% for d = 1:D
%     b(d) = xvals_vecs{d}(end);
% end
% for d = 1:D
%     b(d+D) = -xvals_vecs{d}(1);
% end
% for peakI = 1:npeaks
%     peak_locs(:, peakI) = fmincon(@(tval) -tcf(tval), peak_est_locs(:, peakI), A, b);
%     peak_vals(peakI) = tcf(peak_locs(:, peakI));
% end
