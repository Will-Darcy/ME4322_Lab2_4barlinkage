function results = evaluateFollowerAxes(t_s2, s2_table, t_sim, sim_w_dce_deg_s)
% EVALUATEFOLLOWERAXES Analyzes Sensor 2 (WTFollowerLink) across X, Y, and Z
% angular velocity axes against PMKS Link DCE kinematics.
% Reports both the TA-specified Axis Y and the axis with highest correlation.
%
% Inputs:
%   t_s2             : Aligned experimental time vector for Sensor 2 (s)
%   s2_table         : Aligned Sensor 2 data table
%   t_sim            : Repeated PMKS simulation time vector (s)
%   sim_w_dce_deg_s  : Repeated PMKS Follower Link DCE angular velocity (deg/s)
%
% Output:
%   results          : Struct containing comparison report table, TA axis, and best axis

    % Resample simulation onto experimental time points
    w_sim_interp = interp1(t_sim, sim_w_dce_deg_s, t_s2, 'pchip', 'extrap');

    axes = {'X', 'Y', 'Z'};
    reportData = struct('Axis', {}, 'Correlation_R', {}, 'Inverted_R', {}, ...
                        'Optimal_Polarity', {}, 'RMSE_deg_s', {}, 'RMSE_RPM', {}, 'Status', {});

    bestR = -Inf;
    bestIdx = 2; % default to Y

    for k = 1:length(axes)
        ax = axes{k};
        colName = ['Angular_Velocity_' ax '_deg_s'];
        
        if ismember(colName, s2_table.Properties.VariableNames)
            w_exp = double(s2_table.(colName));
        else
            w_exp = zeros(size(t_s2));
        end

        % Drop NaNs if any
        valid = ~isnan(w_exp) & ~isnan(w_sim_interp);
        w_e = w_exp(valid);
        w_s = w_sim_interp(valid);

        % Zero-center for fair dynamic comparison
        w_e_zeroed = w_e - mean(w_e);
        w_s_zeroed = w_s - mean(w_s);

        % Correlation
        R_direct   = computePearsonCorr(w_e_zeroed, w_s_zeroed);
        R_inverted = computePearsonCorr(-w_e_zeroed, w_s_zeroed);

        if R_inverted > R_direct
            pol = "Inverted (-)";
            R_opt = R_inverted;
            w_comp = -w_e_zeroed;
        else
            pol = "Direct (+)";
            R_opt = R_direct;
            w_comp = w_e_zeroed;
        end

        % Calculate RMSE after zero-centering
        err = w_comp - w_s_zeroed;
        rmse_deg = sqrt(mean(err.^2));
        rmse_rpm = rmse_deg / 6.0;

        if strcmpi(ax, 'Y')
            status = "TA Specified";
        else
            status = "Alternate";
        end

        reportData(k).Axis             = string(['Axis ' ax]);
        reportData(k).Correlation_R    = round(R_direct, 4);
        reportData(k).Inverted_R       = round(R_inverted, 4);
        reportData(k).Optimal_Polarity = pol;
        reportData(k).RMSE_deg_s       = round(rmse_deg, 2);
        reportData(k).RMSE_RPM         = round(rmse_rpm, 2);
        reportData(k).Status           = status;

        if abs(R_opt) > bestR
            bestR = abs(R_opt);
            bestIdx = k;
        end
    end

    reportTable = struct2table(reportData);

    fprintf('\n========================================================================================\n');
    fprintf(' SENSOR 2 (FOLLOWER LINK) MULTI-AXIS CORRELATION & RMSE EVALUATION\n');
    fprintf('========================================================================================\n');
    disp(reportTable);
    fprintf('  * TA Specified Axis : Axis Y (R = %.4f | RMSE = %.2f deg/s)\n', ...
        reportTable.Correlation_R(2), reportTable.RMSE_deg_s(2));
    fprintf('  * Best Overall Axis : %s (R = %.4f | RMSE = %.2f deg/s)\n', ...
        reportTable.Axis(bestIdx), max(reportTable.Correlation_R(bestIdx), reportTable.Inverted_R(bestIdx)), ...
        reportTable.RMSE_deg_s(bestIdx));
    fprintf('========================================================================================\n\n');

    results.reportTable = reportTable;
    results.taAxis      = 'Y';
    results.bestAxis    = axes{bestIdx};
    results.w_sim_interp = w_sim_interp;
end

function r = computePearsonCorr(x, y)
    x = double(x(:)) - mean(double(x(:)));
    y = double(y(:)) - mean(double(y(:)));
    denom = sqrt(sum(x.^2) * sum(y.^2));
    if denom == 0
        r = 0;
    else
        r = sum(x .* y) / denom;
    end
end
