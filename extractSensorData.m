function [t_sec, dataMatrix, varNames] = extractSensorData(filename, channels)
    % filename   : path to data file or MATLAB table
    % channels   : string array or cell array of chars (e.g., ["BNO1GyroX", "BNO1GyroY"])
    
    if istable(filename)
        raw = filename;
    else
        raw = readtable(filename, 'VariableNamingRule', 'preserve');
    end

    colNames = raw.Properties.VariableNames;
    
    % Prioritize Chip_Time_s if numeric (WitMotion standard), then numeric Time (DAQ ms)
    if ismember('Chip_Time_s', colNames) && isnumeric(raw.Chip_Time_s)
        t_sec = double(raw.Chip_Time_s);
    elseif ismember('Time', colNames)
        t_raw = raw.Time;
        if isnumeric(t_raw)
            t_sec = double(t_raw) / 1000.0; % DAQ milliseconds to seconds
        else
            try
                d = duration(string(t_raw));
                t_sec = double(seconds(d - d(1)));
            catch
                t_sec = (0:(height(raw)-1))' * 0.02;
            end
        end
    elseif ismember('Chip_Time', colNames)
        t_raw = raw.Chip_Time;
        try
            d = datetime(string(t_raw));
            t_sec = double(seconds(d - d(1)));
        catch
            t_sec = (0:(height(raw)-1))' * 0.02;
        end
    else
        t_sec = (0:(height(raw)-1))' * 0.02;
    end
    
    % Match target channels that exist in table
    targetVars = string(channels);
    validVars = targetVars(ismember(targetVars, colNames));
    
    if isempty(validVars)
        dataMatrix = [];
        varNames = strings(0, 1);
        return;
    end
    
    dataRaw = table2array(raw(:, validVars));
    
    [t_sec, uniqueIdx] = unique(t_sec, 'stable');
    dataMatrix = dataRaw(uniqueIdx, :);
    varNames = validVars;

end