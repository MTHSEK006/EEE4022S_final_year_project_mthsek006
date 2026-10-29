%% MATLAB Script: Temperature-Compensated Two-Curve Extraction for Rs
clear; clc; close all;

%% 1. Module Specifications & Physical Constants
Ns    = 36;            % Number of series cells
q     = 1.60217663e-19;
k     = 1.380649e-23;
n     = 1.000;         % Diode ideality factor
beta  = -0.0422;       % Temp coefficient of Voc (V/K or V/°C)

%% 2. Load Data & Operating Conditions
% Measured temperature for each file
irradiance_files = {
    'IV_indoor_01Sep_G167_constT.xlsx',...
    'IV_indoor_01Sep_G308_constT.xlsx', ...
    'IV_indoor_01Sep_G445_constT.xlsx'
};

% Operating conditions: [Irradiance (W/m^2), Measured Temperature (°C)]
op_cond = [
    167.1, 32.4;
    308, 34.7;
    445, 34.5
];

num_files = length(irradiance_files);
curves = struct('V', {}, 'I', {}, 'Isc', {}, 'Voc', {}, 'T', {});

for i = 1:num_files
    data = readmatrix(irradiance_files{i});
    validIdx = ~isnan(data(:, 1)) & ~isnan(data(:, 2));
    V_raw = data(validIdx, 1);
    I_raw = data(validIdx, 2);
    
    [V_raw, sortIdx] = sort(V_raw);
    I_raw = I_raw(sortIdx);
    
    Isc = interp1(V_raw(1:2), I_raw(1:2), 0, 'linear', 'extrap');
    
    [~, zeroI_idx] = min(abs(I_raw));
    idx1 = max(1, zeroI_idx - 1); idx2 = min(length(I_raw), zeroI_idx + 1);
    Voc = interp1(I_raw(idx1:idx2), V_raw(idx1:idx2), 0, 'linear', 'extrap');
    
    curves(i).V   = V_raw;
    curves(i).I   = I_raw;
    curves(i).Isc = Isc;
    curves(i).Voc = Voc;
    curves(i).T   = op_cond(i, 2);
end

%% 3. Temperature-Corrected Mesh Analysis for Rs
% Order curves by Isc
if curves(1).Isc < curves(2).Isc
    c1 = curves(1); c2 = curves(2);
else
    c1 = curves(2); c2 = curves(1);
end

dIsc = c2.Isc - c1.Isc;
dT   = c2.T - c1.T; % Temperature delta between tests (°C)

% 1. Temperature-correct Curve 2 Voltage to match Curve 1 temperature
% V_corr = V_measured - beta * dT
V2_corrected = c2.V - (beta * dT);

% 2. Clean current vectors for interpolation
[I1_u, idx1] = unique(c1.I, 'first');
V1_u = c1.V(idx1);

[I2_u, idx2] = unique(c2.I, 'first');
V2_u = V2_corrected(idx2);

[I1_s, s1] = sort(I1_u); V1_s = V1_u(s1);
[I2_s, s2] = sort(I2_u); V2_s = V2_u(s2);

% 3. Evaluate Voltage Delta near Open Circuit (V > 0.8*Voc) where mesh shift holds
I_target_min = 0.05 * c1.Isc;
I_target_max = 0.60 * c1.Isc;

target_currents = linspace(I_target_min, I_target_max, 50);

V1_eval = interp1(I1_s, V1_s, target_currents, 'linear');
V2_eval = interp1(I2_s, V2_s, target_currents, 'linear');

% Thermal voltage term correction: dV_diode = n*Vt*ln(Isc2/Isc1)
Vt = (Ns * n * k * (c1.T + 273.15)) / q;
dV_diode = Vt * log(c2.Isc / c1.Isc);

% Corrected Voltage Delta attributable strictly to Rs
dV_measured = V2_eval - V1_eval;
Rs_array = (dV_measured - dV_diode) / dIsc;

% Filter valid physical range (0.01 to 2.0 Ohms)
valid_Rs = Rs_array(Rs_array > 0.01 & Rs_array < 2.0 & ~isnan(Rs_array));

if ~isempty(valid_Rs)
    Rs_mesh_corrected = mean(valid_Rs);
else
    % Fallback to point evaluation at I = 0 (Voc delta method)
    dV_oc = (c2.Voc - (beta*dT)) - c1.Voc;
    Rs_mesh_corrected = max(0.1, (dV_oc - dV_diode) / dIsc);
end

%% 4. Results Display
fprintf('\n=======================================================\n');
fprintf('Temperature-Compensated Two-Curve Mesh Analysis:\n');
fprintf('Temperature Delta (dT)      : %.2f °C\n', dT);
fprintf('Diode Thermal Voltage Shift : %.4f V\n', dV_diode);
fprintf('Extracted Physical Rs       : %.5f Ohms\n', Rs_mesh_corrected);
fprintf('=======================================================\n');


%% 5. Calculate Shunt Resistance (Rsh) using Low-Voltage Slope Fitting
% Near V = 0 (V <= 5 V) the slope is set by shunt leakage: Rsh = -1/(dI/dV)

Rsh_values = zeros(num_files, 1);

for i = 1:num_files
    % Extract region near V = 0 V (V <= 5 V)
    flat_idx = curves(i).V <= 5.0;

    if sum(flat_idx) >= 2
        p = polyfit(curves(i).V(flat_idx), curves(i).I(flat_idx), 1);
        slope_dI_dV = p(1);
    else
        % Fallback to first 3 points if fewer than 2 points fall under 5 V
        p = polyfit(curves(i).V(1:3), curves(i).I(1:3), 1);
        slope_dI_dV = p(1);
    end

    % Rsh is the inverse negative slope
    if slope_dI_dV < 0
        Rsh_values(i) = -1 / slope_dI_dV;
    else
        % If noise gives a positive/zero slope, fallback to two-point slope
        Rsh_values(i) = -1 / ((curves(i).I(2) - curves(i).I(1)) / (curves(i).V(2) - curves(i).V(1)));
    end
end

Rsh_final = mean(Rsh_values);

%% 6. Display Results Table
summary_table = table((1:num_files)', [curves.Isc]', [curves.Voc]', Rsh_values, ...
    'VariableNames', {'Curve_Num', 'Extrap_Isc_A', 'Extrap_Voc_V', 'Rsh_ohms'});

fprintf('\n================ PARAMETER EXTRACTION RESULTS ================\n');
fprintf('Average Shunt Resistance (Rsh - Low-V Fit) : %.2f Ω\n', Rsh_final);
fprintf('==============================================================\n\n');
disp(summary_table);