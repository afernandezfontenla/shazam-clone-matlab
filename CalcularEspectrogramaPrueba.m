[x,fs] = audioread('001.mp3');
[S,F,T] = calcular_espectrograma(x,fs);

imagesc(T,F,S);
axis xy;
xlabel('Tiempo (s)');
ylabel('Frecuencia (Hz)');
title('Espectrograma');
colorbar;