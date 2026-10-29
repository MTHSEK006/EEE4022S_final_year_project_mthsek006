%% MATLAB Script: Effective Indoor Irradiance Calculation
clear; clc; close all;

%% 1. Physical Constants & Calibration Setup
alpha_Isc = 0.00045; % Relative temperature coefficient (1/°C)
T_ref     = 25;      % Reference temperature (°C)
N_extrap  = 5;       % Points for linear extrapolation at V = 0

% --- OUTDOOR DATA INPUTS ---
outdoor_files = {
    'IV_outdoor_02Sep_G184.xlsx', ...
    'IV_outdoor_02Sep_G218.xlsx', ... 
    'IV_outdoor_07Sep_G592.xlsx', ... 
    'IV_outdoor_07Sep_G629.xlsx', ... 
    'IV_outdoor_07Sep_G651.xlsx', ... 
    'IV_panelcontrol_outdoor1.xlsx', ...
    'IV_panelcontrol_outdoor2.xlsx', ...
    'IV_panelcontrol_outdoor3.xlsx'
};

outdoor_conditions = [
    184.4, 19.6;
    218.4, 22.1;  
    592.9, 46.8; 
    629.0, 48.8; 
    651.1, 51.5; 
    753.0, 52.9; 
    793.1, 50.3; 
    814.2, 52.4  
];

% --- INDOOR DATA INPUTS ---
indoor_files = {
    'IV_indoor_01Sep_G167_constT.xlsx', ...
    'TEST7_T39_IV.xlsx', ... 
    'IV_indoor_01Sep_G308_constT.xlsx', ...  
    'IV_indoor_18Sep_G340_T30.xlsx', ... 
    'iv_indoor_18Sep_G340_T42.xlsx', ...
    'iv_indoor_17Sep_G340_T38.xlsx', ...
    'IV_panelcontrol_indoor150_fanOn.xlsx', ... 
    'test1_low_iraidance_IV.xlsx', ...
    'iv_indoor_17Sep_G340_T32.xlsx', ...
    'test2_G400_IV.xlsx', ...
    'IV_indoor_01Sep_G445_constT.xlsx', ...
    'TEST3_G530_IV.xlsx', ...
    'IV_panelcontrol_indoor200_fanOn.xlsx', ... 
    'IV_panelcontrol_indoor220_fanOn.xlsx', ...
    'TEST4_G873_IV.xlsx'
};

indoor_conditions = [
    167.0, 32.4;
    220.2, 38.2;
    308.0, 34.7; 
    334.0, 30.7; 
    334.2, 42.9; 
    338.2, 38.6; 
    340.0, 36.2; 
    340.2, 32.2; 
    384.2, 31.9; 
    392.1, 33.9;
    445.0, 34.5; 
    573.9, 35.1;  
    644.2, 48.7; 
    811.8, 48.7;
    861.9, 30.9 
];

%% 2. Extrapolate I_sc at V = 0
num_outdoor = length(outdoor_files);
Isc_outdoor_raw = zeros(num_outdoor, 1);
for i = 1:num_outdoor
    data = readmatrix(outdoor_files{i});
    V = data(:, 1); I = data(:, 2);
    [V_s, idx] = sort(V, 'ascend'); I_s = I(idx);
    pts = min(N_extrap, length(V_s));
    p = polyfit(V_s(1:pts), I_s(1:pts), 1);
    Isc_outdoor_raw(i) = p(2);
end

num_indoor = length(indoor_files);
Isc_indoor_raw = zeros(num_indoor, 1);
for i = 1:num_indoor
    data = readmatrix(indoor_files{i});
    V = data(:, 1); I = data(:, 2);
    [V_s, idx] = sort(V, 'ascend'); I_s = I(idx);
    pts = min(N_extrap, length(V_s));
    p = polyfit(V_s(1:pts), I_s(1:pts), 1);
    Isc_indoor_raw(i) = p(2);
end

%% 3. Temperature Normalization (25°C STC Reference)
G_out = outdoor_conditions(:, 1); T_out = outdoor_conditions(:, 2);
G_in  = indoor_conditions(:, 1);  T_in  = indoor_conditions(:, 2);

Isc_out_norm = Isc_outdoor_raw ./ (1 + alpha_Isc * (T_out - T_ref));
Isc_in_norm  = Isc_indoor_raw  ./ (1 + alpha_Isc * (T_in - T_ref));

%% 4. Calibration Slopes (Linear Regression) & R^2 Calculation
K_outdoor = G_out \ Isc_out_norm;
K_indoor  = G_in \ Isc_in_norm;

% Calculate R^2 for Outdoor Fit
y_pred_out = K_outdoor * G_out;
SS_res_out = sum((Isc_out_norm - y_pred_out).^2);
SS_tot_out = sum((Isc_out_norm - mean(Isc_out_norm)).^2);
R2_outdoor = 1 - (SS_res_out / SS_tot_out);

% Calculate R^2 for Indoor Fit
y_pred_in = K_indoor * G_in;
SS_res_in = sum((Isc_in_norm - y_pred_in).^2);
SS_tot_in = sum((Isc_in_norm - mean(Isc_in_norm)).^2);
R2_indoor = 1 - (SS_res_in / SS_tot_in);

% Global Halogen Spectral Correction Factor
C_halogen_global = K_indoor / K_outdoor;

% Local Correction Factors per test run
C_halogen_local = (Isc_in_norm ./ G_in) / K_outdoor;

%% 5. Calculate Effective Indoor Irradiance
% Method 1: Direct PV responsivity (I_sc / K_outdoor)
G_eff_PV = Isc_in_norm / K_outdoor;

% Method 2: Scaled Pyranometer via Global Correction Factor
G_eff_Scaled = C_halogen_global * G_in;

% Residual variance between point-by-point PV value and global linear fit
residual_pct = abs(G_eff_PV - G_eff_Scaled) ./ G_eff_PV * 100;

%% 6. Display Results Summary Table
results_table = table((1:num_indoor)', G_in, T_in, Isc_indoor_raw, G_eff_PV, C_halogen_local, residual_pct, ...
    'VariableNames', {'Test_ID', 'G_pyranometer', 'Temp_C', 'Isc_extrap_A', 'G_effective_PV', 'C_halogen_local', 'Fit_Dev_Pct'});

fprintf('\n================ CALIBRATION SUMMARY ================\n');
fprintf('Outdoor Sun Responsivity (K_outdoor) : %.6f A/(W/m^2) [R^2 = %.4f]\n', K_outdoor, R2_outdoor);
fprintf('Indoor Halogen Responsivity (K_indoor): %.6f A/(W/m^2) [R^2 = %.4f]\n', K_indoor, R2_indoor);
fprintf('Global Halogen Factor (C_halogen)   : %.4f\n', C_halogen_global);
fprintf('======================================================\n\n');
disp(results_table);

%% 7. Linearity Check Plot
figure('Name', 'Irradiance Responsivity Linearity', 'Color', 'w');
plot(G_out, Isc_out_norm, 'ro', 'LineWidth', 1.5, 'MarkerSize', 7, 'DisplayName', 'Outdoor Sun Data');
hold on;
plot([0; max(G_out)], K_outdoor * [0; max(G_out)], 'r--', 'LineWidth', 1.2, 'DisplayName', sprintf('Outdoor Fit (R^2 = %.4f)', R2_outdoor));
plot(G_in, Isc_in_norm, 'bs', 'LineWidth', 1.5, 'MarkerSize', 7, 'DisplayName', 'Indoor Halogen Data');
plot([0; max(G_in)], K_indoor * [0; max(G_in)], 'b--', 'LineWidth', 1.2, 'DisplayName', sprintf('Indoor Fit (R^2 = %.4f)', R2_indoor));

xlabel('Measured Irradiance G (W/m^2)', 'FontWeight', 'bold');
ylabel('Normalized Current I_{sc,norm} (A)', 'FontWeight', 'bold');
title('Photovoltaic Current Responsivity Linearity', 'FontWeight', 'bold');
grid on; legend('Location', 'northwest');