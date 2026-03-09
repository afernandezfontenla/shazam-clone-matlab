function [S,F,T] = calcular_espectrograma(x,fs)
% x: señal de audio. fs: frecuencia de muestreo en Hz.
% S: espectrograma en decibelios
% F: vector de frecuencias en Hz
% T: vector de tiempo en segundos

%Convertir a mono
if size(x,2) > 1
    x = mean(x,2);
end

%Normaizar amplitud al rando de -1 a 1
valor_maximo = max(abs(x));
if valor_maximo > 0
    x = x/valor_maximo;
end

%Configuracion ventana Hamming
Ventana_duracion = 0.04; % En segundos
Ventana_longitud = round(Ventana_duracion*fs); % Número de muestras
Ventana = hamming(Ventana_longitud, 'periodic');

Solapamiento = round(0.75*Ventana_longitud); %Solapamiento 75%

nfft = max(1024,2^nextpow2(Ventana_longitud));

%CALCULO ESPECTROGRAMA

[~,F,T,P] = spectrogram(x,Ventana,Solapamiento,nfft,fs);

S=10*log10(P+eps);

%Recortar solo a las frecuencias útiles
Frecuencia_maxima = fs/2; %Mirar si podemos reducir esto más.
idx = F <= Frecuencia_maxima;

S=S(idx,:);
F=F(idx);
end