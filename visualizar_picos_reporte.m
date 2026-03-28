function visualizar_picos_reporte(audio, fs)
    % 1. Configuración idéntica a la función del compañero
    nfft = 1024;
    window = 1024;
    overlap = 512;

    % 2. Calcular espectrograma para la imagen
    [S, F, T] = spectrogram(audio, window, overlap, nfft, fs);
    S_mag = abs(S);
    S_db = 10 * log10(S_mag + eps); % Escala logarítmica para ver mejor

    % 3. Detectar picos 
    picos_mask = imregionalmax(S_mag);
    [idx_f, idx_t] = find(picos_mask);

    % 4. Creación la figura
    figure('Color', 'w', 'Name', 'Captura para el Reporte');
    
    % Dibujar el espectrograma (fondo)
    imagesc(T, F, S_db);
    axis xy; % Orientación correcta de frecuencias
    colormap('jet');
    colorbar;
    ylabel(colorbar, 'Intensidad (dB)');
    
    hold on;

    % Dibujar los picos (puntos rojos)
    % Usamos los vectores T y F para posicionar los puntos correctamente
    plot(T(idx_t), F(idx_f), 'ro', 'MarkerSize', 3, 'LineWidth', 1);

    % 5. Formato y Limpieza
    title('Análisis de Landmarks: Espectrograma con Picos de Energía');
    xlabel('Tiempo (segundos)');
    ylabel('Frecuencia (Hz)');
    
    % Hacemos un zoom a la zona de interés (0-5000Hz) para que se vea profesional
    ylim([0 5000]); 
    
    % Opcional: Zoom temporal si el audio es muy largo (ej: primeros 3 seg)
    if max(T) > 3
        xlim([0 3]);
    end
    
    grid on;
    hold off;
    
    fprintf('Gráfico generado.\n');
end
