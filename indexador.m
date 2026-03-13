% =========================================================================
% SCRIPT DE INDEXACIÓN: GENERADOR DE HUELLAS DIGITALES (FINGERPRINTING)
% =========================================================================
% Este script recorre una carpeta de audio, extrae picos de energía de cada
% canción y los guarda en una base de datos mapeada por "Hashes".

% --- 1. Configuración Inicial ---
clear; clc;
folderPath = fullfile('Songs', 'Songs');  % Ruta de la carpeta con los MP3
songFiles = dir(fullfile(folderPath, '*.mp3'));  % Lista de archivos encontrados

if isempty(songFiles)
    error('No se encontraron archivos .mp3.');
end

% Creamos un Mapa (Diccionario) para la base de datos:
% Key: Hash (número único del sonido) | Value: [ID Canción; Tiempo en el que ocurre]
database = containers.Map('KeyType', 'double', 'ValueType', 'any'); 

% Guardamos los nombres de los archivos para recuperarlos luego
nombres_canciones = {songFiles.name}; 

fprintf('Iniciando indexación de %d canciones...\n', length(songFiles));

% --- 2. Bucle Principal ---
for id_cancion = 1:length(songFiles)
    fileName = fullfile(folderPath, songFiles(id_cancion).name);
    [y, fs] = audioread(fileName);
    [S, ~, ~] = calcular_espectrograma(y, fs);

    % Detección de picos: Buscamos los puntos con más energía (Landmarks)
    % El umbral es dinámico: depende de la media y desviación estándar de la canción
    threshold = mean(S(:)) + 1.5 * std(S(:)); 
    [freqs, times] = find_peaks_local(S, threshold);

    % --- 3. Generación de Hashes (Parejas de picos) ---
    % Para que la huella sea única, no guardamos un pico solo, sino la
    % relación entre un pico y sus "vecinos" en el tiempo (Fan-out).
    fan_out = 3;
    for i = 1:length(freqs) - fan_out
        for j = 1:fan_out
            idx_next = i + j; % Indice del pico vecino

            % Calculamos la diferencia de tiempo entre los dos picos
            dt = times(idx_next) - times(i);

             % Ventana de coherencia: Solo emparejamos si están cerca (máx 64 frames)
            if dt > 0 && dt < 64

                % EMPAQUETADO DE BITS (HASHING):
                % Creamos un número de 32 bits que contiene:
                % Frecuencia 1 (10 bits), Frecuencia 2 (10 bits), Tiempo dt (12 bits)
                % Se usa aritmética simple para desplazar los bits:
                hash_key = double(uint32(freqs(i)-1)*2^18 + uint32(freqs(idx_next)-1)*2^8 + uint32(dt));

                % Datos a guardar: [ID de la canción; Tiempo exacto del primer pico]
                new_entry = [uint32(id_cancion); uint32(times(i))];

                % Si el sonido (hash) ya existe en el mapa, añadimos la nueva ubicación
                % Si no existe, creamos la entrada en el mapa
                if isKey(database, hash_key)
                    database(hash_key) = [database(hash_key), new_entry];
                else
                    database(hash_key) = new_entry;
                end
            end
        end
    end
    fprintf('Procesada [%d/%d]: %s\n', id_cancion, length(songFiles), songFiles(id_cancion).name);
end

% Guardamos la base de datos y la lista de nombres en un archivo .mat
save('shazam_db.mat', 'database', 'nombres_canciones', '-v7.3');
disp('Base de datos con NOMBRES guardada con éxito.');








