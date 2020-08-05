%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%    This script tests the record_coverage function
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% prepare workspace
clear all
close all
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %% 1D examples
%% Simple 1D example
FWHM = 1; sample_size = 50; nvox = 100; resadd = 3;
spfn = @(nsubj) wnfield( nvox, nsubj ); niters = 1000;
params = ConvFieldParams( FWHM, resadd );
record_coverage( spfn, sample_size, params, niters)

%% Second small 1D example
FWHM = 3; sample_size = 10; nvox = 50; resadd = 1;
spfn = @(nsubj) wnfield( nvox, nsubj ); niters = 1000;
params = ConvFieldParams( FWHM, resadd );
record_coverage( spfn, sample_size, params, niters)

%% 1D bootstrap example

%% %% 2D examples
%% small 2D example 
%(Note that on a small domain conv and finelat are similar even for reasonable resadd)
FWHM = 3; resadd = 3; sample_size = 50;
spfn = @(nsubj) wnfield(Dim, nsubj); niters = 1000;
params = ConvFieldParams( FWHM, resadd );
record_coverage( spfn, sample_size, params, niters)

%% small 2D example - using HPE
FWHM = 3; resadd = 11; sample_size = 50;
spfn = @(nsubj) wnfield(Dim, nsubj); niters = 1000;
record_coverage_dep( spfn, sample_size, FWHM, resadd, niters, 'hpe')

%% large 2D example 
%(Note that on a small domain conv and finelat are similar even for reasonable resadd)
FWHM = 3; resadd = 1; sample_size = 50; Dim = [100,100];
spfn = @(nsubj) wnfield(Dim, nsubj); niters = 1000;
params = ConvFieldParams( [FWHM,FWHM], resadd );
record_coverage( spfn, sample_size, params, niters)

%% small 2D sphere example
FWHM = 3; resadd = 3; sample_size = 50; Dim = [5,5];
mask = bndry_voxels(true(Dim), 'full');
spfn = @(nsubj) wnfield(mask, nsubj); niters = 1000;
params = ConvFieldParams( [FWHM,FWHM], resadd );
coverage = record_coverage( spfn, sample_size, params, niters);

%% Compare max distribution and EC curves
L0 = EulerChar(mask, 0.5, 2); %@Fabian this is wrong
L0 = 1;
thresholds = -6:0.05:6;
av_L_est = mean(coverage.storeLKCs,2)';
EEC_conv = EEC( thresholds, av_L_est, L0, 'T', sample_size -1 );
plot(EEC_conv)
%% large 2D example
FWHM = 3; sample_size = 50; Dim = [50,50]; resadd = 1;
spfn = @(nsubj) wnfield(Dim, nsubj); niters = 1000;
record_coverage( spfn, sample_size, FWHM, resadd, niters)
 
%% %% 3D examples
%% Small 3D example
FWHM = 3; sample_size = 50; Dim = [5,5,5]; resadd = 1;
spfn = @(nsubj) wnfield(Dim, nsubj); niters = 1000;
record_coverage( spfn, sample_size, FWHM, resadd, niters)

%% Large 3D example (takes a while)
FWHM = 3; sample_size = 50; Dim = [50,50,50]; resadd = 1;
spfn = @(nsubj) wnfield(Dim, nsubj); niters = 1000;
record_coverage( spfn, sample_size, FWHM, resadd, niters, 'conv', 0)

%% MNImask example
mask = logical(imgload('MNImask')); FWHM = 3; sample_size = 10; 
Dim = [91,109,91]; resadd = 1; spfn = @(nsubj) wnfield(Dim, nsubj); 
niters = 1000;
record_coverage( spfn, sample_size, FWHM, resadd, niters, 'conv', 0)
