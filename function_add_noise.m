function audio = function_add_noise(audio)
%Function that adds impulsive noise
%The input audio must be a vector containing the audio
%Returns a vector of the same size with the audio with noise

percent = 0.50;

%audio(randi(numel(audio),round(percent*numel(audio)),1)) = rms(audio);
num_muestras_ruido = round(percent * numel(audio));
indices = randi(numel(audio), num_muestras_ruido, 1);
valor_ruido = rms(audio);
audio(indices) = valor_ruido; 
return
