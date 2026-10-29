%% MATLAB Script: Parameter Extraction (n, I0, and I0_stc) from Variable Temp Curves
clear; clc; close all;

%% 1. Module Specifications & Physical Constants
Ns    = 36;             % Number of cells in series
q     = 1.60217663e-19; % Electron charge (C)
k     = 1.380649e-23;   % Boltzmann constant (J/K)
Eg    = 1.12;           % Silicon bandgap energy (eV)
T_stc = 298.15;         % Standard Test Condition Temperature (25°C in Kelvin)

%% 2. User Inputs: Excel Files & Temperature Matrix
temp_files = {
    'IV_indoor_18Sep_G340_T30.xlsx', ...
    'iv_indoor_17Sep_G340_T32.xlsx', ...
    'iv_indoor_17Sep_G340_T38.xlsx', ...
    'iv_indoor_18Sep_G340_T42.xlsx'
};

% Corresponding measured cell temperatures in Celsius (°C)
T_Celsius = [30.7, 32.2, 38.6, 42.9]; 
T_Kelvin  = T_Celsius.' + 273.15; % Convert to Kelvin

%% 3. Load Excel Files & Extract Voc and Iph per Curve
num_files = length(temp_files);
Voc_measured = zeros(num_files, 1);
Iph_measured = zeros(num_files, 1);

for i = 1:num_files
    data = readmatrix(temp_files{i});
    
    % Filter out NaNs
    validIdx = ~isnan(data(:, 1)) & ~isnan(data(:, 2));
    V = data(validIdx, 1);
    I = data(validIdx, 2);
    
    % Sort by Voltage
    [V, sortIdx] = sort(V);
    I = I(sortIdx);
    
    % Extract Iph (Isc) near V = 0 using interp1 extrapolation
    Iph_measured(i) = interp1(V(1:2), I(1:2), 0, 'linear', 'extrap');
    
    % Extract Voc near I = 0 using linear interpolation
    [~, zeroI_idx] = min(abs(I));
    if zeroI_idx == 1
        idx1 = 1; idx2 = 2;
    elseif zeroI_idx == length(I)
        idx1 = length(I) - 1; idx2 = length(I);
    else
        idx1 = zeroI_idx - 1; idx2 = zeroI_idx + 1;
    end
    Voc_measured(i) = interp1(I(idx1:idx2), V(idx1:idx2), 0, 'linear', 'extrap');
end

% Calculate Average Photocurrent across all curves
Iph_avg = mean(Iph_measured);

%% 4. Linear Regression of Voc vs Temperature
p = polyfit(T_Kelvin, Voc_measured, 1);
slope_dVoc_dT = p(1); % dVoc/dT (V/K)

%% 5. Extract Diode Ideality Factor (n) and Saturation Current I0(T)
T_avg = mean(T_Kelvin);
Vt_cell_avg = (k * T_avg) / q;

% Extract ideality factor (n)
dVoc_cell_dT = slope_dVoc_dT / Ns;
n_extracted  = abs(dVoc_cell_dT) / (Vt_cell_avg / T_avg * log(Iph_avg / 1e-9));
n_extracted  = max(1.0, min(2.0, n_extracted)); % Constrain to physical limits [1, 2]

% Calculate I0 for each experimental curve
I0_extracted = zeros(num_files, 1);
for i = 1:num_files
    Vt_module = (Ns * n_extracted * k * T_Kelvin(i)) / q;
    I0_extracted(i) = Iph_avg / (exp(Voc_measured(i) / Vt_module) - 1);
end

%% 6. Calculate I0_stc (Reverse Saturation Current at 25°C / 298.15K)

% Method A: Direct Inversion per Temperature Point
I0_stc_array = zeros(num_files, 1);
for i = 1:num_files
    T_k = T_Kelvin(i);
    temp_ratio = (T_k / T_stc)^3;
    exp_factor = exp((q * Eg / (n_extracted * k)) * ((1 / T_stc) - (1 / T_k)));
    
    I0_stc_array(i) = I0_extracted(i) / (temp_ratio * exp_factor);
end
I0_stc_direct = mean(I0_stc_array);

% Method B: Arrhenius Regression Fit (ln(I0/T^3) vs 1/T)
x_arr = 1 ./ T_Kelvin;
y_arr = log(I0_extracted ./ (T_Kelvin.^3));
p_arr = polyfit(x_arr, y_arr, 1);

y_stc = polyval(p_arr, 1 / T_stc);
I0_stc_arrhenius = exp(y_stc) * (T_stc^3);

%% 7. Display Results Table
results_table = table((1:num_files)', T_Celsius(:), Iph_measured, Voc_measured, I0_extracted, I0_stc_array, ...
    'VariableNames', {'Curve_Num', 'Temp_degC', 'Iph_measured_A', 'Voc_measured_V', 'I0_extracted_A', 'I0_stc_point_A'});

fprintf('\n================ PARAMETER EXTRACTION RESULTS ================\n');
fprintf('Series Cell Count (Ns)                   : %d cells\n', Ns);
fprintf('Average Photocurrent (Iph_avg)            : %.4f A\n', Iph_avg);
fprintf('Temperature Voltage Coefficient (dVoc/dT) : %.4f V/K\n', slope_dVoc_dT);
fprintf('Extracted Diode Ideality Factor (n)       : %.3f\n', n_extracted);
fprintf('--------------------------------------------------------------\n');
fprintf('Calculated I0_stc (Direct Inversion Mean) : %.4e A\n', I0_stc_direct);
fprintf('Calculated I0_stc (Arrhenius Fit Method)  : %.4e A\n', I0_stc_arrhenius);
fprintf('==============================================================\n\n');
disp(results_table);

%% 8. Plotting Fits
figure('Name', 'Parameter Extraction and I0_stc Fits', 'Color', [1 1 1]);

% Plot 1: Voc vs Temperature
subplot(1, 2, 1);
plot(T_Celsius, Voc_measured, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', 'Measured Voc');
hold on;
plot(T_Celsius, polyval(p, T_Kelvin), 'b--', 'LineWidth', 1.2, 'DisplayName', 'Linear Fit');
xlabel('Cell Temperature T (°C)', 'FontWeight', 'bold');
ylabel('Open-Circuit Voltage V_{oc} (V)', 'FontWeight', 'bold');
title('V_{oc} Temperature Dependency', 'FontWeight', 'bold');
grid on; legend('Location', 'northeast');

% Plot 2: Arrhenius Plot for I0_stc Extraction
subplot(1, 2, 2);
plot(x_arr, y_arr, 'ks', 'MarkerSize', 8, 'LineWidth', 1.5, 'DisplayName', 'Data Points');
hold on;
plot(x_arr, polyval(p_arr, x_arr), 'r-', 'LineWidth', 1.2, 'DisplayName', 'Arrhenius Fit');
plot(1/T_stc, y_stc, 'gp', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'DisplayName', 'STC Point (25°C)');
xlabel('1 / Temperature (1/K)', 'FontWeight', 'bold');
ylabel('ln(I_0 / T^3)', 'FontWeight', 'bold');
title('Arrhenius Fit for I_{0,stc}', 'FontWeight', 'bold');
grid on; legend('Location', 'best');