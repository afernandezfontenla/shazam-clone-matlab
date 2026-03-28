function huella = construir_huella(audio, fs)

% Convertir a mono si es estéreo
if size(audio,2) == 2
    audio = mean(audio,2);
end

% 1. Calcular espectrograma
[S,F,T] = spectrogram(audio, 1024, 512, 1024, fs);

% Magnitud del espectrograma
S = abs(S);

% 2. Detectar puntos relevantes (máximos locales)
picos = imregionalmax(S);

% Obtener coordenadas de los picos
[picos_f, picos_t] = find(picos);

% 3. Obtener frecuencias y tiempos
frecuencias = F(picos_f);
tiempos = T(picos_t);

% 4. Calcular distancias entre puntos consecutivos
huella = [];

for i = 1:length(tiempos)-1
    delta_t = tiempos(i+1) - tiempos(i);
    
    huella = [huella;
              frecuencias(i) delta_t];
end

end
