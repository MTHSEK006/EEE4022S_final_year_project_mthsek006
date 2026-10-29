%% MATLAB Script: SDM Validation Against Measured I-V Curves
clear; clc; close all;

%% 1. Input Parameters & Physical Constants
Ns        = 36;             % Number of series cells
n         = 1.000;          % Diode ideality factor
I0_STC    = 4.0491e-11;     % Saturation current at STC (A)
Rs        = 0.13043;        % Calibrated Series resistance (Ohms)
Rsh       = 1721.41;        % Extracted Shunt resistance (Ohms)

% Nominal STC Values (Reference Module Parameters at 1000 W/m^2, 25°C)
Isc_STC   = 4.76;           % Nominal short-circuit current at STC (A)
Voc_STC   = 21.6;           % Nominal open-circuit voltage at STC (V)
alpha_Isc = 0.0005;         % Temperature coefficient of Isc (A/°C)
beta_Voc  = -0.0422;        % Temperature coefficient of Voc (V/°C)
T_ref     = 25.0;           % Reference temperature (°C)
G_STC     = 1000;           % Standard irradiance (W/m^2)

% Responsivity & Constants
K_outdoor = Isc_STC / G_STC;% Outdoor Calibration Slope [A/(W/m^2)]
K_indoor  = 0.002425;       % Indoor halogen calibration slope
q         = 1.60217663e-19; % Electron charge (C)
k         = 1.380649e-23;   % Boltzmann constant (J/K)
Eg        = 1.12;           % Silicon bandgap energy (eV)
T_STC     = 298.15;         % Reference temperature (25°C in K)

%% 2. Excel Files & Environmental Conditions 
excel_files = {
    'IV_25Sep_indoor_G318_T31.xlsx',...
    'IV_25Sep_indoor_G394_T31.xlsx',...
    'IV_25Sep_indoor_G500_T33.xlsx'

    };

% Operating conditions: [Irradiance (W/m^2), Temperature (°C)]
operating_conditions = [
    318.2, 31.1 ; 
    394.7, 31.6; 
    501.2, 33.7  

    ]; 

num_files = length(excel_files);

%% Storage Tables
results_Isc  = zeros(num_files, 5); % [Ref/Exp, SDM, Meas, Err_SDM_vs_Ref(%), Err_SDM_vs_Meas(%)]
results_Voc  = zeros(num_files, 5); % [Ref/Exp, SDM, Meas, Err_SDM_vs_Ref(%), Err_SDM_vs_Meas(%)]
results_Pmp  = zeros(num_files, 7); % [Exp, SDM, Meas, Err_Meas_vs_Exp(%), Err_SDM_vs_Exp(%), Err_SDM_vs_Meas(%), RMSE_SDM_vs_Meas]
results_FF   = zeros(num_files, 3); % [FF_Exp(%), FF_SDM(%), FF_Meas(%)]

G_eff_vector = zeros(num_files, 1);
Isc_norm_vec = zeros(num_files, 1);

%% Visualization Setup
figure('Name', 'Independent 3-Pipeline PV Analysis (Measured vs Expected vs SDM)', ...
       'Color', [1 1 1], 'Position', [100, 100, 1200, 800]);

%% Execution Loop
for i = 1:num_files
    G_raw = operating_conditions(i, 1);
    T_C   = operating_conditions(i, 2);
    T_K   = T_C + 273.15;
    
    % =====================================================================
    % 1. MEASURED DATA (EXTRACTION VIA INTERPOLATION)
    % =====================================================================
    data = readmatrix(excel_files{i});
    validIdx = ~isnan(data(:, 1)) & ~isnan(data(:, 2));
    V_meas = data(validIdx, 1);
    I_meas = data(validIdx, 2);
    
    [V_meas, sortIdx] = sort(V_meas);
    I_meas = I_meas(sortIdx);
    
    % Direct extraction of Isc at V = 0 using linear interpolation
    Isc_meas = interp1(V_meas, I_meas, 0, 'linear', 'extrap');
    
    % Direct extraction of Voc at I = 0 using linear interpolation
    [~, zeroI_idx] = min(abs(I_meas));
    idx_v = max(1, zeroI_idx-2):min(length(I_meas), zeroI_idx+2);
    Voc_meas = interp1(I_meas(idx_v), V_meas(idx_v), 0, 'linear', 'extrap');
    
    % Measured Maximum Power Point (Pmp) and Fill Factor (FF)
    P_meas = V_meas .* I_meas;
    [Pmp_meas, max_p_idx] = max(P_meas);
    Vmp_meas = V_meas(max_p_idx);
    Imp_meas = I_meas(max_p_idx);
    FF_meas = (Pmp_meas / (Isc_meas * Voc_meas)) * 100; 
    
    % Temperature Normalization of Measured Short-Circuit Current
    Isc_meas_norm = Isc_meas / (1 + (alpha_Isc / Isc_STC) * (T_C - T_ref));
    Isc_norm_vec(i) = Isc_meas_norm;
    
    % =====================================================================
    % 2. EFFECTIVE IRRADIANCE & EXPECTED VALUES
    % =====================================================================
    G_eff = G_raw * (K_indoor / K_outdoor);
    G_eff_vector(i) = G_eff;

    % Calculate Expected Isc and Voc based on standard PV scaling formulas
    Isc_exp = (G_eff / G_STC) * (Isc_STC + alpha_Isc * (T_C - T_ref));
    Voc_exp = Voc_STC + beta_Voc * (T_C - T_ref) + (Ns * n * k * T_K / q) * log(G_eff / G_STC);

    % Empirical Estimation of Expected Fill Factor and Pmp
    Vt_cell = (k * T_K) / q;
    voc_n = Voc_exp / (Ns * n * Vt_cell);
    FF_exp = (voc_n - log(voc_n + 0.72)) / (voc_n + 1) * 100; 
    Pmp_exp = (FF_exp / 100) * Isc_exp * Voc_exp;

    % =====================================================================
    % 3. SINGLE-DIODE MODEL (SDM) SIMULATION
    % =====================================================================
    alpha_Isc_rel = alpha_Isc / Isc_STC;
    Iph_sdm = (G_eff / G_STC) * Isc_STC * (1 + alpha_Isc_rel * (T_C - T_ref));

    % Calculate diode saturation current (I0) based on temperature drift
    I0_sdm  = I0_STC * ((T_K / T_STC)^3) * exp((q * Eg / (n * k)) * ((1 / T_STC) - (1 / T_K)));
    Vt_sdm  = (Ns * n * k * T_K) / q;

    % Solve full SDM curve numerically using Newton-Raphson method
    V_sim = linspace(0, max(Voc_exp, Voc_meas) * 1.05, 500).';
    I_sim = zeros(size(V_sim));

    for v_idx = 1:length(V_sim)
        V_val = V_sim(v_idx);
        I_val = Iph_sdm; % Seed with independent photocurrent
        for iter = 1:50
            exp_term = exp((V_val + I_val * Rs) / Vt_sdm);
            f  = Iph_sdm - I0_sdm * (exp_term - 1) - (V_val + I_val * Rs) / Rsh - I_val;
            df = -I0_sdm * (Rs / Vt_sdm) * exp_term - (Rs / Rsh) - 1;
            I_next = I_val - f / df;
            if abs(I_next - I_val) < 1e-6, break; end
            I_val = max(0, I_next);
        end
        I_sim(v_idx) = I_val;
    end

    % Extraction of independent SDM values to compare against measured data
    Isc_sdm = I_sim(1);
    [~, min_I_idx] = min(abs(I_sim));
    Voc_sdm = V_sim(min_I_idx);

    P_sim = V_sim .* I_sim;
    [Pmp_sdm, max_psim_idx] = max(P_sim);
    Vmp_sdm = V_sim(max_psim_idx);
    Imp_sdm = I_sim(max_psim_idx);
    FF_sdm = (Pmp_sdm / (Isc_sdm * Voc_sdm)) * 100;

    % =====================================================================
    % METRICS, ERROR CALCULATIONS & RMSE
    % =====================================================================
    err_Isc_sdm_vs_exp  = ((Isc_sdm - Isc_exp) / Isc_exp) * 100;
    err_Isc_sdm_vs_meas = ((Isc_sdm - Isc_meas) / Isc_meas) * 100;
    
    err_Voc_sdm_vs_exp  = ((Voc_sdm - Voc_exp) / Voc_exp) * 100;
    err_Voc_sdm_vs_meas = ((Voc_sdm - Voc_meas) / Voc_meas) * 100;
    
    err_Pmp_meas_vs_exp = ((Pmp_meas - Pmp_exp) / Pmp_exp) * 100;
    err_Pmp_sdm_vs_exp  = ((Pmp_sdm - Pmp_exp) / Pmp_exp) * 100;
    err_Pmp_sdm_vs_meas = ((Pmp_sdm - Pmp_meas) / Pmp_meas) * 100;
    
    I_sim_interp = interp1(V_sim, I_sim, V_meas, 'linear', 'extrap');
    rmse_sdm_vs_meas = sqrt(mean((I_meas - I_sim_interp).^2));
    
    % Store Results
    results_Isc(i, :) = [Isc_exp, Isc_sdm, Isc_meas, err_Isc_sdm_vs_exp, err_Isc_sdm_vs_meas];
    results_Voc(i, :) = [Voc_exp, Voc_sdm, Voc_meas, err_Voc_sdm_vs_exp, err_Voc_sdm_vs_meas];
    results_Pmp(i, :) = [Pmp_exp, Pmp_sdm, Pmp_meas, err_Pmp_meas_vs_exp, err_Pmp_sdm_vs_exp, err_Pmp_sdm_vs_meas, rmse_sdm_vs_meas];
    results_FF(i, :)  = [FF_exp, FF_sdm, FF_meas];
    
    % =====================================================================
    % SUBPLOT VISUALIZATION
    % =====================================================================
    subplot(2, 2, i);
    
    plot(V_meas, I_meas, 'k.', 'MarkerSize', 6, 'DisplayName', 'Pipeline 1: Measured I-V');
    hold on;
    plot(Vmp_meas, Imp_meas, 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 8, ...
        'DisplayName', sprintf('Meas P_{mp} = %.2f W', Pmp_meas));
    
    plot(0, Isc_exp, 'r^', 'MarkerFaceColor', 'g', 'MarkerSize', 7, ...
        'DisplayName', sprintf('Pipeline 2: Exp I_{sc} = %.3f A', Isc_exp));
    plot(Voc_exp, 0, 'rd', 'MarkerFaceColor', 'm', 'MarkerSize', 7, ...
        'DisplayName', sprintf('Pipeline 2: Exp V_{oc} = %.2f V', Voc_exp));
    
    plot(V_sim, I_sim, 'b-', 'LineWidth', 1.5, ...
        'DisplayName', 'Pipeline 3: SDM Model Curve');
    plot(Vmp_sdm, Imp_sdm, 'bs', 'MarkerFaceColor', 'c', 'MarkerSize', 7, ...
        'DisplayName', sprintf('SDM P_{mp} = %.2f W', Pmp_sdm));
    
    grid on; box on;
    xlim([0, max([V_meas; V_sim; Voc_exp]) * 1.05]);
    ylim([0, max([I_meas; I_sim; Isc_exp]) * 1.1]);
    xlabel('Voltage (V)', 'FontWeight', 'bold');
    ylabel('Current (A)', 'FontWeight', 'bold');
    
    % Rounding G_raw to nearest 100 (-2) and T_C to nearest 10 (-1) for display purposes
    G_disp = round(G_raw, -2);
    T_disp = round(T_C);

    
    title(sprintf('Curve %d: G_{meas}=%d W/m^2, T=%d°C', i, G_disp, T_disp), 'FontWeight', 'bold');
    legend('Location', 'southwest', 'FontSize', 7);
    hold off;
end

%% Display Summary Tables
fprintf('\n====================================================================================\n');
fprintf('THREE-WAY COMPARISON FOR SHORT-CIRCUIT CURRENT (Isc in Amperes)\n');
fprintf('====================================================================================\n');
Curve     = (1:num_files)';
G_raw_Wm2 = operating_conditions(:, 1);
Temp_C    = operating_conditions(:, 2);
table_Isc = table(Curve, G_raw_Wm2, Temp_C, Isc_norm_vec, G_eff_vector, ...
    results_Isc(:,1), results_Isc(:,2), results_Isc(:,3), ...
    results_Isc(:,4), results_Isc(:,5), ...
    'VariableNames', {'Curve', 'G_measured', 'Temp_C', 'Isc_norm_A', 'G_eff', 'Isc_Expected_A', 'Isc_SDM_A', 'Isc_Meas_A', 'Err_SDM_vs_Exp_Pct', 'Err_SDM_vs_Meas_Pct'});
disp(table_Isc);

fprintf('\n====================================================================================\n');
fprintf('THREE-WAY COMPARISON FOR OPEN-CIRCUIT VOLTAGE (Voc in Volts)\n');
fprintf('====================================================================================\n');
table_Voc = table(Curve, G_eff_vector, Temp_C, ...
    results_Voc(:,1), results_Voc(:,2), results_Voc(:,3), ...
    results_Voc(:,4), results_Voc(:,5), ...
    'VariableNames', {'Curve', 'G_eff', 'Temp_C', 'Voc_Expected_V', 'Voc_SDM_V', 'Voc_Meas_V', 'Err_SDM_vs_Exp_Pct', 'Err_SDM_vs_Meas_Pct'});
disp(table_Voc);

fprintf('\n====================================================================================\n');
fprintf('MAXIMUM POWER POINT (Pmp in Watts), FILL FACTOR (%), AND RMSE VALIDATION\n');
fprintf('====================================================================================\n');
table_Pmp = table(Curve, G_eff_vector, Temp_C, ...
    results_Pmp(:,1), results_Pmp(:,2), results_Pmp(:,3), ...
    results_Pmp(:,4), results_Pmp(:,5), results_Pmp(:,6), ...
    results_FF(:,1), results_FF(:,2), results_FF(:,3), results_Pmp(:,7), ...
    'VariableNames', {'Curve', 'G_eff', 'Temp_C', 'Pmp_Exp_W', 'Pmp_SDM_W', 'Pmp_Meas_W', ...
                      'Err_Meas_vs_Exp_Pct', 'Err_SDM_vs_Exp_Pct', 'Err_SDM_vs_Meas_Pct', ...
                      'FF_Exp_Pct', 'FF_SDM_Pct', 'FF_Meas_Pct', 'RMSE_Current_A'});
disp(table_Pmp);