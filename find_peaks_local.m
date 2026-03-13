function [f, t] = find_peaks_local(P, thresh)
% FIND_PEAKS_LOCAL: Identifica puntos de máxima energía en el espectrograma.
% P: Espectrograma en dB (Matriz de Frecuencia x Tiempo).
% thresh: Umbral de intensidad (dB) para descartar ruido de fondo.
% f: Vector con las filas (índices de frecuencia) de los picos.
% t: Vector con las columnas (índices de tiempo/frames) de los picos.

    % 1. Filtrado inicial por intensidad
    % Crea una matriz lógica (ceros y unos) donde solo quedan los puntos 
    % que superan el volumen mínimo (umbral).
    mask = (P > thresh);

    % 2. Inicialización de la matriz de resultados
    [r, c] = size(P); 
    picos = false(r, c); % Matriz vacía de "falsos" del mismo tamaño que el audio

    % 3. Detección de Máximos Locales (Comparación 4-conectada)
    % Comparamos cada punto con sus 4 vecinos (Norte, Sur, Este, Oeste).
    % Usamos (2:end-1) para evitar los bordes y que no dé error de índice.
    picos(2:end-1, 2:end-1) = mask(2:end-1, 2:end-1) & ... % Debe superar el umbral
        P(2:end-1, 2:end-1) > P(1:end-2, 2:end-1) & ...   % Mayor que el vecino de ARRIBA (Norte)
        P(2:end-1, 2:end-1) > P(3:end, 2:end-1)   & ...   % Mayor que el vecino de ABAJO (Sur)
        P(2:end-1, 2:end-1) > P(2:end-1, 1:end-2) & ...   % Mayor que el vecino de la IZQUIERDA (Oeste)
        P(2:end-1, 2:end-1) > P(2:end-1, 3:end);          % Mayor que el vecino de la DERECHA (Este)
    
    % 4. Extracción de coordenadas
    % La función find() busca todos los "true" en la matriz 'picos' y 
    % devuelve sus posiciones en formato de lista (filas y columnas).
    [f, t] = find(picos);
end
