% CEDISP1 Group 11
% Contribution:
% Dan Dabuit - Assisted with file conversion to .wav format
% Marion Melanio - Recording of the .wav file and subplotting of extracted vowels
% Gabriel Infante - Calculated and displayed the average frequencies
% Tara Uy - Syllable segmentation/mapping, literature search of bahay kubo
clear; clc; close all; % Clears workspace, command window, and closes all figure windows

%% --- 1. LOAD DATA & SET PARAMETERS ---
disp('Loading PG11.wav...');
% audioread extracts the audio signal array (y) and sampling rate (Fs)
[y, Fs] = audioread('PG11.wav'); 

% Calculate duration of one beat based on tempo
tempo = 160; % Beats per minute (BPM)
quarter_note_dur = 60 / tempo; % Duration of one beat in seconds

% Manual Time-Domain Segmentation
% Maps each syllable to its exact start and end times in the raw audio
% Format: {'Syllable', Start_Time(s), End_Time(s)}
syllable_data = {
    'ba', 1.20, 1.56; 'hay', 2.30, 2.60; 'ku', 3.36, 3.70; 'bo', 4.34, 4.57;
    'ka', 5.28, 5.55; 'hit', 6.21, 6.45; 'mun', 7.23, 7.62; 'ti', 8.24, 8.43;
    'ang', 9.22, 9.58; 'ha', 10.17, 10.46; 'la', 11.09, 11.42; 'man', 12.30, 12.63;
    'do', 13.30, 13.77; 'on', 14.15, 14.46; 'ay', 15.15, 15.43; 'sa', 16.05, 16.37;
    'ri', 16.89, 17.06; 'sa', 16.05, 16.37; 'ri', 16.89, 17.06;
};

%% --- 2. MUSIC THEORY & SCORE MAPPING ---
% Define the fundamental frequencies (Hz) of notes in the C3 Major Scale
C3 = 130.81; D3 = 146.83; E3 = 164.81; F3 = 174.61; 
G3 = 196.00; A3 = 220.00; C4 = 261.63;

% Musical Score of "Bahay Kubo"
% Format: {Syllable_Index, Target_Frequency (Hz), Note_Duration (Beats)}
score = {
    % --- LINE 1: Bahay kubo, kahit munti ---
    1,  G3, 1;   % ba
    2,  C4, 1;   % hay
    3,  A3, 1;   % ku
    4,  G3, 2;   % bo (Held for 2 beats)
    5,  E3, 1;   % ka
    6,  G3, 1;   % hit
    7,  F3, 1;   % mun
    8,  D3, 2;   % ti (Held for 2 beats)
    
    % --- LINE 2: Ang halaman doon ay sari ---
    9,  G3, 0.5; % ang (Eighth note / half beat)
    10, G3, 0.5; % ha  (Eighth note / half beat)
    11, G3, 1;   % la
    12, C4, 1;   % man
    13, A3, 1;   % do
    14, G3, 1;   % on
    15, E3, 1;   % ay
    16, D3, 1;   % sa (Targeting resolution)
    17, C3, 1;   % ri (Resolves to root note C3 for a closed ending)
    18, D3, 1;   % sa 
    19, C3, 2;   % ri 
};

%% --- 3. SYNTHESIS ENGINE ---
disp('Extracting original pitches and synthesizing...');
final_song = []; % Empty array to hold the generated song
line1_len = 0;   % Tracker for plotting subplots later

% Loop through every note in the musical score
for i = 1:size(score, 1)
    % 3.1 Extract variables for current note
    syllable_idx = score{i, 1};
    target_freq = score{i, 2};
    duration_beats = score{i, 3};
    duration_sec = duration_beats * quarter_note_dur; % Convert beats to actual seconds
    
    % 3.2 Extract the raw audio snippet for the specific syllable
    t_start = syllable_data{syllable_idx, 2};
    t_end = syllable_data{syllable_idx, 3};
    snippet = y(round(t_start*Fs) : round(t_end*Fs)); % Convert time to sample indices
    
    % 3.3 Pitch Detection via Autocorrelation (xcorr)
    % Extract only the middle 50% to isolate the vowel and avoid unvoiced consonants
    mid_start = round(length(snippet) * 0.25);
    mid_end = round(length(snippet) * 0.75);
    voiced_part = snippet(mid_start:mid_end);
    
    % Perform cross-correlation to find repeating pitch periods
    [r, lags] = xcorr(voiced_part);
    r = r(lags >= 0); % Keep only non-negative lags
    
    % Limit search to human voice range (80 Hz to 800 Hz) to avoid noise/errors
    minPitch = 80; maxPitch = 800;
    r(1:round(Fs/maxPitch)) = 0; % Zero out frequencies too high
    if length(r) > round(Fs/minPitch)
        r(round(Fs/minPitch)+1:end) = 0; % Zero out frequencies too low
    end
    [~, peak_idx] = max(r); % Find the highest peak which represents the fundamental period
    
    % Calculate original pitch frequency (subtract 1 because MATLAB is 1-indexed)
    orig_freq = Fs / (peak_idx - 1); 
    
    % Fallback mechanism if Autocorrelation fails
    if orig_freq < 80 || orig_freq > 800
        orig_freq = 150; 
    end
    
    % 3.4 Process audio through the custom pitch-shifting function
    synth_note = shift_and_stretch(snippet, orig_freq, target_freq, duration_sec, Fs);
    
    % 3.5 Append the synthesized note to the final song array
    final_song = [final_song; synth_note];
    
    % 3.6 Insert waltz phrasing rests (silence) after 'bo' and 'ti'
    if i == 4 || i == 8
        rest_samples = zeros(round(quarter_note_dur * Fs), 1);
        final_song = [final_song; rest_samples];
    end
    
    % Track where Line 1 ends to divide the subplot later
    if i == 8
        line1_len = length(final_song);
    end
end

%% --- 4. FORMATTING TO REQUIREMENTS ---
% Requirement: Output must be exactly 16 kHz sampling rate
target_Fs = 16000;
if Fs ~= target_Fs
    final_song = resample(final_song, target_Fs, Fs);
    line1_len = round(line1_len * (target_Fs / Fs)); % Adjust plot tracker to new Fs
    Fs = target_Fs;
end

% Amplitude Normalization: Scale everything down so max peak is 1.0 
% This prevents audio clipping/distortion when saving to WAV
final_song = final_song / max(abs(final_song));

%% --- 5. OUTPUTS ---
disp('Playing Final Synthesized Song...');
soundsc(final_song, Fs); % Plays audio normalized to dynamic range

% Requirement: Save array as a .wav file
filename = 'output_11.wav';
audiowrite(filename, final_song, Fs);
disp(['Saved synthesized song to ', filename]);

% Requirement: Subplot separating Line 1 and Line 2
figure('Name', 'Bahay Kubo Synthesis - Group 11');

% Upper Subplot: Line 1 (Index 1 to line1_len)
subplot(2,1,1); 
t1 = (0:line1_len-1)/Fs; % Create time vector for x-axis
plot(t1, final_song(1:line1_len), 'b');
title('Line 1: /Bahay kubo, kahit munti/'); 
xlabel('Time (s)'); ylabel('Amplitude'); 
grid on; axis tight;

% Lower Subplot: Line 2 (From line1_len to end)
subplot(2,1,2); 
t2 = (0:length(final_song)-line1_len-1)/Fs;
plot(t2, final_song(line1_len+1:end), 'r');
title('Line 2: /Ang halaman doon ay sari/'); 
xlabel('Time (s)'); ylabel('Amplitude'); 
grid on; axis tight;

%% --- LOCAL FUNCTION ---
% This function changes the pitch and fits the audio into the required musical beat
function out_audio = shift_and_stretch(audio_in, orig_freq, target_freq, target_dur_sec, Fs)
    % 1. Pitch Shifting via Resample
    % Gets the integer ratio of orig vs target to safely resample
    [P, Q] = rat(orig_freq / target_freq);
    shifted_audio = resample(audio_in, P, Q);
    
    % 2. Envelope Shaping (Fade-in and Fade-out)
    % Applies a 20ms linear window to prevent clicking/popping noises at the edges
    fade_len = round(0.02 * Fs); 
    if length(shifted_audio) > 2*fade_len
        window = linspace(0, 1, fade_len)';
        shifted_audio(1:fade_len) = shifted_audio(1:fade_len) .* window;
        shifted_audio(end-fade_len+1:end) = shifted_audio(end-fade_len+1:end) .* flipud(window);
    end
    
    % 3. Time Alignment (Zero-Padding / Staccato Method)
    target_samples = round(target_dur_sec * Fs); % Exact length needed for the note
    curr_samples = length(shifted_audio);
    
    out_audio = zeros(target_samples, 1); % Create a container filled with silence
    
    if curr_samples >= target_samples
        % If audio is longer than the required beat, truncate it
        out_audio = shifted_audio(1:target_samples);
    else
        % If audio is shorter, place it at the start, leaving the rest as silence (zero-padding)
        out_audio(1:curr_samples) = shifted_audio;
    end
end