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

%---SYNTHETIC TRIGGER GENERATION--
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

%% 3. RANGE-TIME INTENSITY (RTI) PLOT
RP = fliplr(ifft(sif, [], 2));

%---Calculate Range and Time Axes--
B = fstop - fstart; % Sweep Bandwidth
fb_axis = linspace(0, FS/2, num_samples);
range_axis = (c * Tp * fb_axis) / (2 * B);
time_axis = linspace(0, total_pulses * Tp, total_pulses);

%---1. Standard RTI (Raw Phase History)--
RTI = abs(RP);
RTI_db = 20 * log10(RTI + eps);
RTI_db = RTI_db - max(RTI_db(:)); % Normalize to 0 dB max

%---2. MTI (Moving Target Indicator)--
RP_mti = RP - mean(RP, 1);
RTI_mti = abs(RP_mti);
RTI_mti_db = 20 * log10(RTI_mti + eps);
RTI_mti_db = RTI_mti_db - max(RTI_mti_db(:)); % Normalize to 0 dB max

%---Plotting--
figure('Color', 'w', 'Position', [100, 100, 800, 600]);

% Plot 2: MTI (Moving Objects Isolated)
imagesc(time_axis, range_axis, RTI_mti_db.', [-40 0]);
colormap('jet'); colorbar;
set(gca, 'YDir', 'normal');
ylim([0 15]); % Limit Y-axis to 15m
title('Range vs Time (MTI)-Moving Targets Isolated');
xlabel('Time (s)'); ylabel('Range (m)');

%% 4. VELOCITY ESTIMATION (Filtered)
% 1. Find the range index of the strongest moving target for each pulse
[~, max_idx] = max(RTI_mti, [], 2);
target_range = range_axis(max_idx); % Convert index to meters

% 2. Smooth the trajectory to reduce "staircase" noise from discrete range bins
smooth_window = round(0.5 / Tp);
target_range_smoothed = smooth(target_range, smooth_window)/2;

% 2. Calculate Raw Velocity
inst_velocity_raw = diff(target_range_smoothed) / Tp;

% 3. APPLY MEDIAN FILTER (Removes the sharp "jitter" spikes)
% Requires Signal Processing Toolbox.
try
    inst_velocity_med = medfilt1(inst_velocity_raw, 15);
catch
    inst_velocity_med = smooth(inst_velocity_raw, 15);
end

% 4. APPLY VELOCITY THRESHOLD (The "Deadzone")
v_threshold = 1; % Adjust this (m/s) based on your walking speed
inst_velocity_cleaned = inst_velocity_med;
inst_velocity_cleaned(abs(inst_velocity_cleaned) < v_threshold) = 0;

velocity_time_axis = time_axis(1:end-1);

%% 7. PLOTTING REFINED RESULTS
figure('Color', 'w', 'Position', [100, 100, 900, 500]);

subplot(2,1,1);
plot(time_axis, target_range_smoothed, 'LineWidth', 2, 'Color', [0.8 0 0]);
grid on; ylabel('Range (m)'); title('Cleaned User Tracking');
ylim([0 7]);

subplot(2,1,2);
plot(velocity_time_axis, inst_velocity_cleaned, 'LineWidth', 1.5, 'Color', [0 0.5 0.2]);
hold on;
yline(0, '--k', 'Zero');
grid on;
xlabel('Time (s)'); ylabel('Velocity (m/s)');
title('Filtered Radial Velocity (Noise & Jitter Removed)');
ylim([-4 4]);
