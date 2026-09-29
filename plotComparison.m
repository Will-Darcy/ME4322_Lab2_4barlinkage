function plotComparison(daqResults, wtResults)
% PLOTCOMPARISON Generates comprehensive comparison figures between experimental
% sensor measurements and looped PMKS+ simulation models.
% Supports dynamic operating RPMs for DAQ and WitMotion tests.

    % Extract RPMs dynamically
    if isfield(daqResults, 'targetRPM')
        rpm_daq = daqResults.targetRPM;
    else
        rpm_daq = 15.0;
    end

    if isfield(wtResults, 'targetRPM')
        rpm_wt = wtResults.targetRPM;
    elseif isfield(wtResults, 'rpm_s2')
        rpm_wt = wtResults.rpm_s2;
    else
        rpm_wt = 16.17;
    end

    % Color palette
    c_blue   = [0.00, 0.45, 0.74];
    c_orange = [0.85, 0.33, 0.10];
    c_green  = [0.47, 0.67, 0.19];
    c_purple = [0.49, 0.18, 0.56];
    c_gray   = [0.25, 0.25, 0.25];
    c_pmks   = [1.00, 0.25, 0.25]; % Red for PMKS theoretical curves




    % =========================================================================
    %% 1. COMBINED OVERVIEW: DAQ TEST
    % =========================================================================
    f1 = figure('Name', sprintf('%.2f RPM DAQ Overview', rpm_daq), 'Color', 'w', 'Position', [50, 50, 1200, 620]);
    t1 = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t1, sprintf('%.2f RPM Multi-Sensor DAQ Test vs. Looped PMKS+ Kinematics (BNO1, BNO2, MPU)', rpm_daq), ...
        'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');

    % --- ROW 1: ANGULAR VELOCITIES ---
    nexttile(t1, 1);
    plot(daqResults.t, daqResults.m_BNO1_w.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_BNO1_w.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; ylabel('\omega (deg/s)'), 'k';
    title(sprintf('BNO1 Coupler \\omega (RMSE: %.2f deg/s | %.2f RPM)', ...
        daqResults.m_BNO1_w.RMSE, daqResults.m_BNO1_w.RMSE_RPM), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (Gyro X)', 'PMKS Coupler', 'Location', 'best');

    nexttile(t1, 2);
    plot(daqResults.t, daqResults.m_BNO2_w.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_BNO2_w.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; ylabel('\omega (deg/s)', 'Color', 'k');
    title(sprintf('BNO2 Follower \\omega (RMSE: %.2f deg/s | %.2f RPM)', ...
        daqResults.m_BNO2_w.RMSE, daqResults.m_BNO2_w.RMSE_RPM), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (Gyro X)', 'PMKS Follower', 'Location', 'best');

    nexttile(t1, 3);
    plot(daqResults.t, daqResults.m_MPU_w.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_MPU_w.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; ylabel('\omega (deg/s)', 'Color', 'k');
    title(sprintf('MPU Coupler \\omega (RMSE: %.2f deg/s | %.2f RPM)', ...
        daqResults.m_MPU_w.RMSE, daqResults.m_MPU_w.RMSE_RPM), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (Gyro Y)', 'PMKS Coupler', 'Location', 'best');

    % --- ROW 2: ANGLES ---
    nexttile(t1, 4);
    plot(daqResults.t, daqResults.m_BNO1_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_BNO1_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('BNO1 Coupler Angle \\theta_F (RMSE: %.2f^\\circ | R = %.4f)', ...
        daqResults.m_BNO1_ang.RMSE, daqResults.m_BNO1_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (Angle Z)', 'PMKS Angle F', 'Location', 'best');

    nexttile(t1, 5);
    plot(daqResults.t, daqResults.m_BNO2_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_BNO2_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('BNO2 Follower Angle \\theta_E (RMSE: %.2f^\\circ | R = %.4f)', ...
        daqResults.m_BNO2_ang.RMSE, daqResults.m_BNO2_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (Angle Z)', 'PMKS Angle E', 'Location', 'best');

    nexttile(t1, 6);
    plot(daqResults.t, daqResults.m_MPU_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_MPU_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('MPU Coupler Angle \\theta_G (RMSE: %.2f^\\circ | R = %.4f)', ...
        daqResults.m_MPU_ang.RMSE, daqResults.m_MPU_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (Angle Y)', 'PMKS Angle G', 'Location', 'best');

    outName1 = sprintf('Comparison_%.2fRPM_DAQ.png', rpm_daq);
    saveas(f1, outName1);
    fprintf('  Saved plot: %s\n', outName1);

    % =========================================================================
    %% 2. COMBINED OVERVIEW: WITMOTION TEST
    % =========================================================================
    f2 = figure('Name', sprintf('%.2f RPM WitMotion Overview', rpm_wt), 'Color', 'w', 'Position', [80, 80, 1100, 620]);
    t2 = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t2, sprintf('%.2f RPM WitMotion Wireless Test vs. Looped PMKS+ Kinematics (Sensor 1 & Sensor 2)', rpm_wt), ...
        'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');

    % Tile 1: WT1 Input Crank Velocity
    nexttile(t2, 1);
    plot(wtResults.t_s1, wtResults.S1_w_exp, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(wtResults.t_s1, wtResults.S1_w_sim, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.6);
    grid on; ylabel('\omega_z (deg/s)', 'Color', 'k');
    title(sprintf('Sensor 1 Input Crank \\omega (RMSE: %.2f deg/s | %.2f RPM)', ...
        wtResults.m_S1_w.RMSE, wtResults.m_S1_w.RMSE_RPM), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (WT1 |\omega_z|)', 'PMKS Crank AB', 'Location', 'southeast');

    % Tile 2: WT2 Follower Rocker Velocity
    nexttile(t2, 2);
    plot(wtResults.t_s2, wtResults.m_S2_wy.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(wtResults.t_s2, wtResults.m_S2_wy.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; ylabel('\omega (deg/s)', 'Color', 'k');
    title(sprintf('Sensor 2 Follower \\omega [TA Axis Y] (RMSE: %.2f deg/s | %.2f RPM | R = %.4f)', ...
        wtResults.m_S2_wy.RMSE, wtResults.m_S2_wy.RMSE_RPM, wtResults.m_S2_wy.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (Axis Y Aligned)', 'PMKS Follower DCE', 'Location', 'best');

    % Tile 3: WT1 Crank Pitch Angle
    nexttile(t2, 3);
    plot(wtResults.t_s1, wtResults.m_S1_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(wtResults.t_s1, wtResults.m_S1_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('Sensor 1 Pitch Angle Y (RMSE: %.2f^\\circ | R = %.4f)', ...
        wtResults.m_S1_ang.RMSE, wtResults.m_S1_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (Angle Y)', 'PMKS Pitch Model', 'Location', 'best');

    % Tile 4: WT2 Follower Rocking Angle
    nexttile(t2, 4);
    plot(wtResults.t_s2, wtResults.m_S2_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(wtResults.t_s2, wtResults.m_S2_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('Sensor 2 Follower Angle [TA Axis Y] (RMSE: %.2f^\\circ | R = %.4f)', ...
        wtResults.m_S2_ang.RMSE, wtResults.m_S2_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp (Angle Y)', 'PMKS Follower DCE', 'Location', 'best');

    outName2 = sprintf('Comparison_%.2fRPM_WitMotion.png', rpm_wt);
    saveas(f2, outName2);
    fprintf('  Saved plot: %s\n', outName2);

    % =========================================================================
    %% 3. DEDICATED INDIVIDUAL SENSOR FIGURES
    % =========================================================================
    % BNO1
    f_bno1 = figure('Name', 'Sensor BNO1 Evaluation', 'Color', 'w', 'Position', [100, 100, 850, 600]);
    tb1 = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tb1, sprintf('BNO1 Sensor: Coupler Link Dynamics (%.2f RPM Test)', rpm_daq), 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');
    nexttile(tb1, 1);
    plot(daqResults.t, daqResults.m_BNO1_w.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_BNO1_w.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; ylabel('\omega (deg/s)', 'Color', 'k');
    title(sprintf('Angular Velocity \\omega_x vs. PMKS Coupler Link (RMSE: %.2f deg/s | R = %.4f)', ...
        daqResults.m_BNO1_w.RMSE, daqResults.m_BNO1_w.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('BNO1 Gyro X', 'PMKS Coupler', 'Location', 'best');
    nexttile(tb1, 2);
    plot(daqResults.t, daqResults.m_BNO1_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_BNO1_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('Orientation Angle \\theta_z vs. PMKS Joint Vector B-F (RMSE: %.2f^\\circ | R = %.4f)', ...
        daqResults.m_BNO1_ang.RMSE, daqResults.m_BNO1_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('BNO1 Angle Z', 'PMKS Vector B-F', 'Location', 'best');
    saveas(f_bno1, 'Figure_Sensor_BNO1.png');

    % BNO2
    f_bno2 = figure('Name', 'Sensor BNO2 Evaluation', 'Color', 'w', 'Position', [120, 120, 850, 600]);
    tb2 = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tb2, sprintf('BNO2 Sensor: Follower Rocker Dynamics (%.2f RPM Test)', rpm_daq), 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');
    nexttile(tb2, 1);
    plot(daqResults.t, daqResults.m_BNO2_w.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_BNO2_w.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; ylabel('\omega (deg/s)', 'Color', 'k');
    title(sprintf('Angular Velocity \\omega_x vs. PMKS Follower Link DCE (RMSE: %.2f deg/s | R = %.4f)', ...
        daqResults.m_BNO2_w.RMSE, daqResults.m_BNO2_w.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('BNO2 Gyro X', 'PMKS Follower DCE', 'Location', 'best');
    nexttile(tb2, 2);
    plot(daqResults.t, daqResults.m_BNO2_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_BNO2_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('Orientation Angle \\theta_z vs. PMKS Joint Vector D-E (RMSE: %.2f^\\circ | R = %.4f)', ...
        daqResults.m_BNO2_ang.RMSE, daqResults.m_BNO2_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('BNO2 Angle Z', 'PMKS Vector D-E', 'Location', 'best');
    saveas(f_bno2, 'Figure_Sensor_BNO2.png');

    % MPU
    f_mpu = figure('Name', 'Sensor MPU Evaluation', 'Color', 'w', 'Position', [140, 140, 850, 600]);
    tb3 = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tb3, sprintf('MPU6050 Sensor: Coupler Link Dynamics (%.2f RPM Test)', rpm_daq), 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');
    nexttile(tb3, 1);
    plot(daqResults.t, daqResults.m_MPU_w.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_MPU_w.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; ylabel('\omega (deg/s)', 'Color', 'k');
    title(sprintf('Angular Velocity \\omega_y vs. PMKS Coupler Link (RMSE: %.2f deg/s | R = %.4f)', ...
        daqResults.m_MPU_w.RMSE, daqResults.m_MPU_w.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('MPU Gyro Y', 'PMKS Coupler', 'Location', 'best');
    nexttile(tb3, 2);
    plot(daqResults.t, daqResults.m_MPU_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(daqResults.t, daqResults.m_MPU_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('Orientation Angle \\theta_y vs. PMKS Joint Vector B-G (RMSE: %.2f^\\circ | R = %.4f)', ...
        daqResults.m_MPU_ang.RMSE, daqResults.m_MPU_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('MPU Angle Y', 'PMKS Vector B-G', 'Location', 'best');
    saveas(f_mpu, 'Figure_Sensor_MPU.png');

    % WT1
    f_wt1 = figure('Name', 'Sensor 1 WT1 Evaluation', 'Color', 'w', 'Position', [160, 160, 850, 600]);
    tb4 = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tb4, sprintf('Sensor 1 (WitMotion): Input Crank Kinematics (%.2f RPM Test)', rpm_wt), 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');
    nexttile(tb4, 1);
    plot(wtResults.t_s1, wtResults.S1_w_exp, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(wtResults.t_s1, wtResults.S1_w_sim, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.6);
    grid on; ylabel('\omega_z (deg/s)', 'Color', 'k');
    title(sprintf('Input Crank Speed (RMSE: %.2f deg/s | %.2f RPM)', wtResults.m_S1_w.RMSE, wtResults.m_S1_w.RMSE_RPM), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Measured Speed |\omega_z|', 'PMKS Model AB', 'Location', 'southeast');
    nexttile(tb4, 2);
    plot(wtResults.t_s1, wtResults.m_S1_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(wtResults.t_s1, wtResults.m_S1_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('Periodic Pitch Angle Y (RMSE: %.2f^\\circ | R = %.4f)', ...
        wtResults.m_S1_ang.RMSE, wtResults.m_S1_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('Exp Pitch (Angle Y)', 'PMKS Pitch Model', 'Location', 'best');
    saveas(f_wt1, 'Figure_Sensor_WT1.png');

    % WT2
    f_wt2 = figure('Name', 'Sensor 2 WT2 Evaluation', 'Color', 'w', 'Position', [180, 180, 850, 600]);
    tb5 = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tb5, sprintf('Sensor 2 (WitMotion): Follower Rocker Kinematics (%.2f RPM Test)', rpm_wt), 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');
    nexttile(tb5, 1);
    plot(wtResults.t_s2, wtResults.m_S2_wy.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(wtResults.t_s2, wtResults.m_S2_wy.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; ylabel('\omega (deg/s)', 'Color', 'k');
    title(sprintf('Follower Rocker \\omega vs. PMKS Link DCE [TA Axis Y] (RMSE: %.2f deg/s | R = %.4f)', ...
        wtResults.m_S2_wy.RMSE, wtResults.m_S2_wy.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('WT2 Gyro Y', 'PMKS Follower DCE', 'Location', 'best');
    nexttile(tb5, 2);
    plot(wtResults.t_s2, wtResults.m_S2_ang.y_exp_used, 'LineWidth', 1.3, 'Color', c_blue); hold on;
    plot(wtResults.t_s2, wtResults.m_S2_ang.y_sim_aligned, 'Color', c_pmks, 'LineStyle', '--', 'LineWidth', 1.5);
    grid on; xlabel('Aligned Time (s)', 'Color', 'k'); ylabel('Angle (deg)', 'Color', 'k');
    title(sprintf('Follower Angle Excursion vs. PMKS Link DCE (RMSE: %.2f^\\circ | R = %.4f)', ...
        wtResults.m_S2_ang.RMSE, wtResults.m_S2_ang.Correlation_R), 'Color', 'k');
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    legend('WT2 Angle Y', 'PMKS Follower DCE', 'Location', 'best');
    saveas(f_wt2, 'Figure_Sensor_WT2.png');

    % =========================================================================
    %% 4. BAR GRAPH: SENSOR ANGULAR VELOCITY RMSE (deg/s and RPM)
    % =========================================================================
    f_bar = figure('Name', 'Angular Velocity RMSE Bar Graph', 'Color', 'w', 'Position', [200, 200, 950, 520]);
    sensorLabels = {'BNO1 Coupler', 'BNO2 Follower', 'MPU Coupler', ...
                    'Sensor 1 (Crank)', 'Sensor 2 (Follower [TA Y])'};
    rmse_deg_vals = [daqResults.m_BNO1_w.RMSE, ...
                     daqResults.m_BNO2_w.RMSE, ...
                     daqResults.m_MPU_w.RMSE, ...
                     wtResults.m_S1_w.RMSE, ...
                     wtResults.m_S2_wy.RMSE];
    rmse_rpm_vals = rmse_deg_vals / 6.0;

    bar(rmse_deg_vals, 0.55, 'FaceColor', c_blue, 'EdgeColor', 'none'); hold on;
    grid on;
    ylabel('Velocity RMSE (deg/s)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    set(gca, 'XTick', 1:length(sensorLabels), 'XTickLabel', sensorLabels, 'FontSize', 10);
    xtickangle(15);
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    title('Root Mean Square Error (RMSE) of Angular Velocity Across Sensors', ...
        'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');

    for i = 1:length(rmse_deg_vals)
        text(i, rmse_deg_vals(i) + 0.6, ...
            sprintf('%.2f deg/s\n(%.2f RPM)', rmse_deg_vals(i), rmse_rpm_vals(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 9.5, 'FontWeight', 'bold');
    end
    ylim([0, max(rmse_deg_vals) + 3.5]);
    saveas(f_bar, 'Figure_Velocity_RMSE_BarGraph.png');

    % =========================================================================
    %% 5. REPORT DASHBOARD: CORRELATION & ANGLE ACCURACY
    % =========================================================================
    f_dash = figure('Name', 'Kinematic Fidelity & Angle Accuracy Dashboard', ...
                    'Color', 'w', 'Position', [220, 220, 1050, 500]);
    td = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(td, 'Kinematic Fidelity & Angular Precision Dashboard', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');

    nexttile(td, 1);
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    corrChannels = {'BNO1 Coupler \omega', 'BNO2 Follower \omega', 'MPU Coupler \omega', ...
                    'BNO1 Angle \theta_F', 'BNO2 Angle \theta_E', 'MPU Angle \theta_G', ...
                    'WT2 Follower \omega', 'WT2 Follower Angle'};
    r_vals = [daqResults.m_BNO1_w.Correlation_R, ...
              daqResults.m_BNO2_w.Correlation_R, ...
              daqResults.m_MPU_w.Correlation_R, ...
              daqResults.m_BNO1_ang.Correlation_R, ...
              daqResults.m_BNO2_ang.Correlation_R, ...
              daqResults.m_MPU_ang.Correlation_R, ...
              wtResults.m_S2_wy.Correlation_R, ...
              wtResults.m_S2_ang.Correlation_R];

    barh(r_vals, 0.55, 'FaceColor', c_green, 'EdgeColor', 'none'); hold on;
    xline(0.95, 'r--', '0.95 Threshold (High Fidelity)', 'LineWidth', 1.2, 'LabelHorizontalAlignment', 'left');
    xlim([max(0.80, min(r_vals) - 0.05), 1.005]);
    grid on; xlabel('Pearson Correlation Coefficient (R)', 'Color', 'k');
    set(gca, 'YTick', 1:length(corrChannels), 'YTickLabel', corrChannels, 'FontSize', 9.5);
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    title('Waveform Harmonic Fidelity (Correlation R)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    for i = 1:length(r_vals)
        text(r_vals(i) - 0.008, i, sprintf('%.4f', r_vals(i)), ...
            'FontWeight', 'bold', 'FontSize', 9, 'VerticalAlignment', 'middle');
    end

    nexttile(td, 2);
    angleSensors = {'BNO1 Coupler (\theta_F)', 'BNO2 Follower (\theta_E)', 'MPU Coupler (\theta_G)', ...
                    'WT2 Follower (\theta_{DCE})'};
    ang_rmse_vals = [daqResults.m_BNO1_ang.RMSE, ...
                     daqResults.m_BNO2_ang.RMSE, ...
                     daqResults.m_MPU_ang.RMSE, ...
                     wtResults.m_S2_ang.RMSE];

    bar(ang_rmse_vals, 0.55, 'FaceColor', c_purple, 'EdgeColor', 'none'); hold on;
    grid on; ylabel('Angle RMSE (degrees)', 'Color', 'k');
    set(gca, 'XTick', 1:length(angleSensors), 'XTickLabel', angleSensors, 'FontSize', 9.5);
    xtickangle(15);
    ax = gca; ax.XColor = 'k'; ax.YColor = 'k';
    title('Link Angle Measurement RMSE (degrees)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    for i = 1:length(ang_rmse_vals)
        text(i, ang_rmse_vals(i) + 0.25, sprintf('%.2f^\\circ', ang_rmse_vals(i)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9.5);
    end
    ylim([0, max(ang_rmse_vals) + 1.2]);
    saveas(f_dash, 'Figure_Kinematic_Fidelity_Summary.png');

    fprintf('  All comparison plots successfully generated and saved.\n');

end
