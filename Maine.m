%% MAINE.M: AUTOMATED PMKS+ KINEMATICS VS. MULTI-SENSOR EXPERIMENTAL DATA COMPARISON
%
% This script automates:
% 1. Universal input loading: accepts raw data_0 (.csv, .txt, .mat, or .xlsx)
%    and automatically organizes WitMotion data into separate sensor files.
% 2. Dynamic column screening to detect active sensor channels.
% 3. Sensor data extraction for Input Crank, Follower Link, and DAQ (BNO1, BNO2, MPU).
% 4. Automatic operating RPM & period detection via peak detection.
% 5. Adaptive PMKS simulation loading: automatically detects whether 1, 2, or 3
%    different PMKS simulation files are required based on RPM grouping.
% 6. Graceful workflow: if PMKS files are not yet ready, prints the exact
%    specifications needed to run the simulation in PMKS+ and exits cleanly.
% 7. Automated steady-state detection and phase alignment with positive acceleration.
% 8. Looping/duplicating 1-rev PMKS kinematics over the full experimental duration.
% 9. Follower Link (WT2) multi-axis evaluation (Axis Y vs. Axis X and Z).
% 10. Kinematic accuracy calculations: RMSE (deg/s, RPM, and deg), MAE, and correlation R.
% 11. Overlaid comparison figures and summary reports for all sensors.

clearvars;
close all;
clc;

fprintf('========================================================================================\n');
fprintf('  STARTING PMKS+ VS. EXPERIMENTAL KINEMATIC ANALYSIS & RMSE CALCULATIONS\n');
fprintf('========================================================================================\n\n');

%% 1. Universal Data Input & Sensor Organization

fprintf('========================================================================================\n');

promptStr = input('---Enter WitMotion data file (data_0.csv / data.mat / .xlsx)---: ', 's');


wirelessfile = promptStr;
fprintf('========================================================================================\n\n');

if isempty(wirelessfile) || ~exist(wirelessfile, 'file')
    error('The specified wireless data file was not found: %s', wirelessfile);
end
fprintf('Verified input wireless file: %s\n', wirelessfile);

% Organize WitMotion Sensor Data automatically
fprintf('\n--- Organizing WitMotion Sensor Data (Sensor 1: Input Crank, Sensor 2: Follower) ---\n');
[file1, file2] = organizeSensorData(wirelessfile);


fprintf('\n========================================================================================\n');

promptStrDAQ = input('---Enter DAQ 4-Bar test file (.xlsx)---: ', 's');


Fourbartest = promptStrDAQ;
fprintf('========================================================================================\n\n');

if isempty(Fourbartest) || ~exist(Fourbartest, 'file')
    error('The specified DAQ data file was not found: %s', Fourbartest);
end
fprintf('Verified DAQ input file: %s\n', Fourbartest);

file3 = Fourbartest;

% Information about Data Steady State
fprintf('========================================================================================\n\n');

ministart = input('--- After perliminary analysis please enter a time (sec) where data is steady state---: ');

% Validate the requested steady-state start time before continuing
if ~isscalar(ministart) || ~isfinite(ministart) || ministart < 0
    error('Steady-state start time must be a finite, nonnegative scalar.');
end

fprintf('Steady-state analysis will begin at %.3f s.\n', ministart);

%% 2. Dynamic Column Screening & Extraction
fprintf('\n--- 2. Screening and Extracting Experimental Sensor Data ---\n');

% Screen columns to detect active sensor channels
rep1 = screenSensorColumns(file1);
rep2 = screenSensorColumns(file2);
rep3 = screenSensorColumns(file3);

% Rep3 has multiple sensors: separate BNO1, BNO2, and MPU channels
sensorsBNO1 = rep3(contains(rep3, "BNO1"));
sensorsBNO2 = rep3(contains(rep3, "BNO2"));
sensorsMPU  = rep3(contains(rep3, "MPU"));

% Extract channels
[S1.time, S1.data, S1.names]         = extractSensorData(file1, rep1);
[S2.time, S2.data, S2.names]         = extractSensorData(file2, rep2);
[BNO1.time, BNO1.data, BNO1.names]   = extractSensorData(file3, sensorsBNO1);
[BNO2.time, BNO2.data, BNO2.names]   = extractSensorData(file3, sensorsBNO2);
[MPU.time,  MPU.data,  MPU.names]    = extractSensorData(file3, sensorsMPU);

% Load raw tables for multi-axis access
s1_raw = readtable(file1, 'VariableNamingRule', 'preserve');
s2_raw = readtable(file2, 'VariableNamingRule', 'preserve');
s3_raw = readtable(file3, 'VariableNamingRule', 'preserve');

fprintf('  Extracted Sensor 1 (Input Link): %d samples\n', length(S1.time));
fprintf('  Extracted Sensor 2 (Follower Link): %d samples\n', length(S2.time));
fprintf('  Extracted DAQ Sensors (BNO1, BNO2, MPU): %d samples\n', length(BNO1.time));


%% 3. Operating RPM Calculation & PMKS Grouping
fprintf('\n--- 3. Operating RPM Calculation & PMKS File Requirement Analysis ---\n');

[RPM1, RPM2, RPM3] = calculateLinkagePeriod(file1, file2, file3, ministart);

% Operating speed grouping tolerance (0.75 RPM or ~4% tolerance)
rpmTol = 0.75;
match_1_2 = abs(RPM1 - RPM2) <= rpmTol;
match_1_3 = abs(RPM1 - RPM3) <= rpmTol;
match_2_3 = abs(RPM2 - RPM3) <= rpmTol;

if match_1_2 && match_2_3
    % Case 1: All sensors share the same operating speed
    PMKSfilenums = 1;
    rpm_common = mean([RPM1, RPM2, RPM3]);
    target_rpm_list = rpm_common;
    fprintf('========================================================================================\n');
    fprintf('  PMKS REQUIREMENT: 1 PMKS SIMULATION FILE NEEDED\n');
    fprintf('  All sensor tests operated at a uniform speed: ~%.2f RPM\n', rpm_common);
    fprintf('  -> Single PMKS simulation covers: Sensor 1 (Crank), Sensor 2 (Follower), and DAQ\n');
    fprintf('========================================================================================\n\n');

elseif match_1_2
    % Case 2A: WitMotion sensors match at one speed, DAQ at another (Standard)
    PMKSfilenums = 2;
    rpm_wt  = mean([RPM1, RPM2]);
    rpm_daq = RPM3;
    target_rpm_list = [rpm_wt, rpm_daq];
    fprintf('========================================================================================\n');
    fprintf('  PMKS REQUIREMENT: 2 PMKS SIMULATION FILES NEEDED\n');
    fprintf('  Two distinct operating speeds detected:\n');
    fprintf('    1. WitMotion Sensors (Input Crank & Follower Link): ~%.2f RPM\n', rpm_wt);
    fprintf('    2. DAQ Sensors (BNO1, BNO2, MPU)                 : ~%.2f RPM\n', rpm_daq);
    fprintf('========================================================================================\n\n');

elseif match_1_3
    % Case 2B: Sensor 1 and DAQ match, Sensor 2 differs
    PMKSfilenums = 2;
    rpm_match = mean([RPM1, RPM3]);
    rpm_other = RPM2;
    target_rpm_list = [rpm_match, rpm_other];
    fprintf('========================================================================================\n');
    fprintf('  PMKS REQUIREMENT: 2 PMKS SIMULATION FILES NEEDED\n');
    fprintf('  Two distinct operating speeds detected:\n');
    fprintf('    1. Sensor 1 & DAQ Sensors  : ~%.2f RPM\n', rpm_match);
    fprintf('    2. Sensor 2 (Follower Link): ~%.2f RPM\n', rpm_other);
    fprintf('========================================================================================\n\n');

elseif match_2_3
    % Case 2C: Sensor 2 and DAQ match, Sensor 1 differs
    PMKSfilenums = 2;
    rpm_match = mean([RPM2, RPM3]);
    rpm_other = RPM1;
    target_rpm_list = [rpm_match, rpm_other];
    fprintf('========================================================================================\n');
    fprintf('  PMKS REQUIREMENT: 2 PMKS SIMULATION FILES NEEDED\n');
    fprintf('  Two distinct operating speeds detected:\n');
    fprintf('    1. Sensor 2 & DAQ Sensors  : ~%.2f RPM\n', rpm_match);
    fprintf('    2. Sensor 1 (Input Crank)  : ~%.2f RPM\n', rpm_other);
    fprintf('========================================================================================\n\n');

else
    % Case 3: All 3 sensors have different operating speeds
    PMKSfilenums = 3;
    target_rpm_list = [RPM1, RPM2, RPM3];
    fprintf('========================================================================================\n');
    fprintf('  PMKS REQUIREMENT: 3 PMKS SIMULATION FILES NEEDED\n');
    fprintf('  Three distinct operating speeds detected:\n');
    fprintf('    1. Sensor 1 (Input Crank)   : ~%.2f RPM\n', RPM1);
    fprintf('    2. Sensor 2 (Follower Link) : ~%.2f RPM\n', RPM2);
    fprintf('    3. DAQ Sensors (BNO/MPU)    : ~%.2f RPM\n', RPM3);
    fprintf('========================================================================================\n\n');
end


%% 4. Request and Load PMKS+ Kinematic Loop Simulation Data

fprintf('Do you have the PMKS simulation file(s) for these RPM values ready?\n');
havePMKS = safeInput('Proceed with PMKS kinematic comparison now? [Y/N]: ', 'N');

if ~ismember(upper(strtrim(havePMKS)), {'Y', 'YES'})
    fprintf('\n========================================================================================\n');
    fprintf('  PMKS SIMULATION SETUP GUIDE (Run these simulations in PMKS+):\n');
    fprintf('========================================================================================\n');
    fprintf('  To complete kinematic comparison and RMSE calculations:\n');
    if PMKSfilenums == 1
        fprintf('  1. Open PMKS+ and configure your 4-bar linkage dimensions.\n');
        fprintf('  2. Set Crank Motor Speed to: %.2f RPM\n', target_rpm_list(1));
        fprintf('  3. Export kinematics Excel spreadsheet.\n');
    elseif PMKSfilenums == 2
        fprintf('  1. Open PMKS+ and configure your 4-bar linkage dimensions.\n');
        fprintf('  2. Run Simulation 1: Crank Speed = %.2f RPM (WitMotion Test)\n', target_rpm_list(1));
        fprintf('     Export as Excel spreadsheet.\n');
        fprintf('  3. Run Simulation 2: Crank Speed = %.2f RPM (DAQ Test)\n', target_rpm_list(2));
        fprintf('     Export as Excel spreadsheet.\n');
    else
        fprintf('  1. Open PMKS+ and configure your 4-bar linkage dimensions.\n');
        for k = 1:3
            fprintf('  Simulation %d: Crank Speed = %.2f RPM\n', k, target_rpm_list(k));
        end
        fprintf('  Export each run as an Excel spreadsheet.\n');
    end
    fprintf('  4. Re-run Maine.m and enter the exported PMKS file(s) when prompted.\n');
    fprintf('========================================================================================\n');
    fprintf('  Sensor data extraction, organization, and RPM calculation completed successfully\n');
    fprintf('========================================================================================\n');
    return;
end

% User confirmed PMKS files are ready: prompt and load tables
fprintf('\n--- 4. Loading PMKS+ Kinematic Simulation Files ---\n');

if PMKSfilenums == 1
    promptPMKS = sprintf('---Enter PMKS file for %.2f RPM---: ', target_rpm_list(1));
    pmks_file1 = safeInput(promptPMKS, '');
    if ~exist(pmks_file1, 'file')
        error('PMKS file not found: %s', pmks_file1);
    end
    pmks_table1 = readtable(pmks_file1, 'VariableNamingRule', 'preserve');

    % Map to all 3 datasets
    pmks_table_daq = pmks_table1; rpm_daq = target_rpm_list(1);
    pmks_table_s1  = pmks_table1; rpm_s1  = target_rpm_list(1);
    pmks_table_s2  = pmks_table1; rpm_s2  = target_rpm_list(1);
    fprintf('  Loaded Common PMKS File: %s (%.2f RPM, %d rows)\n', pmks_file1, rpm_common, height(pmks_table1));

elseif PMKSfilenums == 2
    if match_1_2
        % Standard: WitMotion file + DAQ file
        promptWT  = sprintf('---Enter PMKS file for WitMotion (%.2f RPM)---: ', rpm_wt);
        promptDAQ = sprintf('---Enter PMKS file for DAQ (%.2f RPM)---: ', rpm_daq);
        file_wt_name  = safeInput(promptWT, '');
        file_daq_name = safeInput(promptDAQ, '');

        if ~exist(file_wt_name, 'file')
            error('PMKS file not found: %s', file_wt_name);
        end
        if ~exist(file_daq_name, 'file')
            error('PMKS file not found: %s', file_daq_name);
        end

        pmks_table_wt  = readtable(file_wt_name, 'VariableNamingRule', 'preserve');
        pmks_table_daq = readtable(file_daq_name, 'VariableNamingRule', 'preserve');

        pmks_table_s1 = pmks_table_wt;  rpm_s1 = rpm_wt;
        pmks_table_s2 = pmks_table_wt;  rpm_s2 = rpm_wt;
        fprintf('  Loaded WitMotion PMKS: %s (%.2f RPM, %d rows)\n', file_wt_name, rpm_wt, height(pmks_table_wt));
        fprintf('  Loaded DAQ PMKS      : %s (%.2f RPM, %d rows)\n', file_daq_name, rpm_daq, height(pmks_table_daq));

    elseif match_1_3
        promptMatch = sprintf('---Enter PMKS file for S1 & DAQ (%.2f RPM)---: ', rpm_match);
        promptS2    = sprintf('---Enter PMKS file for S2 (%.2f RPM)---: ', rpm_other);
        file_match_name = safeInput(promptMatch, '');
        file_s2_name    = safeInput(promptS2, '');

        pmks_table_match = readtable(file_match_name, 'VariableNamingRule', 'preserve');
        pmks_table_s2    = readtable(file_s2_name, 'VariableNamingRule', 'preserve');

        pmks_table_daq = pmks_table_match; rpm_daq = rpm_match;
        pmks_table_s1  = pmks_table_match; rpm_s1  = rpm_match;
        rpm_s2         = rpm_other;

    else % match_2_3
        promptMatch = sprintf('---Enter PMKS file for S2 & DAQ (%.2f RPM)---: ', rpm_match);
        promptS1    = sprintf('---Enter PMKS file for S1 (%.2f RPM)---: ', rpm_other);
        file_match_name = safeInput(promptMatch, '');
        file_s1_name    = safeInput(promptS1, '');

        pmks_table_match = readtable(file_match_name, 'VariableNamingRule', 'preserve');
        pmks_table_s1    = readtable(file_s1_name, 'VariableNamingRule', 'preserve');

        pmks_table_daq = pmks_table_match; rpm_daq = rpm_match;
        pmks_table_s2  = pmks_table_match; rpm_s2  = rpm_match;
        rpm_s1         = rpm_other;
    end

else
    % 3 PMKS files
    promptS1  = sprintf('---Enter PMKS file for Sensor 1 Crank (%.2f RPM)---: ', RPM1);
    promptS2  = sprintf('---Enter PMKS file for Sensor 2 Follower (%.2f RPM)---: ', RPM2);
    promptDAQ = sprintf('---Enter PMKS file for DAQ Sensors (%.2f RPM)---: ', RPM3);

    file_s1_name  = safeInput(promptS1, '');
    file_s2_name  = safeInput(promptS2, '');
    file_daq_name = safeInput(promptDAQ, '');

    pmks_table_s1  = readtable(file_s1_name, 'VariableNamingRule', 'preserve');
    pmks_table_s2  = readtable(file_s2_name, 'VariableNamingRule', 'preserve');
    pmks_table_daq = readtable(file_daq_name, 'VariableNamingRule', 'preserve');

    rpm_s1  = RPM1;
    rpm_s2  = RPM2;
    rpm_daq = RPM3;
end


%% 5. Process DAQ Dataset (BNO1, BNO2, MPU vs. PMKS DAQ Model)
fprintf('\n========================================================================================\n');
fprintf('  PROCESSING DATASET 1: %.2f RPM DAQ TEST (BNO1, BNO2, MPU)\n', rpm_daq);
fprintf('========================================================================================\n');

% Extract primary signals from DAQ file 3
t_daq = double(s3_raw.Time) / 1000.0; % Convert ms to seconds
[t_daq, u_daq] = unique(t_daq, 'stable');

bno1_vel_x = s3_raw.BNO1GyroX(u_daq);
bno1_ang_z = s3_raw.BNO1AngleZ(u_daq);

bno2_vel_x = s3_raw.BNO2GyroX(u_daq);
bno2_ang_z = s3_raw.BNO2AngleZ(u_daq);

mpu_vel_y  = s3_raw.MPUGyroY(u_daq);
mpu_ang_y  = s3_raw.MPUAngleY(u_daq);

% Align steady-state starting point matching PMKS initial state with positive acceleration
[tStart_daq, idxKeep_daq, tAligned_daq, numRevs_daq] = ...
    findSteadyStateAndAlign(t_daq, bno2_vel_x, pmks_table_daq, rpm_daq, ministart);

% Trim all DAQ sensor channels to common steady-state window
t_daq_ss      = tAligned_daq;
bno1_vel_x_ss = bno1_vel_x(idxKeep_daq);
bno1_ang_z_ss = bno1_ang_z(idxKeep_daq);
bno2_vel_x_ss = bno2_vel_x(idxKeep_daq);
bno2_ang_z_ss = bno2_ang_z(idxKeep_daq);
mpu_vel_y_ss  = mpu_vel_y(idxKeep_daq);
mpu_ang_y_ss  = mpu_ang_y(idxKeep_daq);

% Duplicate / loop the 1-rev PMKS kinematics over the needed duration
[pmks_daq_rep, T_daq_period, t_sim_daq] = repeatPMKSData(pmks_table_daq, rpm_daq, numRevs_daq + 1);

% Resample continuous PMKS kinematics onto experimental timestamps
pmks_coupler_w   = interp1(t_sim_daq, pmks_daq_rep.('Link CBFG_angVel_deg_s'), t_daq_ss, 'pchip', 'extrap');
pmks_follower_w  = interp1(t_sim_daq, pmks_daq_rep.('Link DCE_angVel_deg_s'),  t_daq_ss, 'pchip', 'extrap');
pmks_angleF      = interp1(t_sim_daq, pmks_daq_rep.angleF_deg,                 t_daq_ss, 'pchip', 'extrap');
pmks_angleE      = interp1(t_sim_daq, pmks_daq_rep.angleE_deg,                 t_daq_ss, 'pchip', 'extrap');
pmks_angleG      = interp1(t_sim_daq, pmks_daq_rep.angleG_deg,                 t_daq_ss, 'pchip', 'extrap');

% Calculate RMSE metrics for Dataset 1
daqResults.targetRPM    = rpm_daq;
daqResults.t            = t_daq_ss;
daqResults.BNO1_w_exp   = bno1_vel_x_ss;
daqResults.BNO1_w_sim   = pmks_coupler_w;
daqResults.m_BNO1_w     = calculateRMSE(bno1_vel_x_ss, pmks_coupler_w, 'BNO1 Coupler \omega (deg/s)', 'deg/s', true);

daqResults.BNO2_w_exp   = bno2_vel_x_ss;
daqResults.BNO2_w_sim   = pmks_follower_w;
daqResults.m_BNO2_w     = calculateRMSE(bno2_vel_x_ss, pmks_follower_w, 'BNO2 Follower \omega (deg/s)', 'deg/s', true);

daqResults.MPU_w_exp    = mpu_vel_y_ss;
daqResults.MPU_w_sim    = pmks_coupler_w;
daqResults.m_MPU_w      = calculateRMSE(mpu_vel_y_ss,  pmks_coupler_w, 'MPU Coupler \omega (deg/s)',  'deg/s', true);

daqResults.BNO1_ang_exp = bno1_ang_z_ss;
daqResults.m_BNO1_ang   = calculateRMSE(bno1_ang_z_ss, pmks_angleF, 'BNO1 Coupler Angle (deg)', 'deg', true);
daqResults.BNO1_ang_sim = daqResults.m_BNO1_ang.y_sim_aligned;

daqResults.BNO2_ang_exp = bno2_ang_z_ss;
daqResults.m_BNO2_ang   = calculateRMSE(bno2_ang_z_ss, pmks_angleE, 'BNO2 Follower Angle (deg)', 'deg', true);
daqResults.BNO2_ang_sim = daqResults.m_BNO2_ang.y_sim_aligned;

daqResults.MPU_ang_exp  = mpu_ang_y_ss;
daqResults.m_MPU_ang    = calculateRMSE(mpu_ang_y_ss,  pmks_angleG, 'MPU Coupler Angle (deg)',  'deg', true);
daqResults.MPU_ang_sim  = daqResults.m_MPU_ang.y_sim_aligned;


%% 6. Process WitMotion Test (Sensor 1 & Sensor 2 vs. PMKS Model)
fprintf('\n========================================================================================\n');
fprintf('  PROCESSING DATASET 2: WITMOTION TEST (SENSOR 1: %.2f RPM | SENSOR 2: %.2f RPM)\n', rpm_s1, rpm_s2);
fprintf('========================================================================================\n');

% Extract timestamps and clean unique indices
[t_s1, u_s1] = unique(s1_raw.Chip_Time_s, 'stable');
[t_s2, u_s2] = unique(s2_raw.Chip_Time_s, 'stable');

s1_clean = s1_raw(u_s1, :);
s2_clean = s2_raw(u_s2, :);

% Align steady-state starting point using Follower GyroY (Sensor 2)
[tStart_wt, idxKeep_wt, tAligned_wt, numRevs_s2] = ...
    findSteadyStateAndAlign(t_s2, s2_clean.Angular_Velocity_Y_deg_s, pmks_table_s2, rpm_s2, 1.5);

% Trim Sensor 2
t_s2_ss  = tAligned_wt;
s2_ss    = s2_clean(idxKeep_wt, :);

% Synchronize Sensor 1
if abs(rpm_s1 - rpm_s2) <= rpmTol
    idxKeep_s1 = (t_s1 >= tStart_wt);
    t_s1_ss    = t_s1(idxKeep_s1) - tStart_wt;
    s1_ss      = s1_clean(idxKeep_s1, :);
else
    [tStart_s1, idxKeep_s1, t_s1_ss, numRevs_s1] = ...
        findSteadyStateAndAlign(t_s1, abs(s1_clean.Angular_Velocity_Z_deg_s), pmks_table_s1, rpm_s1, 1.5);
    s1_ss = s1_clean(idxKeep_s1, :);
end

% Duplicate / loop PMKS kinematics over the needed duration
neededSpan_s2 = max(t_s2_ss);
numRevs_s2_needed = ceil(neededSpan_s2 / (60.0 / rpm_s2)) + 1;
[pmks_s2_rep, T_s2_period, t_sim_s2] = repeatPMKSData(pmks_table_s2, rpm_s2, numRevs_s2_needed);

neededSpan_s1 = max(t_s1_ss);
numRevs_s1_needed = ceil(neededSpan_s1 / (60.0 / rpm_s1)) + 1;
[pmks_s1_rep, T_s1_period, t_sim_s1] = repeatPMKSData(pmks_table_s1, rpm_s1, numRevs_s1_needed);

% Evaluate Sensor 2 multi-axis correlation (TA Axis Y vs. Axis X and Z)
sim_w_dce_deg_s = pmks_s2_rep.('Link DCE_angVel_deg_s');
s2_axisResults  = evaluateFollowerAxes(t_s2_ss, s2_ss, t_sim_s2, sim_w_dce_deg_s);

% Resample continuous PMKS kinematics onto Sensor 1 timestamps
pmks_crank_w    = interp1(t_sim_s1, pmks_s1_rep.('Link AB_angVel_deg_s'), t_s1_ss, 'pchip', 'extrap');
pmks_crank_ang  = interp1(t_sim_s1, pmks_s1_rep.angleAB_deg,             t_s1_ss, 'pchip', 'extrap');

% Resample continuous PMKS kinematics onto Sensor 2 timestamps
pmks_follower_w   = interp1(t_sim_s2, pmks_s2_rep.('Link DCE_angVel_deg_s'), t_s2_ss, 'pchip', 'extrap');
pmks_follower_ang = interp1(t_sim_s2, pmks_s2_rep.angleE_deg,                t_s2_ss, 'pchip', 'extrap');

% Calculate RMSE metrics for Dataset 2
wtResults.targetRPM   = rpm_s2;
wtResults.rpm_s1      = rpm_s1;
wtResults.rpm_s2      = rpm_s2;
wtResults.t_s1        = t_s1_ss;
wtResults.t_s2        = t_s2_ss;

wtResults.S1_w_exp    = abs(double(s1_ss.Angular_Velocity_Z_deg_s));
wtResults.S1_w_sim    = pmks_crank_w;
wtResults.m_S1_w      = calculateRMSE(wtResults.S1_w_exp, pmks_crank_w, 'Sensor 1 Input Crank \omega (deg/s)', 'deg/s', false);

wtResults.S2_wy_exp   = double(s2_ss.Angular_Velocity_Y_deg_s);
wtResults.S2_w_sim    = pmks_follower_w;
wtResults.m_S2_wy     = calculateRMSE(wtResults.S2_wy_exp, pmks_follower_w, 'Sensor 2 Follower \omega [TA Axis Y]', 'deg/s', true);

% Sensor 1 Angle (Pitch Angle Y: periodic +/-90 deg excursion)
s1_ang_y              = double(s1_ss.Angle_Y_deg);
pmks_crank_pitch      = asind(sin(deg2rad(pmks_crank_ang)));
wtResults.S1_ang_exp  = s1_ang_y;
wtResults.m_S1_ang    = calculateRMSE(s1_ang_y, pmks_crank_pitch, 'Sensor 1 Pitch Angle [Angle Y]', 'deg', true);
wtResults.S1_ang_sim  = wtResults.m_S1_ang.y_sim_aligned;

% Sensor 2 Angle (rocking angle excursion)
s2_ang_y              = double(s2_ss.Angle_Y_deg);
wtResults.S2_ang_exp  = s2_ang_y;
wtResults.m_S2_ang    = calculateRMSE(s2_ang_y, pmks_follower_ang, 'Sensor 2 Follower Angle [TA Axis Y]', 'deg', true);
wtResults.S2_ang_sim  = wtResults.m_S2_ang.y_sim_aligned;


%% 7. Formatted Summary Error Tables & Excel Exports
fprintf('\n========================================================================================\n');
fprintf('  FINAL KINEMATIC ACCURACY & RMSE SUMMARY REPORT\n');
fprintf('========================================================================================\n\n');

% Compile Dataset 1 Table (DAQ)
mList1 = {daqResults.m_BNO1_w, daqResults.m_BNO2_w, daqResults.m_MPU_w, ...
          daqResults.m_BNO1_ang, daqResults.m_BNO2_ang, daqResults.m_MPU_ang};
table1_data = struct('Channel', {}, 'Unit', {}, 'RMSE', {}, 'RMSE_RPM', {}, 'MAE', {}, 'Correlation_R', {});
for i = 1:length(mList1)
    m = mList1{i};
    table1_data(i).Channel       = m.SignalName;
    table1_data(i).Unit          = m.Unit;
    table1_data(i).RMSE          = m.RMSE;
    table1_data(i).RMSE_RPM      = m.RMSE_RPM;
    table1_data(i).MAE           = m.MAE;
    table1_data(i).Correlation_R = m.Correlation_R;
end
tSummary1 = struct2table(table1_data);
fprintf('--- DATASET 1: %.2f RPM DAQ MULTI-SENSOR RUN ---\n', rpm_daq);
disp(tSummary1);

% Compile Dataset 2 Table (WitMotion)
mList2 = {wtResults.m_S1_w, wtResults.m_S2_wy, wtResults.m_S1_ang, wtResults.m_S2_ang};
table2_data = struct('Channel', {}, 'Unit', {}, 'RMSE', {}, 'RMSE_RPM', {}, 'MAE', {}, 'Correlation_R', {});
for i = 1:length(mList2)
    m = mList2{i};
    cName = m.SignalName;
    rVal = m.Correlation_R;
    if contains(cName, 'Sensor 1 Input Crank')
        cName = "Sensor 1 Input Crank \omega";
        rVal = NaN;
    end
    table2_data(i).Channel       = cName;
    table2_data(i).Unit          = m.Unit;
    table2_data(i).RMSE          = m.RMSE;
    table2_data(i).RMSE_RPM      = m.RMSE_RPM;
    table2_data(i).MAE           = m.MAE;
    table2_data(i).Correlation_R = rVal;
end
tSummary2 = struct2table(table2_data);
fprintf('\n--- DATASET 2: %.2f RPM WITMOTION WIRELESS RUN ---\n', rpm_s2);
disp(tSummary2);

% Save summary tables to Excel
fileSummaryDAQ = sprintf('RMSE_Summary_%.2fRPM_DAQ.xlsx', rpm_daq);
fileSummaryWT  = sprintf('RMSE_Summary_%.2fRPM_WitMotion.xlsx', rpm_s2);

try
    writetable(tSummary1, fileSummaryDAQ);
    fprintf('  Saved Excel table: %s\n', fileSummaryDAQ);
catch ME
    warning('Could not overwrite %s (%s).', fileSummaryDAQ, ME.message);
end

try
    writetable(tSummary2, fileSummaryWT);
    fprintf('  Saved Excel table: %s\n', fileSummaryWT);
catch ME
    warning('Could not overwrite %s (%s).', fileSummaryWT, ME.message);
end


%% 8. Generate Overlaid Comparison Graphs
fprintf('\n--- 8. Generating Comparison Graphs and Saving Figures ---\n');
plotComparison(daqResults, wtResults);

fprintf('\n========================================================================================\n');
fprintf('  ANALYSIS AND AUTOMATION COMPLETE\n');
fprintf('========================================================================================\n');


%% HELPER FUNCTIONS
function val = safeInput(promptStr, defaultVal)
    try
        raw = input(promptStr, 's');
        if isempty(strtrim(raw))
            val = defaultVal;
        else
            val = strtrim(raw);
        end
    catch
        val = defaultVal;
    end
end