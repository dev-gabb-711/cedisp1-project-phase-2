% CEDISP1 Group 11
% Contribution:
% Daniel Dabuit - Assisted with initial file conversion (.wav) and early refinement of syllable timings.
% Marion Melanio - Recording of the raw audio, initial synthesis implementation, 
%                   and extraction/subplotting of vowel segments.
% Gabriel Infante - Led the technical refinement of syllable timings and 
%                   calculated/verified target frequency mappings.
% Tara Uy - Managed syllable segmentation and mapping; conducted literature 
%           research; assisted in pitch-shifting and timing refinement.
clear; clc; close all; % Clears workspace, command window, and closes all figure windows

%% 1. LOAD DATA & SET PARAMETERS
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

%% 2. MUSIC THEORY & SCORE MAPPING
% Define the fundamental frequencies (Hz) of notes in the G Major Scale
B2 = 123.47; C3 = 130.81; D3 = 146.83; E3 = 164.81; 
Fs3 = 185.00; G3 = 196.00; A3 = 220.00; B3 = 246.94;

score = {
    % --- LINE 1 ---
    1,  D3,  1.2; % ba  (Sol)
    2,  G3,  2;   % hay (Do)
    3,  A3,  1;   % ku  (Re)
    4,  Fs3, 2;   % bo  (Ti) - Held for 2 beats
    5,  D3,  1;   % ka  (Sol)
    6,  E3,  2;   % hit (La)
    7,  Fs3, 1;   % mun (Ti)
    8,  D3,  2;   % ti  (Sol) - Held for 2 beats
    
    % --- LINE 2 ---
    9,  B2,  0.7; % ang (Mi) - Lowest note in the song (123 Hz)
    10, C3,  0.5; % ha  (Fa)
    11, D3,  1;   % la  (Sol)
    12, E3,  1.2; % man (La)
    13, D3,  1;   % do  (Sol)
    14, C3,  2;   % on  (Fa)
    15, A3,  1;   % ay  (Re)
    16, A3,  1.2;   % sa  (Re)
    17, B3,  1;   % ri  (Mi) - Highest note in the song (246 Hz)
    18, A3,  1.2;   % sa  (Re)
    19, G3,  1;   % ri  (Do) - Resolves perfectly to the root note
};

%% 3. SYNTHESIS ENGINE (OVERLAP-MIXING)
disp('Extracting original pitches and synthesizing...');

total_beats = sum(cell2mat(score(:, 3)));
total_samples = round((total_beats + 2) * quarter_note_dur * Fs); 
final_song = zeros(total_samples, 1);

current_idx = 1; 
line1_len = 0;   

for i = 1:size(score, 1)
    syllable_idx = score{i, 1};
    target_freq = score{i, 2};
    duration_beats = score{i, 3};
    
    t_start = syllable_data{syllable_idx, 2};
    t_end = syllable_data{syllable_idx, 3};
    snippet = y(round(t_start*Fs) : round(t_end*Fs)); 
    
    % Robust Pitch Detection (DC Removal + Lowpass Filter)
    mid_start = round(length(snippet) * 0.25);
    mid_end = round(length(snippet) * 0.75);
    voiced_part = snippet(mid_start:mid_end);
    voiced_part = voiced_part - mean(voiced_part);
    
    % The filter guarantees the math locks onto the human voice, not background noise
    [b, a] = butter(2, 600/(Fs/2), 'low');
    voiced_part = filtfilt(b, a, voiced_part);
    
    voiced_part = voiced_part .* hamming(length(voiced_part));
    
    [r, lags] = xcorr(voiced_part);
    r = r(lags >= 0); 
    minPitch = 80; maxPitch = 400;
    min_lag = round(Fs/maxPitch);
    max_lag = round(Fs/minPitch);
    r(1:min_lag) = 0; 
    if length(r) > max_lag
        r(max_lag+1:end) = 0; 
    end
    [~, peak_idx] = max(r); 
    orig_freq = Fs / (peak_idx - 1); 
    if orig_freq < 80 || orig_freq > 400 || isnan(orig_freq)
        orig_freq = 150; 
    end
    
    % Calculate target duration based on the musical score
    target_dur_sec = duration_beats * quarter_note_dur;
    
    % Process audio through Wavetable Sustainer
    synth_note = shift_and_sustain(snippet, orig_freq, target_freq, target_dur_sec, Fs);
    
    % Overlap-Mixing Timeline
    note_len = length(synth_note);
    end_idx = current_idx + note_len - 1;
    
    if end_idx > total_samples
        synth_note = synth_note(1 : total_samples - current_idx + 1);
        end_idx = total_samples;
    end
    
    final_song(current_idx:end_idx) = final_song(current_idx:end_idx) + synth_note;
    
    step_samples = round(duration_beats * quarter_note_dur * Fs);
    overlap_samples = round(0.08 * Fs); % 80ms
    current_idx = current_idx + step_samples - overlap_samples;
    
    if i == 8
        line1_len = current_idx;
    end
end

%% 4. FORMATTING TO REQUIREMENTS
target_Fs = 16000;
if Fs ~= target_Fs
    final_song = resample(final_song, target_Fs, Fs);
    line1_len = round(line1_len * (target_Fs / Fs)); 
    Fs = target_Fs;
end

% Amplitude Normalization
final_song = final_song / max(abs(final_song));

%% 5. OUTPUTS
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
title('Line 2: /Ang halaman doon ay sari-sari/'); 
xlabel('Time (s)'); ylabel('Amplitude'); 
grid on; axis tight;

%% LOCAL FUNCTION
% This function simply pitch-shifts and applies a smooth natural decay
% to the note, avoiding all robotic and stuttering stretching artifacts!
function out_audio = shift_and_sustain(audio_in, orig_freq, target_freq, target_dur_sec, Fs)
    % MILD pitch shift only (cap at ±13 semitones max)
    % Voice sounds alien beyond cap so use the natural voice
    semitone_shift = 12 * log2(target_freq / orig_freq);
    semitone_shift = max(-13, min(13, semitone_shift)); % clamp to ±8 semitones
    clamped_target = orig_freq * 2^(semitone_shift / 12);

    [P, Q] = rat(orig_freq / clamped_target, 1e-4); % looser tolerance = smaller P,Q = less distortion
    shifted = resample(audio_in, P, Q);

    target_samples = round(target_dur_sec * Fs);
    curr_samples   = length(shifted);

    % Simple zero-pad OR natural truncation
    % NO looping at all so just let the note ring then fade to silence
    if curr_samples < target_samples
        % Fade out the tail of the snippet naturally
        fade_len = round(curr_samples * 0.10); % was 0.30
        if fade_len > 1
            shifted(end-fade_len+1:end) = shifted(end-fade_len+1:end) .* linspace(1, 0, fade_len)';
        end
        % Pad the rest with silence
        out_audio = [shifted; zeros(target_samples - curr_samples, 1)];
    else
        % Natural truncation with a short fade out
        out_audio = shifted(1:target_samples);
        fade_len = round(target_samples * 0.10);
        if fade_len > 1
            out_audio(end-fade_len+1:end) = out_audio(end-fade_len+1:end) .* linspace(1, 0, fade_len)';
        end
    end

    % 3. Master Edge Smooth (de-clicking)
    fade_len = round(0.02 * Fs);
    if length(out_audio) > 2*fade_len
        out_audio(1:fade_len) = out_audio(1:fade_len) .* linspace(0, 1, fade_len)';
        out_audio(end-fade_len+1:end) = out_audio(end-fade_len+1:end) .* linspace(1, 0, fade_len)';
    end
end
