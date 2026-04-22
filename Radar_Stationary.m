%% Standard RTI Only (SAR and 1D Profile Removed)
clear all; close all; clc;

%% 1. FILE LOADING & PARAMETERS
% Radar Settings
fstart = 2.2e9; fstop = 2.5e9; Tp = 23e-3; c = 3e8;

% Load data 
try
    [Y, FS] = audioread('C:\Users\Public\Documents\6th_sem\EE396\Matlab\stat.wav'); 
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

%% 3. RANGE PROFILE (RTI GENERATION)
% Recover the range profiles directly from the sliced pulses
RP = fliplr(ifft(sif, [], 2));

% --- Calculate Range and Time Axes ---
B = fstop - fstart; % Sweep Bandwidth
fb_axis = linspace(0, FS/2, num_samples); 
range_axis = (c * Tp * fb_axis) / (2 * B);
time_axis = linspace(0, total_pulses * Tp, total_pulses);

% --- Standard RTI (Raw Phase History) ---
RTI = abs(RP);
RTI_db = 20 * log10(RTI + eps);
RTI_db = RTI_db - max(RTI_db(:)); % Normalize to 0 dB max

%% 4. PLOTTING
figure('Color', 'w', 'Position', [150, 150, 800, 600]);

% Single, full-window plot for RTI
imagesc(time_axis, range_axis, RTI_db.', [-40 0]);
colormap('jet'); 
colorbar;
set(gca, 'YDir', 'normal');
ylim([0 15]); % Adjust limits here if you want to look past 15 meters
title('Range-Time Intensity (RTI)');
xlabel('Time (s)'); 
ylabel('Range (m)');
