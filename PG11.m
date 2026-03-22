% CEDISP1 Group 11
% Contribution:
% Dan Dabuit - 
% Marion Melanio - Original recording of PG11.wav
% Gabriel Infante - 
% Tara Uy - Syllable segmentation/mapping, literature search of bahay kubo

% Load Data & Parameters
[y, Fs] = audioread('PG11.wav');
tempo = 120; % Bahay Kubo tempo (BPM)
% Note: I have no idea like I am assuming that's the tempo
% look at this for the music sheet: https://www.scribd.com/document/396017709/Bahay-Kubo
quarter_note_dur = 60 / tempo;
% Since there are 60 seconds in one minute, dividing 60 by the Beats Per Minute (BPM) 
% tells exactly how many seconds a single beat (a quarter note) lasts
% In this case, quarter note syllable is made to last 0.5 seconds, 
% while half note syllable will last 1.0 second

% Mapping the syllables with start and end points time {Syllable, Start(s), End(s)}
syllable_data = {
    'ba', 1.20, 1.56; 'hay', 2.30, 2.60; 'ku', 3.36, 3.70; 'bo', 4.34, 4.57;
    'ka', 5.28, 5.55; 'hit', 6.21, 6.45; 'mun', 7.23, 7.62; 'ti', 8.24, 8.43;
    'ang', 9.22, 9.58; 'ha', 10.17, 10.46; 'la', 11.09, 11.42; 'man', 12.30, 12.63;
    'do', 13.30, 13.77; 'on', 14.15, 14.46; 'ay', 15.15, 15.43; 'sa', 16.05, 16.37;
    'ri', 16.89, 17.06;
};

%{
Target Frequencies (Hz) and Durations (Beats)
In this case, I'm gonna need help putting the Frequencies which come from the musical notes
so I guess like G, A, B, or C like that then for Beats is how long the syllables are so if 
like solid black circle or hollow circle if that makes sense in a music sheet
(I'll try doing this tomorrow if no one has done it yet :> -Tara)
score = [
    ; % Line 1 Part A
    ; % Line 1 Part B
    ; % Line 2 Part A
    ; % Line 2 Part B
];
%}

% Tools (Commented out, used this to manually hear and map out the syllables)
%{
t = (0:length(y)-1)/Fs;
plot(t, y);
title('Syllable Waveforms');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

Example verification of a snippet:
t_start = 16.89; t_end = 17.06;
snippet = y(round(t_start*Fs) : round(t_end*Fs));
fprintf('Playing: [%.2f to %.2f]... ', t_start, t_end);
soundsc(snippet, Fs);
%}

% Final Outputs as required by Phase 2 specs
% soundsc(final_song, Fs);
% audiowrite('output_11.wav', final_song, Fs);

% Waveform Subplots (if needed)
%{
figure;
subplot(2,1,1); plot((1:line1_len)/Fs, final_song(1:line1_len));
title('Line 1: Bahay kubo, kahit munti'); xlabel('Time (s)'); grid on;
subplot(2,1,2); plot((1:length(final_song)-line1_len)/Fs, final_song(line1_len+1:end));
title('Line 2: Ang halaman doon ay sari-sari'); xlabel('Time (s)'); grid on;
%}

% [NEXT STEP] Pitch Analysis & Synthesis Engine?
% GOAL is to transform spoken syllables into a "Sung" melody.
% so Pitch detection (maybe autocorrelation), Pitch shifting (ratio
% needed), Synthesis (shift the pitch and stretch the timing to match the
% 120 BPM tempo without distorting the voice (this is what we're aiming)
