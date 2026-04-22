%% Stationary & moving object
clear all; close all; clc;

%% 1. FILE LOADING & PARAMETERS
% Radar Settings
fstart = 2.2e9; fstop = 2.5e9; Tp = 23e-3; c = 3e8;

% Aperture length converted from feet (2 ft) to meters
aperture_len_ft = 2; L = aperture_len_ft * 0.3048;

try
    [Y, FS] = audioread('C:\Users\Public\Documents\6th_sem\EE396\Matlab\mv.wav');
catch
    error('File not found. Check the filename.');
end

% Extract Mono Signal
s_raw = -1 * Y(:,2); 
clear Y;

% --- SYNTHETIC TRIGGER GENERATION ---
samples_per_pulse = floor(Tp * FS); 
total_pulses = floor(length(s_raw) / samples_per_pulse);
num_samples_final = floor(samples_per_pulse / 2);
sif = zeros(total_pulses, num_samples_final);
fprintf('Processing %d pulses...\n', total_pulses);

%% 2. SIGNAL PARSING (SLICING)
for jj = 1:total_pulses
    idx_start = (jj-1) * samples_per_pulse + 1;
    idx_end = jj * samples_per_pulse;
    pulse_data = s_raw(idx_start:idx_end);
    
    q = ifft(pulse_data);
    analytic_half = q(floor(end/2)+1 : end);
    sif(jj,:) = fft(analytic_half).'; 
end

[num_pulses, num_samples] = size(sif);

%% 3. SAR IMAGING (RMA)
delta_x = L / num_pulses; 
Kr = linspace((4*pi/c)*fstart, (4*pi/c)*fstop, num_samples);

% Hanning Window
H = 0.5 + 0.5*cos(2*pi*((1:num_samples)-num_samples/2)/num_samples);
sif = sif .* repmat(H, num_pulses, 1);

% Along-track FFT (Cross-range)
zpad = 1024; 
S = fftshift(fft(sif, zpad, 1), 1);
Kx = linspace(-pi/delta_x, pi/delta_x, zpad);

% --- FIXED STOLT INTERPOLATION ---
Ky_even = linspace(min(Kr), max(Kr), num_samples);
S_st = zeros(zpad, num_samples);

for ii = 1:zpad
    % Calculate Ky values
    Ky_cur = sqrt(Kr.^2 - Kx(ii)^2);
    
    % FIX: Only use indices where Ky is real and positive
    % Since Kr is strictly increasing, Ky_cur will be strictly increasing (unique) here.
    mask = (imag(Ky_cur) == 0) & (Ky_cur > 0);
    
    if sum(mask) > 1
        % Interpolate only using the valid, unique points
        S_st(ii,:) = interp1(Ky_cur(mask), S(ii,mask), Ky_even, 'linear', 0);
    end
end

S_st(isnan(S_st)) = 0;

%% 4. RENDERING & ROOM PLOT
v = ifft2(S_st, zpad*2, num_samples*2);
img = abs(v);
img = fliplr(rot90(img));

% Room Scaling (Converted from 20x25 ft to meters)
% 10 ft * 0.3048 = 3.048 m
% 25 ft * 0.3048 = 7.62 m
cross_m = linspace(-10, 10, size(img, 2)); 
down_m = linspace(0, 25, size(img, 1)); 

% Logarithmic Scaling
img_db = 20 * log10(img + eps);
img_db = img_db - max(img_db(:));

figure('Color', 'w');
imagesc(cross_m, down_m, img_db, [-35 0]); 
colormap('jet'); colorbar; axis equal;
title('SAR Image: 6.1 x 7.6m Room (Fixed interp1)');
xlabel('Cross-range (m)'); ylabel('Down-range (m)');
grid on;

%% 5. RANGE-TIME INTENSITY (RTI) & MTI PLOT
% Recover the range profiles by taking the IFFT of the time-domain phase history.
% Note: Due to the MIT-style ifft slicing earlier in the code, the frequency bins 
% are reversed (Nyquist down to DC). We use fliplr to correct the orientation so 
% index 1 corresponds to 0 meters.
RP = fliplr(ifft(sif, [], 2));

% --- Calculate Range and Time Axes ---
B = fstop - fstart; % Sweep Bandwidth
% The analytic_half covers frequencies from 0 to FS/2
fb_axis = linspace(0, FS/2, num_samples); 
range_axis = (c * Tp * fb_axis) / (2 * B);

% Slow-time (pulse) axis
time_axis = linspace(0, total_pulses * Tp, total_pulses);

% --- 1. Standard RTI (Raw Phase History) ---
RTI = abs(RP);
RTI_db = 20 * log10(RTI + eps);
RTI_db = RTI_db - max(RTI_db(:)); % Normalize to 0 dB max

% --- 2. MTI (Moving Target Indicator) ---
% Subtract the average background to cancel out stationary clutter (walls, etc.)
% This highlights phase/amplitude changes caused by moving targets.
RP_mti = RP - mean(RP, 1);
RTI_mti = abs(RP_mti);
RTI_mti_db = 20 * log10(RTI_mti + eps);
RTI_mti_db = RTI_mti_db - max(RTI_mti_db(:)); % Normalize to 0 dB max

% --- Plotting ---
figure('Color', 'w', 'Position', [100, 100, 800, 600]);



% Plot 2: MTI (Moving Objects Isolated)
imagesc(time_axis, range_axis, RTI_mti_db.', [-40 0]);
colormap('jet'); colorbar;
set(gca, 'YDir', 'normal');
ylim([0 15]); % Limit Y-axis to 15m
title('Range vs Time (MTI) - Moving Targets Isolated');
xlabel('Time (s)'); ylabel('Range (m)');
