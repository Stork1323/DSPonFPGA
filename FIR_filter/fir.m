% Parameters
filename = 'sine.hex';  % Hex file name
sampling_frequency = 100e6;  % 100 MHz
duration = 1;  % Duration in seconds

% Read the hex file
fileID = fopen(filename, 'r');
hexData = textscan(fileID, '%s');  % Read hex values as strings
fclose(fileID);

% Convert hex to decimal (24-bit signed integer)
data = hex2dec(hexData{1});
data = data - (data > 2^23) * 2^24;  % Convert to signed integers

% Create a time vector
numSamples = length(data);
timeVector = (0:numSamples-1) / sampling_frequency;

% Save the waveform data in a variable
waveform = data;  % Now 'waveform' holds the sine wave data

% Optionally, plot the data
figure;
subplot(2, 1, 1);
plot(timeVector, waveform);
xlabel('Time (s)');
ylabel('Amplitude');
title('Sine Wave from Hex Data');
grid on;

% Frequency response analysis using FFT
N = length(waveform);  % Number of samples
Y = fft(waveform);  % Compute the FFT
f = (0:N-1)*(sampling_frequency/N);  % Frequency vector

% Compute the magnitude
magnitude = abs(Y)/N;  % Normalize the magnitude
magnitude = magnitude(1:N/2+1);  % Take the positive frequencies
magnitude(2:end-1) = 2*magnitude(2:end-1);  % Adjust magnitude for single-sided spectrum
f = f(1:N/2+1);  % Take the positive frequencies

% Plot the frequency response
subplot(2, 1, 2);
plot(f, magnitude);
xlabel('Frequency (Hz)');
ylabel('Magnitude');
title('Frequency Response');
grid on;

% Optionally save the data to a .mat file
save('sine_wave.mat', 'waveform', 'timeVector', 'f', 'magnitude');

