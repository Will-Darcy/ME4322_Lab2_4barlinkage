function importantChannels = screenSensorColumns(filename)
% SCREENSENSORCOLUMNS Inspects an Excel file to find the most active/oscillating columns.
% Inputs:
%   filename : Path to the .xlsx file
% Outputs:
%   report   : Table sorted by highest dynamic deviation (StdDev)

if istable(filename)
    tbl = filename;
    fileLabel = 'Table Input';
else
    fileLabel = char(filename);
    tbl = readtable(filename, 'VariableNamingRule', 'preserve');
end
colNames = tbl.Properties.VariableNames;

% 2. Columns to ignore from dynamic kinematic screening
ignorePatterns = {'time', 'chip_time', 'equipment', 'hall', 'RPM', ...
    'EncoderAngularVelocity'};

results = struct('Column', {}, 'StdDev', {}, 'PeakToPeak_Range', {}, ...
    'Mean', {}, 'Min', {}, 'Max', {}, 'Status', {});

count = 0;
for i = 1:length(colNames)
    cName = colNames{i};
    lowerName = lower(cName);

    % Skip timestamps, IDs, and constants
    if any(contains(lowerName, ignorePatterns))
        continue;
    end

    colData = tbl.(cName);

    % Ensure column is numeric
    if isnumeric(colData)
        % Drop NaNs if any
        cleanData = colData(~isnan(colData));
        if length(cleanData) < 5
            continue;
        end

        count = count + 1;
        stdVal   = std(cleanData);
        minVal   = min(cleanData);
        maxVal   = max(cleanData);
        rangeVal = maxVal - minVal;
        meanVal  = mean(cleanData);

        % Classify activity level based on dynamic oscillation
        if stdVal > 15 || rangeVal > 40
            status = "HIGH ACTIVITY (Primary)";
        elseif stdVal > 2 || rangeVal > 5
            status = "MODERATE";
        else
            status = "LOW / NEAR-ZERO (Negligible)";
        end

        

        results(count).Column           = string(cName);
        results(count).StdDev           = round(stdVal, 2);
        results(count).PeakToPeak_Range = round(rangeVal, 2);
        results(count).Mean             = round(meanVal, 2);
        results(count).Min              = round(minVal, 2);
        results(count).Max              = round(maxVal, 2);
        results(count).Status           = status;
    end
end

% Convert to table and sort by highest standard deviation
report = struct2table(results);
report = sortrows(report, 'StdDev', 'descend');

% Print formatted overview to Command Window
fprintf('\n========================================================================================\n');
fprintf(' DYNAMIC COLUMN SCREENING REPORT: %s\n', fileLabel);
fprintf('========================================================================================\n');
disp(report(:, {'Column', 'StdDev', 'PeakToPeak_Range', 'Mean', 'Status'}));
fprintf('========================================================================================\n\n');

%Extract the active channels list (High and Moderate activity)
activechannels = contains(report.Status, "HIGH", 'IgnoreCase', true) | ...
    contains(report.Status, "Moderate", 'IgnoreCase', true);
%return string array of important fields to track
%issue is all sensors will be included so need to sperate after
importantChannels = report.Column(activechannels);

end

