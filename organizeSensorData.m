% organizeSensorData.m
% 
% Separates multi-sensor IMU data (WitMotion sensors) into individual
% sensor datasets and exports them to separate Excel (.xlsx) files.
% Supports raw data_0.csv, data_0.txt, data.mat, and Excel files.
% Automatically detects 19-, 20-, 25-, and 26-column WitMotion structures.
%
% Sensor mapping:
%   Sensor 1: WTInput link    (MAC: ff:bd:0d:cb:d7:a7, Equipment ID: 1)
%   Sensor 2: WTFollowerLink  (MAC: f9:a2:89:42:44:2c, Equipment ID: 2)
%
% Syntax:
%   [fileSensor1, fileSensor2] = organizeSensorData
%   [fileSensor1, fileSensor2] = organizeSensorData(inputFile)
%   [fileSensor1, fileSensor2, sensor1_data, sensor2_data] = organizeSensorData(inputFile, outputDir)
%
% Inputs:
%   inputFile (optional) - Path to 'data_0.csv', 'data_0.txt', 'data.mat',
%                          workbook '.xlsx', or a matrix from readMatData.
%   outputDir (optional) - Directory to save generated Excel files.
%                          Defaults to pwd.
%
% Outputs:
%   fileSensor1  - Path to generated 'Sensor1_WTInputLink.xlsx'
%   fileSensor2  - Path to generated 'Sensor2_WTFollowerLink.xlsx'
%   sensor1_data - MATLAB table containing data for Sensor 1 (WTInput link)
%   sensor2_data - MATLAB table containing data for Sensor 2 (WTFollowerLink)

function [fileSensor1, fileSensor2, sensor1_data, sensor2_data] = organizeSensorData(inputFile, outputDir)

    % 1. Determine input file if not provided
    if nargin < 1 || isempty(inputFile)
        candidateFiles = { ...
            'data_0.csv', ...
            'data_0.txt', ...
            'data.mat', ...
            fullfile('Example Data', 'Tristan Ross', '18-33-20-271', 'data_0.csv'), ...
            fullfile('Example Data', 'Tristan Ross', '18-33-20-271', 'data_0.txt'), ...
            fullfile('Example Data', 'Tristan Ross', '18-33-20-271', 'Matlab', 'data.mat'), ...
            fullfile('Example Data', '20RPM', 'data_0.csv'), ...
            fullfile('Example Data', '20RPM', 'Matlab', 'data.mat'), ...
            'Separated_Sensor_Data.xlsx' ...
        };
        found = false;
        for c = 1:length(candidateFiles)
            if exist(candidateFiles{c}, 'file')
                inputFile = candidateFiles{c};
                found = true;
                break;
            end
        end
        if ~found
            error('No input file specified and could not find default WitMotion data file.');
        end
    end

    % Column headers definition for 19-col matrix (no shift/speed)
    matColNames19 = { ...
        'Equipment', 'Chip_Time_s', ...
        'Acceleration_X_g', 'Acceleration_Y_g', 'Acceleration_Z_g', ...
        'Angular_Velocity_X_deg_s', 'Angular_Velocity_Y_deg_s', 'Angular_Velocity_Z_deg_s', ...
        'Angle_X_deg', 'Angle_Y_deg', 'Angle_Z_deg', ...
        'Magnetic_Field_X_uT', 'Magnetic_Field_Y_uT', 'Magnetic_Field_Z_uT', ...
        'Temperature_degC', ...
        'Quaternion_0', 'Quaternion_1', 'Quaternion_2', 'Quaternion_3' ...
    };

    % Column headers definition for 25-col matrix (includes 6 shift/speed cols)
    matColNames25 = { ...
        'Equipment', 'Chip_Time_s', ...
        'Acceleration_X_g', 'Acceleration_Y_g', 'Acceleration_Z_g', ...
        'Angular_Velocity_X_deg_s', 'Angular_Velocity_Y_deg_s', 'Angular_Velocity_Z_deg_s', ...
        'ShiftX_mm', 'ShiftY_mm', 'ShiftZ_mm', ...
        'SpeedX_mm_s', 'SpeedY_mm_s', 'SpeedZ_mm_s', ...
        'Angle_X_deg', 'Angle_Y_deg', 'Angle_Z_deg', ...
        'Magnetic_Field_X_uT', 'Magnetic_Field_Y_uT', 'Magnetic_Field_Z_uT', ...
        'Temperature_degC', ...
        'Quaternion_0', 'Quaternion_1', 'Quaternion_2', 'Quaternion_3' ...
    };

    % Column headers definition for 20-col CSV/table (no shift/speed)
    csvColNames20 = { ...
        'Time', 'Device_Name', 'Chip_Time', ...
        'Acceleration_X_g', 'Acceleration_Y_g', 'Acceleration_Z_g', ...
        'Angular_Velocity_X_deg_s', 'Angular_Velocity_Y_deg_s', 'Angular_Velocity_Z_deg_s', ...
        'Angle_X_deg', 'Angle_Y_deg', 'Angle_Z_deg', ...
        'Magnetic_Field_X_uT', 'Magnetic_Field_Y_uT', 'Magnetic_Field_Z_uT', ...
        'Temperature_degC', ...
        'Quaternion_0', 'Quaternion_1', 'Quaternion_2', 'Quaternion_3' ...
    };

    % Column headers definition for 26-col CSV/table (with shift/speed)
    csvColNames26 = { ...
        'Time', 'Device_Name', 'Chip_Time', ...
        'Acceleration_X_g', 'Acceleration_Y_g', 'Acceleration_Z_g', ...
        'Angular_Velocity_X_deg_s', 'Angular_Velocity_Y_deg_s', 'Angular_Velocity_Z_deg_s', ...
        'ShiftX_mm', 'ShiftY_mm', 'ShiftZ_mm', ...
        'SpeedX_mm_s', 'SpeedY_mm_s', 'SpeedZ_mm_s', ...
        'Angle_X_deg', 'Angle_Y_deg', 'Angle_Z_deg', ...
        'Magnetic_Field_X_uT', 'Magnetic_Field_Y_uT', 'Magnetic_Field_Z_uT', ...
        'Temperature_degC', ...
        'Quaternion_0', 'Quaternion_1', 'Quaternion_2', 'Quaternion_3' ...
    };

    % 2. Set output directory
    if nargin < 2 || isempty(outputDir)
        outputDir = pwd;
    end
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % 3. Load data based on input type
    if isnumeric(inputFile)
        rawMatrix = inputFile;
        isMat = true;
    elseif ischar(inputFile) || isstring(inputFile)
        inputFile = char(inputFile);
        if ~exist(inputFile, 'file')
            error('Input file not found: %s', inputFile);
        end
        [~, ~, ext] = fileparts(inputFile);
        fprintf('Processing WitMotion file: %s\n', inputFile);

        if strcmpi(ext, '.mat')
            isMat = true;
            matData = load(inputFile);
            vars = fieldnames(matData);
            rawMatrix = [];
            for v = 1:length(vars)
                val = matData.(vars{v});
                if isnumeric(val) && size(val, 2) >= 19
                    rawMatrix = [rawMatrix; val]; %#ok<AGROW>
                end
            end
            if isempty(rawMatrix) && exist('readMatData', 'file')
                rawMatrix = readMatData(inputFile);
            end

        elseif strcmpi(ext, '.xlsx') || strcmpi(ext, '.xls')
            isMat = false;
            % Check if file is already a multi-sheet separated workbook
            try
                sheetNames = sheetnames(inputFile);
            catch
                [~, sheetNames] = xlsfinfo(inputFile);
            end
            if ismember('WTInput_Link', sheetNames) && ismember('WTFollower_Link', sheetNames)
                fprintf('  Detected multi-sheet separated workbook. Loading sheets directly...\n');
                sensor1_data = readtable(inputFile, 'Sheet', 'WTInput_Link', 'VariableNamingRule', 'preserve');
                sensor2_data = readtable(inputFile, 'Sheet', 'WTFollower_Link', 'VariableNamingRule', 'preserve');
                fileSensor1 = fullfile(outputDir, 'Sensor1_WTInputLink.xlsx');
                fileSensor2 = fullfile(outputDir, 'Sensor2_WTFollowerLink.xlsx');
                writetable(sensor1_data, fileSensor1);
                writetable(sensor2_data, fileSensor2);
                fprintf('  Successfully ready: %s and %s\n', fileSensor1, fileSensor2);
                return;
            end
            rawTable = readtable(inputFile, 'VariableNamingRule', 'preserve');

        elseif strcmpi(ext, '.csv') || strcmpi(ext, '.txt')
            isMat = false;
            % Try reading with ReadVariableNames false first to preserve row 1 if data
            rawTable = readtable(inputFile, 'ReadVariableNames', false);
            % Check if first row is actually text headers
            firstRowVals = table2cell(rawTable(1, :));
            hasTextHeader = any(cellfun(@(x) (ischar(x) || isstring(x)) && ...
                            any(contains(lower(string(x)), {'acc', 'gyro', 'time', 'angle', 'device'})), firstRowVals));
            if hasTextHeader
                rawTable = readtable(inputFile, 'VariableNamingRule', 'preserve');
            end
        else
            error('Unsupported file format: %s. Supported formats: .csv, .txt, .mat, .xlsx', ext);
        end
    else
        error('Invalid input argument. Must be a filename string or numeric data matrix.');
    end

    % 4. Process and separate data
    if isMat
        nCols = size(rawMatrix, 2);
        if nCols >= 25
            colNames = matColNames25;
            if nCols > 25
                extraCols = arrayfun(@(k) sprintf('Extra_Col_%d', k), 26:nCols, 'UniformOutput', false);
                colNames = [colNames, extraCols];
            end
        else
            colNames = matColNames19;
            if nCols > 19
                extraCols = arrayfun(@(k) sprintf('Extra_Col_%d', k), 20:nCols, 'UniformOutput', false);
                colNames = [colNames, extraCols];
            end
        end

        idx1 = (rawMatrix(:, 1) == 1);
        idx2 = (rawMatrix(:, 1) == 2);

        % If equipment ID wasn't 1 and 2, fallback to dividing in half
        if ~any(idx1) && ~any(idx2)
            half = floor(size(rawMatrix, 1) / 2);
            idx1 = false(size(rawMatrix, 1), 1); idx1(1:half) = true;
            idx2 = ~idx1;
        end

        sensor1_data = array2table(rawMatrix(idx1, :), 'VariableNames', colNames);
        sensor2_data = array2table(rawMatrix(idx2, :), 'VariableNames', colNames);

    else
        % Process table from CSV / TXT / XLSX
        nCols = width(rawTable);
        curNames = rawTable.Properties.VariableNames;

        % If column names are generic Var1, Var2... assign standard names based on width
        if startsWith(curNames{1}, 'Var')
            if nCols >= 26
                assigned = csvColNames26;
                if nCols > 26
                    assigned = [assigned, arrayfun(@(k) sprintf('Extra_Col_%d', k), 27:nCols, 'UniformOutput', false)];
                end
                rawTable.Properties.VariableNames = assigned(1:nCols);
            else
                assigned = csvColNames20;
                if nCols > 20
                    assigned = [assigned, arrayfun(@(k) sprintf('Extra_Col_%d', k), 21:nCols, 'UniformOutput', false)];
                end
                rawTable.Properties.VariableNames = assigned(1:nCols);
            end
        end

        % Identify device column (column 2 or named Device / Device_Name)
        colNames = rawTable.Properties.VariableNames;
        devColIdx = find(contains(lower(colNames), 'device'), 1);
        if isempty(devColIdx)
            devColIdx = min(2, width(rawTable));
        end

        devCol = rawTable{:, devColIdx};
        devColStr = strtrim(string(devCol));

        % Sensor 1 MAC: ff:bd:0d:cb:d7:a7, Sensor 2 MAC: f9:a2:89:42:44:2c
        idx1 = contains(devColStr, 'ff:bd:0d:cb:d7:a7', 'IgnoreCase', true);
        idx2 = contains(devColStr, 'f9:a2:89:42:44:2c', 'IgnoreCase', true);

        % Fallback by unique devices
        if ~any(idx1) && ~any(idx2)
            uDevs = unique(devColStr);
            if length(uDevs) >= 2
                idx1 = (devColStr == uDevs(1));
                idx2 = (devColStr == uDevs(2));
            else
                % Single device present
                idx1 = true(height(rawTable), 1);
                idx2 = false(height(rawTable), 1);
            end
        end

        sensor1_data = rawTable(idx1, :);
        sensor2_data = rawTable(idx2, :);

        % Ensure Chip_Time_s numeric seconds vector exists for both sensors
        sensor1_data = ensureChipTimeSeconds(sensor1_data);
        if any(idx2)
            sensor2_data = ensureChipTimeSeconds(sensor2_data);
        end
    end

    % 5. Print summary
    fprintf('  Found %d rows for Sensor 1 (WTInput link, ff:bd:0d:cb:d7:a7)\n', height(sensor1_data));
    fprintf('  Found %d rows for Sensor 2 (WTFollowerLink, f9:a2:89:42:44:2c)\n', height(sensor2_data));

    % 6. Write separated files
    fileSensor1  = fullfile(outputDir, 'Sensor1_WTInputLink.xlsx');
    fileSensor2  = fullfile(outputDir, 'Sensor2_WTFollowerLink.xlsx');
    fileCombined = fullfile(outputDir, 'Separated_Sensor_Data.xlsx');

    fprintf('Writing separated Excel files...\n');
    writetable(sensor1_data, fileSensor1);
    fprintf('  Created: %s\n', fileSensor1);

    if height(sensor2_data) > 0
        writetable(sensor2_data, fileSensor2);
        fprintf('  Created: %s\n', fileSensor2);
    end

    try
        writetable(sensor1_data, fileCombined, 'Sheet', 'WTInput_Link');
        if height(sensor2_data) > 0
            writetable(sensor2_data, fileCombined, 'Sheet', 'WTFollower_Link');
        end
        fprintf('  Created: %s (Multi-sheet workbook)\n', fileCombined);
    catch ME
        fprintf('  Note: Multi-sheet write skipped (%s)\n', ME.message);
    end

    fprintf('Done! Successfully organized sensor data.\n');

end

% Helper function to ensure Chip_Time_s column exists and is numeric elapsed seconds
function tbl = ensureChipTimeSeconds(tbl)
    varNames = tbl.Properties.VariableNames;
    if ismember('Chip_Time_s', varNames) && isnumeric(tbl.Chip_Time_s)
        return;
    end

    % Find time column
    timeCol = '';
    if ismember('Time', varNames)
        timeCol = 'Time';
    elseif ismember('Chip_Time', varNames)
        timeCol = 'Chip_Time';
    elseif ismember('Var1', varNames)
        timeCol = 'Var1';
    end

    if ~isempty(timeCol)
        t_raw = tbl.(timeCol);
        try
            if isduration(t_raw)
                t_sec = seconds(t_raw - t_raw(1));
            elseif isdatetime(t_raw)
                t_sec = seconds(t_raw - t_raw(1));
            else
                t_str = string(t_raw);
                d = duration(t_str);
                t_sec = seconds(d - d(1));
            end
            tbl.Chip_Time_s = double(t_sec);
        catch
            % Fallback: row index with assumed 50Hz sample rate (0.02s dt)
            tbl.Chip_Time_s = (0:(height(tbl)-1))' * 0.02;
        end
    else
        tbl.Chip_Time_s = (0:(height(tbl)-1))' * 0.02;
    end
end
