% =========================================================================
% SCRIPT DE IDENTIFICACIÓN (MATCHING) - SISTEMA DE HUELLAS ACÚSTICAS
% =========================================================================
% Este script carga un fragmento de audio, le añade ruido impulsivo para 
% pruebas de robustez, genera su huella digital y busca la mejor coincidencia
% temporal en la base de datos pre-indexada.

clear; clc; close all;

% 1. CARGA DE RECURSOS
if ~exist('shazam_db.mat', 'file')
    error('Base de datos no encontrada. Ejecute el indexador primero.');
end
load('shazam_db.mat'); % Carga 'database' (Mapa de Hashes) y 'nombres_canciones'

% 2. SELECCIÓN Y CONFIGURACIÓN DEL FRAGMENTO DE PRUEBA
[file, path] = uigetfile('*.mp3', 'Selecciona audio para identificación');
if isequal(file,0), return; end

info = audioinfo(fullfile(path, file));
fs = info.SampleRate;

% Parámetros de recorte para simular una captura parcial
segundo_inicio = 10; 
duracion = 5; % Duración del fragmento en segundos

startSample = round(segundo_inicio * fs) + 1;
endSample = min(info.TotalSamples, round((segundo_inicio + duracion) * fs));
[y_query, ~] = audioread(fullfile(path, file), [startSample, endSample]);

% Pre-procesamiento: Conversión a monoaural para consistencia matricial
if size(y_query, 2) > 1
    y_query = mean(y_query, 2); 
end

% PRUEBA DE ROBUSTEZ: Inyección de ruido impulsivo (5% de las muestras)
y_query = function_add_noise(y_query); 

% --- INICIO DEL PROCESAMIENTO CRÍTICO ---
tic; 

% 3. GENERACIÓN DE ESPECTROGRAMA Y LANDMARKS (Puntos Clave)
% Se utiliza la configuración optimizada (40ms, 75% overlap, 5000Hz)
[S, F, T] = calcular_espectrograma(y_query, fs);

% Detección de máximos locales mediante morfología matemática (imregionalmax)
picos_mask = imregionalmax(S);
[idx_f, idx_t] = find(picos_mask);

% 4. GENERACIÓN DE HASHES Y BÚSQUEDA EN BASE DE DATOS
% Cada pico se empareja con sus sucesores (Fan-out) para crear huellas robustas
fan_out = 3; 
matches_cell = cell(length(idx_t) * fan_out, 1); % Pre-asignación para eficiencia
match_count = 0;

for i = 1:length(idx_t) - fan_out
    for j = 1:fan_out
        idx_next = i + j;
        dt = idx_t(idx_next) - idx_t(i); % Diferencia temporal entre picos
        
        % Ventana de coherencia temporal (0 < dt < 64)
        if dt > 0 && dt < 64
            % Empaquetado de bits: [F1(10 bits) | F2(10 bits) | dt(12 bits)]
            % Genera una clave única de 32 bits para búsqueda instantánea O(1)
            hash_key = double(uint32(idx_f(i)-1)*2^18 + uint32(idx_f(idx_next)-1)*2^8 + uint32(dt));
            
            % Consulta al diccionario (Mapa de Hashes)
            if isKey(database, hash_key)
                hits = database(hash_key); % Recupera [ID_Cancion; TiempoOriginal]
                match_count = match_count + 1;
                % Vectorización de offsets: Diferencia entre tiempo real y tiempo de consulta
                matches_cell{match_count} = [double(hits(1,:))', double(hits(2,:))' - double(idx_t(i))];
            end
        end
    end
end

% Estadísticas de densidad de la huella digital
total_hashes_analizados = (i * j); 
hashes_por_segundo = total_hashes_analizados / duracion;

% Consolidación de resultados
if match_count > 0
    matches = cell2mat(matches_cell(1:match_count));
else
    matches = [];
end
tiempo_total = toc; % Fin de la medición de rendimiento

% 5. ANÁLISIS ESTADÍSTICO DE COINCIDENCIAS (VOTACIÓN)
if isempty(matches)
    disp('X No se encontraron coincidencias consistentes.');
else
    % Identificación de la canción con mayor coherencia temporal (Moda de Offsets)
    unique_ids = unique(matches(:,1));
    best_score = 0; mejor_id = 0;

    for k = 1:length(unique_ids)
        this_id = unique_ids(k);
        % Filtramos los votos recibidos para esta canción específica
        offsets = matches(matches(:,1) == this_id, 2);
        
        % El histograma revela si los hashes coinciden de forma aleatoria (ruido)
        % o de forma alineada (canción correcta)
        [counts, values] = hist(offsets, unique(offsets));
        [max_c, idx_c] = max(counts);
        
        if max_c > best_score
            best_score = max_c; % El puntaje máximo define la confianza
            mejor_id = this_id;
        end
    end

    % 6. REPORTE DE RESULTADOS
    fprintf('\n========================================\n');
    fprintf('RESULTADO DE IDENTIFICACIÓN EXITOSA\n');
    fprintf('========================================\n');
    fprintf('CANCIÓN: %s\n', nombres_canciones{mejor_id});
    fprintf('DURACIÓN ANALIZADA: %d s\n', duracion);
    fprintf('DENSIDAD DE HUELLA: %.2f hashes/seg\n', hashes_por_segundo);
    fprintf('PUNTAJE (VOTOS): %d\n', best_score);
    fprintf('TIEMPO DE RESPUESTA: %.4f s\n', tiempo_total);
    fprintf('========================================\n');
   
    % Visualización de los picos sobre el espectrograma para el informe
    visualizar_picos_reporte(y_query, fs);
end
