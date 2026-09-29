function [RPM1, RPM2, RPM3] = calculateLinkagePeriod(s1_tbl, s2_tbl, s3_tbl, minStartTimeSec)
% CALCULATELINKAGEPERIOD Calculates the operating period and RPM for:
%   Sensor 1 (WitMotion Input Crank)
%   Sensor 2 (WitMotion Follower Rocker)
%   Sensor 3 (Wired DAQ Sensors: BNO1 & BNO2)
%
% Inputs:
%   s1_tbl          : Path to Sensor 1 file or MATLAB table
%   s2_tbl          : Path to Sensor 2 file or MATLAB table
%   s3_tbl          : Path to DAQ sensor file or MATLAB table
%   minStartTimeSec : ignore data before this time (default = 0)
%
% Outputs:
%   RPM1   : Operating RPM calculated from Sensor 1
%   RPM2   : Operating RPM calculated from Sensor 2
%   RPM3   : Operating RPM calculated from Sensor 3 (DAQ)

    %% 1. Load Data if strings/chars provided
    if ischar(s1_tbl) || isstring(s1_tbl)
        s1_tbl = readtable(s1_tbl, 'VariableNamingRule', 'preserve');
    end
    if ischar(s2_tbl) || isstring(s2_tbl)
        s2_tbl = readtable(s2_tbl, 'VariableNamingRule', 'preserve');
    end
    if ischar(s3_tbl) || isstring(s3_tbl)
        s3_tbl = readtable(s3_tbl, 'VariableNamingRule', 'preserve');
    end
        
    if nargin < 4 || isempty(minStartTimeSec)
            minStartTimeSec = 0;
    end

    % Extract time vectors
    t1_raw = extractTimeVector(s1_tbl);
    t2_raw = extractTimeVector(s2_tbl);

    if ismember('Time', s3_tbl.Properties.VariableNames) && isnumeric(s3_tbl.Time)
        t3_raw = double(s3_tbl.Time) / 1000.0; % Convert DAQ ms to seconds
    else
        t3_raw = extractTimeVector(s3_tbl);
    end

    %% 2. Sensor 1 (Input Link): Compare Angle_Y vs. Angle_Z and Gyro
    rpm1_candidates = [];
    AY1 = []; AZ1 = [];
    rpm1_Y = NaN; freq1_Y = NaN; T1_Y = NaN;
    rpm1_Z = NaN; freq1_Z = NaN; T1_Z = NaN;

    if ismember('Angle_Y_deg', s1_tbl.Properties.VariableNames)
        AY1 = double(s1_tbl.Angle_Y_deg);
        [~, locs1_Y] = safeFindPeaks(AY1, t1_raw, 0.8, 10, minStartTimeSec);
        if length(locs1_Y) >= 2
            T1_Y = mean(diff(locs1_Y));
            rpm1_Y = 60.0 / T1_Y;
            rpm1_candidates = [rpm1_candidates, rpm1_Y];
            freq1_Y = 1.0 / T1_Y;
        end
    end

    if ismember('Angle_Z_deg', s1_tbl.Properties.VariableNames)
        AZ1 = double(s1_tbl.Angle_Z_deg);
        [~, locs1_Z] = safeFindPeaks(AZ1, t1_raw, 0.8, 10, minStartTimeSec);
        if length(locs1_Z) >= 2
            T1_Z = mean(diff(locs1_Z));
            rpm1_Z = 60.0 / T1_Z;
            rpm1_candidates = [rpm1_candidates, rpm1_Z];
            freq1_Z = 1.0 / T1_Z;
        end
    end

    % Physical fallback for crank: mean angular velocity (deg/s) / 6.0
    if ismember('Angular_Velocity_Z_deg_s', s1_tbl.Properties.VariableNames)
        mean_wz = abs(mean(double(s1_tbl.Angular_Velocity_Z_deg_s), 'omitnan'));
        if mean_wz > 10
            rpm1_gyro = mean_wz / 6.0;
            if isempty(rpm1_candidates)
                rpm1_candidates = [rpm1_candidates, rpm1_gyro];
            end
        end
    end

    if isempty(rpm1_candidates)
        RPM1 = 20.0; % default fallback
        warning('Sensor 1: Could not detect periodic peaks. Defaulting RPM1 to 20.0.');
    else
        RPM1 = mean(rpm1_candidates);
    end

    fprintf('================ SENSOR 1: INPUT LINK ================\n');
    if ~isnan(rpm1_Y)
        fprintf('  Angle Y : Freq = %.4f Hz | T = %.3f s | RPM = %.2f\n', freq1_Y, T1_Y, rpm1_Y);
    end
    if ~isnan(rpm1_Z)
        fprintf('  Angle Z : Freq = %.4f Hz | T = %.3f s | RPM = %.2f\n', freq1_Z, T1_Z, rpm1_Z);
    end
    fprintf('  -> Mean Operating Speed: %.2f RPM\n', RPM1);

    %% 3. Sensor 2 (Follower Link): Angle_Y vs. Angular Velocity
    rpm2_candidates = [];
    rpm2_Y = NaN; freq2_Y = NaN; T2_Y = NaN;

    if ismember('Angle_Y_deg', s2_tbl.Properties.VariableNames)
        AY2 = double(s2_tbl.Angle_Y_deg);
        [~, locs2_Y] = safeFindPeaks(AY2, t2_raw, 0.8, 10, minStartTimeSec);
        if length(locs2_Y) >= 2
            T2_Y = mean(diff(locs2_Y));
            rpm2_Y = 60.0 / T2_Y;
            rpm2_candidates = [rpm2_candidates, rpm2_Y];
            freq2_Y = 1.0 / T2_Y;
        end
    end

    % Check Gyro Y (primary follower rocking axis)
    if ismember('Angular_Velocity_Y_deg_s', s2_tbl.Properties.VariableNames)
        w2_Y = double(s2_tbl.Angular_Velocity_Y_deg_s);
        [~, locs2_wY] = safeFindPeaks(abs(w2_Y), t2_raw, 0.4, 10, minStartTimeSec);
        if length(locs2_wY) >= 4
            T2_wY = mean(diff(locs2_wY)) * 2.0;
            rpm2_wY = 60.0 / T2_wY;
            if isnan(rpm2_Y)
                rpm2_candidates = [rpm2_candidates, rpm2_wY];
            end
        end
    end

    if isempty(rpm2_candidates)
        RPM2 = RPM1; % fallback to Sensor 1 if S2 had poor peaks
    else
        RPM2 = mean(rpm2_candidates);
    end

    fprintf('\n=============== SENSOR 2: FOLLOWER LINK ==============\n');
    if ~isnan(rpm2_Y)
        fprintf('  Angle Y : Freq = %.4f Hz | T = %.3f s | RPM = %.2f\n', freq2_Y, T2_Y, rpm2_Y);
    end
    fprintf('  -> Mean Operating Speed: %.2f RPM\n', RPM2);

    %% 4. Sensor 3 (Combined DAQ Test): BNO1 vs. BNO2 Angles
    rpm3_candidates = [];
    rpm3_1 = NaN; freq3_1 = NaN; T3_1 = NaN;
    rpm3_2 = NaN; freq3_2 = NaN; T3_2 = NaN;

    if ismember('BNO1AngleZ', s3_tbl.Properties.VariableNames)
        BNO1_AZ = double(s3_tbl.BNO1AngleZ);
        [~, locs3_1] = safeFindPeaks(BNO1_AZ, t3_raw, 0.8, 8, minStartTimeSec);
        if length(locs3_1) >= 2
            T3_1 = mean(diff(locs3_1));
            rpm3_1 = 60.0 / T3_1;
            rpm3_candidates = [rpm3_candidates, rpm3_1];
            freq3_1 = 1.0 / T3_1;
        end
    end

    if ismember('BNO2AngleZ', s3_tbl.Properties.VariableNames)
        BNO2_AZ = double(s3_tbl.BNO2AngleZ);
        [~, locs3_2] = safeFindPeaks(BNO2_AZ, t3_raw, 0.8, 8, minStartTimeSec);
        if length(locs3_2) >= 2
            T3_2 = mean(diff(locs3_2));
            rpm3_2 = 60.0 / T3_2;
            rpm3_candidates = [rpm3_candidates, rpm3_2];
            freq3_2 = 1.0 / T3_2;
        end
    end

    if isempty(rpm3_candidates)
        RPM3 = RPM1;
    else
        RPM3 = mean(rpm3_candidates);
    end

    fprintf('\n=============== SENSOR 3: 3-SENSOR DAQ ===============\n');
    if ~isnan(rpm3_1)
        fprintf('  BNO1 Angle Z : Freq = %.4f Hz | T = %.3f s | RPM = %.2f\n', freq3_1, T3_1, rpm3_1);
    end
    if ~isnan(rpm3_2)
        fprintf('  BNO2 Angle Z : Freq = %.4f Hz | T = %.3f s | RPM = %.2f\n', freq3_2, T3_2, rpm3_2);
    end
    fprintf('  -> Mean Operating Speed: %.2f RPM\n', RPM3);
    fprintf('======================================================\n\n');

end

% Helper function to extract time vector in seconds from table
function t = extractTimeVector(tbl)
    varNames = tbl.Properties.VariableNames;
    if ismember('Chip_Time_s', varNames) && isnumeric(tbl.Chip_Time_s)
        t = double(tbl.Chip_Time_s);
    elseif ismember('Time', varNames)
        t_raw = tbl.Time;
        if isnumeric(t_raw)
            t = double(t_raw);
        else
            try
                d = duration(string(t_raw));
                t = double(seconds(d - d(1)));
            catch
                t = (0:(height(tbl)-1))' * 0.02;
            end
        end
    elseif ismember('Chip_Time', varNames)
        t_raw = tbl.Chip_Time;
        try
            d = datetime(string(t_raw));
            t = double(seconds(d - d(1)));
        catch
            t = (0:(height(tbl)-1))' * 0.02;
        end
    else
        t = (0:(height(tbl)-1))' * 0.02;
    end
end

% Safe peak detection helper guaranteeing finite and strictly increasing time
function [pks, locs] = safeFindPeaks(y, t, minDist, minProm, minStartTimeSec)
    valid = isfinite(y) & isfinite(t) & (t >= minStartTimeSec);
    
    t_v = t(valid);
    y_v = y(valid);

    if length(t_v) < 3
        pks = []; 
        locs = []; 
        return;
    end
    [t_u, uIdx] = unique(t_v);
    y_u = y_v(uIdx);
   
    if length(t_u) < 3
        pks = []; 
        locs = []; 
        return;
    end
    try
        [pks, locs] = findpeaks(y_u, t_u, 'MinPeakDistance', minDist, 'MinPeakProminence', minProm);
    catch
        pks = []; 
        locs = [];
    end
end
