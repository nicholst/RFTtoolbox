%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%    This script tests the EECthreshold function
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %% 1D Examples
%% Simple 1D example
FWHM = 6; resadd = 1; nsubj = 50; nvox = 100;
lat_data = wnfield(nvox, nsubj);

[tcfield, cfields] = convfield_t_Field( lat_data, FWHM, resadd );
dcfields = convfield_Field( lat_data, FWHM, 1, resadd );
[L,L0] = LKC_voxmfd_est( cfields, dcfields );

threshold_spm = spm_thresh( L, L0, 'T', nsubj -1, 0.05)
threshold_EEC = EECthreshold( 0.05, L, L0, 'T', nsubj -1)

%% %% 2D Examples
%% Simple 2D example
FWHM = 6; resadd = 1; nsubj = 50; Dim = [50,50];
lat_data = wnfield(Dim, nsubj);

[tcfield, cfields] = convfield_t_Field( lat_data, FWHM, resadd );
dcfields = convfield_Field( lat_data, FWHM, 1, resadd );
[L,L0] = LKC_voxmfd_est( cfields, dcfields );

threshold_spm = spm_thresh( L, L0, 'T', nsubj -1, 0.05)
threshold_EEC = EECthreshold( 0.05, L, L0, 'T', nsubj -1)

%% %% 3D Examples
%% Simple 3D example
FWHM = 2; resadd = 1; nsubj = 50; Dim = [5,5,5];
lat_data = wnfield(Dim, nsubj);

[tcfield, cfields] = convfield_t_Field( lat_data, FWHM, resadd );
dcfields = convfield_Field( lat_data, FWHM, 1, resadd );
[L,L0] = LKC_voxmfd_est( cfields, dcfields );

threshold_spm = spm_thresh( L, L0, 'T', nsubj -1, 0.05)
threshold_EEC = EECthreshold( 0.05, L, L0, 'T', nsubj -1)
