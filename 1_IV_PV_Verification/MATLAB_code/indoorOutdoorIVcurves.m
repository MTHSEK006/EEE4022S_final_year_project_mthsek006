%% MATLAB Script: Baseline DC Load I-V Curve Validation & ATP Pass/Fail Check
clear; clc; close all;

%% 1. User Input: Filenames & Operating Conditions
% Enter your measured Excel filenames here (must contain Voltage in col 1, Current in col 2)
excel_files = {
    'IV_panelcontrol_indoor150V.xlsx', ...
    'IV_panelcontrol_indoor200_fanOn.xlsx', ...
    'IV_panelcontrol_indoor200V.xlsx',...
    'IV_panelcontrol_indoor220_fanOn.xlsx'
    };

% Operating conditions corresponding to each file: [Irradiance (W/m^2), Temperature (°C)]
operating_conditions = [
    317.3, 45.6 ;
    644.2, 48.7;
    716.9, 59.6;
    835.6, 65.2 
    ];

num_files = length(excel_files);

%% 2. Panel Nameplate & STC Constants
Isc_stc   = 4.76;       % Short-circuit current at STC (A)
Voc_stc   = 21.6;       % Open-circuit voltage at STC (V)
G_stc     = 1000;       % Standard Irradiance (W/m^2)
T_ref     = 25.0;       % Reference Temperature (°C)
alpha_Isc = 0.0005;     % Temperature coefficient of Isc (A/°C)
beta_Voc  = -0.0422;    % Temperature coefficient of Voc (V/°C)
N_s       = 36;         % Number of series cells
V_a       = 0.0257 * N_s; % Thermal voltage scale factor
N_extrap  = 5;          % Number of low-end points for linear extrapolation at V = 0

%% 3. Preallocate Storage Results
% [G, T, Isc_meas, Isc_exp, Voc_meas, Voc_exp, Err_Isc(%), Err_Voc(%), RMSE_Isc, RMSE_Voc]
results_summary = zeros(num_files, 10); 

%% 4. Plotting Setup
nRows = ceil(sqrt(num_files));
nCols = ceil(num_files / nRows);
figure('Name', 'Baseline DC Load I-V Curve & ATP Validation', 'Color', 'w', 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);

%% 5. Processing Loop
for i = 1:num_files
    G_meas = operating_conditions(i, 1);
    T_curr = operating_conditions(i, 2);
    dT     = T_curr - T_ref;
    
    % Rounded values to the nearest 10th for display formatting
    G_rounded = round(G_meas, -1); 
    T_rounded = round(T_curr);
    
    try
        % Read Excel Data
        data = readmatrix(excel_files{i});
        validIdx = ~isnan(data(:, 1)) & ~isnan(data(:, 2));
        V_raw = data(validIdx, 1);
        I_raw = data(validIdx, 2);
        
        % Sort ascending by voltage
        [V_raw, sortIdx] = sort(V_raw, 'ascend');
        I_raw = I_raw(sortIdx);
        
        % Filter strictly positive values
        valid_pv = V_raw >= 0 & I_raw >= 0;
        V_raw = V_raw(valid_pv);
        I_raw = I_raw(valid_pv);
        
        % -----------------------------------------------------------------
        % A. EXTRAPOLATION FOR Isc (flat-region fit, knee points excluded)
        % -----------------------------------------------------------------
        Rsh_est   = 1721.41;            % shunt resistance from the SDM (Ohm)
        V_frac    = 0.6;                % flat region: V <= 0.6*Voc
        I_frac    = 0.95;               % ... and I >= 95% of the highest current
        max_corr  = 0.03;               % max allowed extrapolation: 3% of I_max
        Voc_est = max(V_raw);           % rough Voc, only used to select the region
        I_max   = max(I_raw);
        inFlat  = (V_raw <= V_frac*Voc_est) & (I_raw >= I_frac*I_max);
        Vf = V_raw(inFlat);
        If = I_raw(inFlat);
        
        % (1) Shunt-slope projection: physically based lower estimate
        Isc_shunt = max(If + Vf/Rsh_est);
        
        % (2) Linear fit through the flat points, if there are enough of them
        if numel(Vf) >= 2
            p_isc  = polyfit(Vf, If, 1);
            Isc_fit = p_isc(2);
            % Reject a fit that is rising or that extrapolates by more than max_corr
            if p_isc(1) > 0 || (Isc_fit - Isc_shunt) > max_corr*I_max
                Isc_fit = NaN;
            end
        else
            Isc_fit = NaN;
        end
        
        if ~isnan(Isc_fit)
            Isc_meas   = Isc_fit;
            isc_method = sprintf('flat-region fit (%d pts)', numel(Vf));
        else
            Isc_meas   = Isc_shunt;
            p_isc      = [-1/Rsh_est, Isc_shunt];
            isc_method = sprintf('shunt-slope projection (%d pts)', numel(Vf));
        end
        Isc_low  = Isc_shunt;                   
        Isc_high = max(Isc_shunt, Isc_meas);    
        fprintf('%s: Isc = %.3f A [%.3f - %.3f A], %s\n', ...
            excel_files{i}, Isc_meas, Isc_low, Isc_high, isc_method);
        
        % -----------------------------------------------------------------
        % B. EXTRACTION FOR Voc
        % -----------------------------------------------------------------
        [~, zeroI_idx] = min(abs(I_raw));
        idx_v = max(1, zeroI_idx-2):min(length(I_raw), zeroI_idx+2);
        Voc_meas = interp1(I_raw(idx_v), V_raw(idx_v), 0, 'linear', 'extrap');
        
        % -----------------------------------------------------------------
        % C. THEORETICAL EXPECTED VALUES
        % -----------------------------------------------------------------
        Isc_exp = (G_meas / G_stc) * (Isc_stc + alpha_Isc * dT);
        Voc_exp = Voc_stc + beta_Voc * dT + V_a * log(G_meas / G_stc);
        
        % -----------------------------------------------------------------
        % D. RESIDUALS & ERROR CALCULATIONS
        % -----------------------------------------------------------------
        res_Isc = Isc_exp - Isc_meas;
        res_Voc = Voc_exp - Voc_meas;
        
        % Relative Errors (%)
        err_isc_pct = (abs(res_Isc) / Isc_exp) * 100;
        err_voc_pct = (abs(res_Voc) / Voc_exp) * 100;
        
        % Independent RMSE metrics for Isc and Voc
        rmse_Isc = abs(res_Isc);
        rmse_Voc = abs(res_Voc);
       
        % Store summary
        results_summary(i, :) = [G_meas, T_curr, Isc_meas, Isc_exp, Voc_meas, Voc_exp, err_isc_pct, err_voc_pct, rmse_Isc, rmse_Voc];
        
        % -----------------------------------------------------------------
        % E. PLOTTING RESULTS
        % -----------------------------------------------------------------
        subplot(nRows, nCols, i);
        
        % Scatter plot for measured raw points
        plot(V_raw, I_raw, 'ko', 'MarkerSize', 3, 'MarkerFaceColor', 'k', 'DisplayName', 'Measured Data');
        hold on; grid on; box on;
        
        % Expected Reference Lines
        yline(Isc_exp, 'r--', 'LineWidth', 1.2, 'DisplayName', sprintf('Exp I_{sc} = %.2f A', Isc_exp));
        xline(Voc_exp, 'm--', 'LineWidth', 1.2, 'DisplayName', sprintf('Exp V_{oc} = %.2f V', Voc_exp));
        
        % Plot Extrapolated Measured Isc point at V=0
        plot(0, Isc_meas, 'rx', 'MarkerSize', 7, 'LineWidth', 2, 'DisplayName', sprintf('Meas I_{sc} = %.2f A', Isc_meas));
        
        % Show the line actually used for the extrapolation
        V_line = linspace(0, max(Vf), 20);
        plot(V_line, polyval(p_isc, V_line), 'r-', 'LineWidth', 1, ...
            'DisplayName', 'I_{sc} fit (flat region)');
        plot(Vf, If, 'ro', 'MarkerSize', 5, 'DisplayName', 'Points used for fit');
        xlabel('Voltage (V)', 'FontWeight', 'bold');
        ylabel('Current (A)', 'FontWeight', 'bold');
        
        title(sprintf('Indoor IV curve using DC load\nG ≈ %d W/m², T ≈ %d°C', G_rounded, T_rounded), 'FontSize', 8.5);
        legend('Location', 'southwest', 'FontSize', 6);
        
        xlim([0, max([V_raw; Voc_exp]) * 1.1]);
        ylim([0, max([I_raw; Isc_exp]) * 1.1]);
        hold off;
        
    catch ME
        fprintf('Error processing file %s: %s\n', excel_files{i}, ME.message);
    end
end

%% 6. ATP Pass / Fail Evaluation Display
fprintf('\n========================================================================================\n');
fprintf('                     ACCEPTANCE TEST PROCEDURE (ATP) - BASELINE CHECK                   \n');
fprintf('========================================================================================\n');
for i = 1:num_files
    if results_summary(i, 1) == 0, continue; end
    
    file_name = excel_files{i};
    isc_err   = results_summary(i, 7);
    voc_err   = results_summary(i, 8);
    rmse_Isc  = results_summary(i, 9);
    rmse_Voc  = results_summary(i, 10);
    
    % ATP Criteria: Relative error <= 10% and individual RMSE <= 0.5
    passed = (isc_err <= 10) && (voc_err <= 10) && (rmse_Isc <= 0.5) && (rmse_Voc <= 0.5); 
    
    fprintf('Test File: %s\n', file_name);
    fprintf('  -> I_sc Rel Error : %.2f%%\n', isc_err);
    fprintf('  -> V_oc Rel Error : %.2f%%\n', voc_err);
    fprintf('  -> RMSE (I_sc)    : %.4f A\n', rmse_Isc);
    fprintf('  -> RMSE (V_oc)    : %.4f V\n', rmse_Voc);
    
    if passed
        fprintf('  -> ATP STATUS     : \033[1;32mPASSED\033[0m\n');
    else
        fprintf('  -> ATP STATUS     : \033[1;31mFAILED\033[0m (Exceeds acceptable deviation limits)\n');
    end
    fprintf('----------------------------------------------------------------------------------------\n');
end

% Summary Table
atp_table = table((1:num_files)', excel_files', results_summary(:,1), results_summary(:,2), ...
    results_summary(:,3), results_summary(:,4), results_summary(:,5), results_summary(:,6), ...
    results_summary(:,7), results_summary(:,8), results_summary(:,9), results_summary(:,10), ...
    'VariableNames', {'ID', 'Filename', 'G_meas', 'Temp_C', 'Isc_Meas', 'Isc_Exp', 'Voc_Meas', 'Voc_Exp', 'Err_Isc_Pct', 'Err_Voc_Pct', 'RMSE_Isc', 'RMSE_Voc'});
disp(atp_table);