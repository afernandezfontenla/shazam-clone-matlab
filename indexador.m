% =========================================================================
% SCRIPT DE INDEXACIÓN: GENERACIÓN DE LA BASE DE DATOS DE HUELLAS (FINGERPRINTS)
% =========================================================================
% Este script automatiza el procesamiento de una biblioteca musical para 
% extraer sus rasgos acústicos únicos (Landmarks) y almacenarlos en una 
% estructura de datos de búsqueda ultra-rápida (Tabla Hash).

clear; clc;
folderPath = fullfile('Songs');  % Ruta del repositorio de audio
songFiles = dir(fullfile(folderPath, '*.mp3'));

if isempty(songFiles), error('No se detectaron archivos .mp3 en la ruta.'); end

% 1. ESTRUCTURAS DE ALMACENAMIENTO
% Usamos un Mapa (containers.Map) por su eficiencia O(1) en acceso aleatorio.
% Clave: Hash de sonido (32 bits) | Valor: [ID_Cancion; Tiempo_Original]
database = containers.Map('KeyType', 'double', 'ValueType', 'any'); 

% Vector de metadatos para mapear el ID numérico con el nombre real del archivo
nombres_canciones = {songFiles.name}; 

fprintf('Iniciando indexación masiva de %d canciones...\n', length(songFiles));

% --- BUCLE DE PROCESAMIENTO POR CANCIÓN ---
for id_cancion = 1:length(songFiles)
    fileName = fullfile(folderPath, songFiles(id_cancion).name);
    [y, fs] = audioread(fileName);
    
    % 2. ANÁLISIS ESPECTRAL (Compañero 1)
    % Se genera el espectrograma optimizado con ventana de 40ms y límite de 5kHz.
    [S, F, T] = calcular_espectrograma(y, fs);
  
    % 3. EXTRACCIÓN DE LANDMARKS (Compañero 2)
    % Calculamos un umbral dinámico basado en la energía de la canción
    umbral = mean(S(:)) + 1.5 * std(S(:)); 
    
    % Aplicamos imregionalmax PERO solo en puntos que superen el umbral
    % Esto elimina el "mar de puntos rojos" en zonas de silencio
    picos_mask = imregionalmax(S) & (S > umbral); 
    
    % Ahora extraemos los índices de los picos que SI son importantes
    [idx_f, idx_t] = find(picos_mask);
    
    % 4. CODIFICACIÓN DE HUELLAS POR PAREJAS (Hashing - Compañero 3)
    % No indexamos picos sueltos, sino relaciones entre picos (Fan-out = 3).
    % Esto aumenta la unicidad de la huella digital exponencialmente.
    fan_out = 3;
    for i = 1:length(idx_t) - fan_out
        for j = 1:fan_out
            idx_next = i + j;
            dt = idx_t(idx_next) - idx_t(i); % Diferencia temporal entre picos
            
            % Restricción de coherencia: los picos deben estar en una ventana cercana
            if dt > 0 && dt < 64
                % GENERACIÓN DEL HASH (Clave de búsqueda de 32 bits):
                % Empaquetado: [Frecuencia_1 (10 bits) | Frecuencia_2 (10 bits) | dt (12 bits)]
                % Se usa aritmética de bits para desplazar valores y evitar colisiones.
                f1 = idx_f(i); 
                f2 = idx_f(idx_next);
                hash_key = double(uint32(f1-1)*2^18 + uint32(f2-1)*2^8 + uint32(dt));
                
                % Metadato asociado: [ID de canción ; Momento en el que ocurre (frames)]
                new_entry = [uint32(id_cancion); uint32(idx_t(i))];
                
                % Almacenamiento en el Mapa (Manejo de colisiones: se añaden nuevas ubicaciones)
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

% 5. PERSISTENCIA DE DATOS
% Se utiliza la versión -v7.3 para soportar archivos de gran tamaño (HDF5)
save('shazam_db.mat', 'database', 'nombres_canciones', '-v7.3');
disp('Base de datos generada y con éxito.');
