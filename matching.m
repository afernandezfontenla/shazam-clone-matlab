% ==========================================
% SCRIPT DE MATCHING CON RECORTE AUTOMÁTICO
% ==========================================
clear; clc; close all;

% 1. Cargar Base de Datos
load('shazam_db.mat'); 

% 2. Seleccionar archivo y extraer un fragmento de 10 segundos
[file, path] = uigetfile('*.mp3', 'Selecciona una canción de la base de datos');
if isequal(file,0), return; end

info = audioinfo(fullfile(path, file));
fs = info.SampleRate;

% --- CONFIGURACIÓN DEL FRAGMENTO ---
segundo_inicio = 20; % Empezar en el segundo 20
duracion = 10;       % Durar 10 segundos

startSample = round(segundo_inicio * fs) + 1;
endSample = min(info.TotalSamples, round((segundo_inicio + duracion) * fs));

% Cargamos SOLO el trozo especificado
[y_query, ~] = audioread(fullfile(path, file), [startSample, endSample]);
fprintf('Analizando fragmento de %d segundos (del seg %d al %d)...\n', duracion, segundo_inicio, segundo_inicio + duracion);

%Inicio cronometro
tic;
% 3. Procesamiento con calcular_espectograma de mi compañero
[S, ~, ~] = calcular_espectrograma(y_query, fs);
threshold = mean(S(:)) + 1.5 * std(S(:));
[freqs, times] = find_peaks_local(S, threshold);

% 4. Búsqueda de Coincidencias (VERSION OPTIMIZADA)
fan_out = 3;%Es el número de "picos vecinos" que cada punto busca para crear parejas. Si lo subes a 5, el sistema será más preciso pero un poco más lento; si lo bajas a 2, será más rápido pero menos fiable. 3 es el equilibrio perfecto.
matches = cell(length(freqs) * fan_out, 1); % Pre-asignamos espacio
match_count = 0;

for i = 1:length(freqs) - fan_out
    for j = 1:fan_out
        idx_next = i + j;
        dt = times(idx_next) - times(i);
        
        if dt > 0 && dt < 64
            hash_key = double(uint32(freqs(i)-1)*2^18 + uint32(freqs(idx_next)-1)*2^8 + uint32(dt));
            
            if isKey(database, hash_key)
                hits = database(hash_key); % hits es [ID; TiempoOriginal]
                match_count = match_count + 1;
                % Calculamos todos los offsets de este hash de golpe sin bucle 'k'
                matches{match_count} = [double(hits(1,:))', double(hits(2,:))' - double(times(i))];
            end
        end
    end
end

% Convertimos la lista de celdas en una sola matriz (mucho más rápido)
matches = cell2mat(matches(1:match_count)); 
% if match_count > 0
%     matches = cell2mat(matches_cell(1:match_count)); 
% else
%     matches = [];
% end

% >>> TERMINA EL CRONÓMETRO AQUÍ <<<
tiempo_deteccion = toc; 

% 5. Análisis de Resultados
if isempty(matches)
    disp('X No se encontraron coincidencias.');
else
    unique_ids = unique(matches(:,1));
    best_score = 0; mejor_id = 0; mejor_offset = 0;

    for k = 1:length(unique_ids)
        this_id = unique_ids(k);
        offsets = matches(matches(:,1) == this_id, 2);
        [counts, values] = hist(offsets, unique(offsets));
        [max_c, idx_c] = max(counts);
        if max_c > best_score
            best_score = max_c; mejor_id = this_id; mejor_offset = values(idx_c);
        end
    end

    % 6. Mostrar Resultados Finales
    fprintf('\n========================================\n');
    fprintf('   ¡CANCIÓN IDENTIFICADA!\n');
    fprintf('========================================\n');
    fprintf('NOMBRE: %s\n', nombres_canciones{mejor_id});
    fprintf('COINCIDENCIAS: %d puntos\n', best_score);
    fprintf('TIEMPO DE PROCESAMIENTO: %.4f segundos\n', tiempo_deteccion);
    
    % Cálculo del segundo exacto donde empieza en la original
    % (Pasamos de frames a segundos usando la configuración de la ventana)
    % El paso (hop) entre ventanas en tu función es el 25% de la ventana (75% solapamiento)
    ventana_duracion = 0.04; 
    paso_segundos = ventana_duracion * 0.25; 
    tiempo_estimado = mejor_offset * paso_segundos;
    
    fprintf('INICIO DETECTADO EN: %.2f segundos\n', tiempo_estimado);
    fprintf('========================================\n');
    
    % Histograma para ver el "pico" de confianza
    figure('Name', 'Resultado del Matching');
    histogram(matches(matches(:,1) == mejor_id, 2), 'FaceColor', 'g');
    title(['Alineación Temporal: ', nombres_canciones{mejor_id}]);
    grid on;
end



