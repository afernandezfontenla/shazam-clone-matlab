% =========================================================================
% SCRIPT PRINCIPAL (MAIN) - CONTROLADOR DEL SISTEMA
% =========================================================================

db_file = 'shazam_db.mat';

% Verificación de existencia de la Base de Datos
if ~exist(db_file, 'file')

    % Ejecución del script de indexación
    run('indexador.m');
    
end

% Ejecución del script de matching
run('matching.m');