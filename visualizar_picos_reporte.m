function visualizar_picos_reporte(audio, fs)
    % 1. Obtener espectrograma con los parámetros oficiales (Compañero 1)
    [S, F, T] = calcular_espectrograma(audio, fs);
    
    % 2. Detección de picos con FILTRO DE ENERGÍA (Compañero 2 + Optimización)
    % Usamos el mismo umbral dinámico que en el indexador para coherencia
    umbral = mean(S(:)) + 1.5 * std(S(:)); 
    
    % Solo marcamos como picos los máximos regionales que superan el umbral
    picos_mask = imregionalmax(S) & (S > umbral);
    [idx_f, idx_t] = find(picos_mask);

    % 3. Crear la figura para el entregable
    figure('Color', 'w', 'Name', 'Captura Oficial para el Reporte');
    
    % Dibujamos el espectrograma de fondo
    imagesc(T, F, S); 
    axis xy; % Orientación correcta de frecuencias
    colormap('jet');
    colorbar;
    ylabel(colorbar, 'Intensidad (dB)');
    
    hold on;

    % Dibujamos los picos (puntos rojos)
    % T(idx_t) y F(idx_f) sitúan los puntos exactamente sobre los píxeles correctos
    plot(T(idx_t), F(idx_f), 'ro', 'MarkerSize', 4, 'LineWidth', 1.2);

    % 4. Formato y Presentación
    title('Huella Acústica: Landmarks sobre Espectrograma (Optimizado)');
    xlabel('Tiempo (segundos)');
    ylabel('Frecuencia (Hz)');
    
    % Zoom automático a la zona de interés (puedes ajustar el límite)
    % Si fs/2 es muy alto, podrías limitarlo a 8000 o 10000 para que se vea mejor
    ylim([0 max(F)]); 
    
    % Zoom temporal para que los puntos no se amontonen (primeros 2 segundos)
    if max(T) > 2
        xlim([0 2]);
    end
    
    grid on;
    hold off;
    
    fprintf('Captura generada correctamente.\n');
end
