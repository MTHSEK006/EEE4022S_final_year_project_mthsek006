%% MATLAB Script: A/B Comparative EIS Analysis (Nyquist overlay and Randles refit)
clear; clc; close all;

%% --- 1. INPUTS ---
% RUN 1 (Reference / Healthy baseline)
file_params_1 = 'EIS_22Sep_indoor_healthy_OPX70_R01_PARAMS.xlsx';
file_raw_1    = 'EIS_22Sep_indoor_healthy_OPX70_R01.xlsx';
label_1       = 'Healthy baseline';
G_1           = 296.22;   % Irradiance (W/m^2)
T_1           = 43.17;    % Temperature (°C)

% RUN 2 (Comparison / Shaded / Low Irradiance)
file_params_2 = 'EIS_22Sep_indoor_PS50_cell52_OPX70_R01_PARAMS.xlsx';
file_raw_2    = 'EIS_22Sep_indoor_PS50_cell52_OPX70_R01.xlsx';
label_2       = 'Partial Shading 50% ';
G_2           = 296.22;   % Irradiance (W/m^2)
T_2           = 43.17;    % Temperature (°C)

fprintf('====================================================\n');
fprintf('   DIRECT EIS COMPARATIVE ANALYSIS\n');
fprintf('====================================================\n');
fprintf('%s -> G = %.1f W/m^2, T = %.2f degC\n', label_1, G_1, T_1);
fprintf('%s -> G = %.1f W/m^2, T = %.2f degC\n', label_2, G_2, T_2);

%% --- 2. PARAMETERS: NOVA VALUES AND REFIT FROM THE MEASURED ARC ---
nova1 = read_nova_params(file_params_1);
nova2 = read_nova_params(file_params_2);
[w1, Z1] = read_raw(file_raw_1);
[w2, Z2] = read_raw(file_raw_2);
p1 = refit_randles(w1, Z1, nova1);
p2 = refit_randles(w2, Z2, nova2);

fprintf('\n------------- NOVA CIRCLE-FIT PARAMETERS -------------\n');
print_table(nova1, nova2, label_1, label_2);
fprintf('\n------------- REFITTED RANDLES PARAMETERS -------------\n');
print_table(p1, p2, label_1, label_2);
fprintf('Characteristic frequency fc: %s = %.0f Hz, %s = %.0f Hz\n', ...
        label_1, p1.fc, label_2, p2.fc);

%% --- 3. OVERLAY NYQUIST PLOT ---
figure('Name', 'A/B Nyquist Comparison', 'Position', [100, 100, 900, 650]);
hold on; grid on; box on;
plot_nyquist_run(w1, Z1, p1, label_1, 'b', 1.5);
plot_nyquist_run(w2, Z2, p2, label_2, 'r', 1.5);
xlabel('Z'' (\Omega)', 'FontSize', 12);
ylabel('Z'''' (\Omega)', 'FontSize', 12);
title(sprintf('Overlay Nyquist Comparison:\n%s vs %s', label_1, label_2), 'FontSize', 13);
legend('Location', 'best', 'FontSize', 9);
% Axis limits from the capacitive data of both runs
Zc = [Z1(-imag(Z1) > 0); Z2(-imag(Z2) > 0)];
xr = [min(real(Zc)), max(real(Zc))];
xlim([xr(1) - 0.05*diff(xr), xr(2) + 0.05*diff(xr)]);
ylim([0, 1.15*max(-imag(Zc))]);
hold off;

%% --- HELPER FUNCTIONS ---
function p = read_nova_params(filename)
if ~isfile(filename), error('Parameter file %s not found!', filename); end
row = readmatrix(filename, 'Range', 'G2:J2');
p.Q = row(1); p.Rct = row(2); p.Rs = row(3); p.alpha = row(4);
p.fc = 1/(2*pi*(p.Rct*p.Q)^(1/p.alpha));
end

function [w, Z] = read_raw(raw_file)
if ~isfile(raw_file), error('Raw impedance file %s not found!', raw_file); end
T = readtable(raw_file, detectImportOptions(raw_file));
Zre    = T{:, 1};            % Z' (Ohm)
negZim = T{:, 3};            % -Z'' (Ohm)
w      = T{:, 8};            % omega (rad/s)
Z      = Zre - 1i*negZim;
end

function Z = randles(p, w)
Zcpe = 1 ./ (p.Q * (1i*w).^p.alpha);
Z = p.Rs + (p.Rct .* Zcpe) ./ (p.Rct + Zcpe);
end

function p = refit_randles(w, Z, p0)
% Fit Rs, Rct, Q, alpha to the capacitive arc only (-Z'' > 0)
use = -imag(Z) > 0;
% Starting value for Q from the apex of the measured arc
[~, k] = max(-imag(Z) .* use);
Q0 = 1 / (p0.Rct * w(k)^p0.alpha);
x0 = [p0.Rs, p0.Rct, log10(Q0), p0.alpha];
model = @(x, ww) x(1) + x(2) ./ (1 + x(2) * 10^x(3) * (1i*ww).^x(4));
cost  = @(x) sum(abs((model(x, w(use)) - Z(use)) ./ abs(Z(use))).^2) ...
             + 1e3*max(0, x(4) - 1)^2;          % keep alpha <= 1
opts = optimset('MaxFunEvals', 2e4, 'MaxIter', 2e4, 'TolX', 1e-10, 'TolFun', 1e-14);
x = fminsearch(cost, x0, opts);
p.Rs = x(1); p.Rct = x(2); p.Q = 10^x(3); p.alpha = x(4);
p.fc = 1/(2*pi*(p.Rct*p.Q)^(1/p.alpha));
end

function print_table(a, b, la, lb)
fprintf('%-10s | %-24s | %-24s | %-10s\n', 'Parameter', la, lb, 'Delta (%)');
fprintf('%s\n', repmat('-', 1, 78));
names = {'Rct (Ohm)', 'Rs (Ohm)', 'Q (F)', 'alpha'};
fld   = {'Rct', 'Rs', 'Q', 'alpha'};
for k = 1:4
    v1 = a.(fld{k}); v2 = b.(fld{k});
    fprintf('%-10s | %24.6g | %24.6g | %+9.1f%%\n', names{k}, v1, v2, (v2 - v1)/v1*100);
end
end

function plot_nyquist_run(w, Z, p, label_str, col, line_width)
cap = -imag(Z) > 0;
% Measured capacitive points (the arc)
plot(real(Z(cap)), -imag(Z(cap)), 'o', 'MarkerSize', 4, ...
     'MarkerEdgeColor', col, 'MarkerFaceColor', 'none', ...
     'DisplayName', [label_str ' (measured)']);
% Fitted arc on a dense frequency grid
w_fit = 2*pi*logspace(-1, 6, 400)';
Z_fit = randles(p, w_fit);
Z_fit = Z_fit(-imag(Z_fit) >= 0);                % keep the arc above the axis
plot(real(Z_fit), -imag(Z_fit), '-', 'Color', col, 'LineWidth', line_width, ...
     'DisplayName', [label_str ' (fitted arc)']);
end
