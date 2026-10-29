%% MATLAB Script: Individual, Combined, and Extrapolated IV Curves
clear; clc; close all;

% =========================================================================
% 1. USER INPUT: List your separate Excel file names
% =========================================================================
excelFiles = { ...
    'baseline_12h00.xlsx', ...          % File 1
    'IV_PS_col1row1_paper.xlsx' ,...    % File 2
    'IV_PS_col2row1_paper.xlsx' ,...  
    'IV_PS_col3row1_paper.xlsx' ,...  
    'IV_PS_col1row1_cardboard.xlsx',...
    'IV_PS_col1row1_paper_50%.xlsx'
   
    };
numFiles = length(excelFiles);
colors = lines(numFiles); % Generate distinct colors for each file

% Initialize Summary Table
fprintf('====================================================================================\n');
fprintf('%-30s | %-12s | %-12s | %-12s\n', 'File Name', 'Extrap. Isc(A)', 'Voc (V)', 'Pmp (W)');
fprintf('====================================================================================\n');

% Initialize Combined Figures
combinedFig1 = figure('Name', 'Combined Measured I-V Curves', 'Color', 'w', ...
    'Position', [100, 100, 950, 650]);
figure(combinedFig1); hold on; grid on; box on;

combinedFig2 = figure('Name', 'Combined Extrapolated I-V Curves', 'Color', 'w', ...
    'Position', [150, 150, 950, 650]);
figure(combinedFig2); hold on; grid on; box on;

% =========================================================================
% 2. LOOP THROUGH EACH EXCEL FILE & PLOT FIGURES
% =========================================================================
for i = 1:numFiles
    currentFile = excelFiles{i};
    [~, shortName, ext] = fileparts(currentFile);
    
    % --- Read Data (Defaults to 1st Sheet automatically) ---
    opts = detectImportOptions(currentFile);
    opts.VariableNamingRule = 'preserve';
    data = readtable(currentFile, opts);
    
    % Extract Voltage (Column 2) and Current (Column 3)
    rawV = data{:, 2};
    rawI = data{:, 3};
    validIdx = ~isnan(rawV) & ~isnan(rawI);
    V_meas = rawV(validIdx);
    I_meas = rawI(validIdx);
    
    % Sort measured points by voltage ascending
    [V_meas, sortIdx] = sort(V_meas);
    I_meas = I_meas(sortIdx);
    
    % --- Key Electrical Parameter Extractions ---
    % 1. Voc (Measured Open-Circuit Voltage)
    Voc_meas = max(V_meas);
    
    % 2. Pmp, Vmp, Imp (Maximum Power Point)
    P_meas = V_meas .* I_meas;
    [Pmp_meas, maxP_idx] = max(P_meas);
    Vmp_meas = V_meas(maxP_idx);
    Imp_meas = I_meas(maxP_idx);
    
    % 3. Extrapolate Short-Circuit Current (Isc at V = 0)
    numLowPoints = min(4, length(V_meas));
    p_Isc = polyfit(V_meas(1:numLowPoints), I_meas(1:numLowPoints), 1);
    
    V_sc_extrap = 0;
    I_sc_extrap = polyval(p_Isc, V_sc_extrap); % Isc at V = 0
    
    % Print summary stats to Command Window
    fprintf('%-30s | %-12.4f | %-12.4f | %-12.4f\n', [shortName, ext], I_sc_extrap, Voc_meas, Pmp_meas);
    
    % Prepare Extrapolation Line segment for Isc (from V = 0 to first few points)
    V_low_line = linspace(0, V_meas(numLowPoints), 20);
    I_low_line = polyval(p_Isc, V_low_line);
    
    curveColor = colors(i, :);
    
    % ---------------------------------------------------------------------
    % A. PLOT INDIVIDUAL FIGURE FOR THIS SPECIFIC FILE
    % ---------------------------------------------------------------------
    indivFig = figure('Name', sprintf('IV Curve - %s', shortName), 'Color', 'w', ...
        'Position', [200 + (i*25), 200 - (i*10), 750, 500]);
    figure(indivFig);
    hold on; grid on; box on;
    
    plot(V_meas, I_meas, '-o', 'Color', curveColor, 'LineWidth', 1.8, ...
        'MarkerSize', 6, 'MarkerFaceColor', curveColor, 'DisplayName', 'Measured Data');
    plot(V_low_line, I_low_line, 'r--', 'LineWidth', 1.2, 'DisplayName', 'I_{sc} Linear Fit');
    plot(V_sc_extrap, I_sc_extrap, 'r^', 'MarkerSize', 9, 'MarkerFaceColor', 'r', ...
        'DisplayName', sprintf('Extrapolated I_{sc} = %.2f A', I_sc_extrap));
    plot(Vmp_meas, Imp_meas, 'kp', 'MarkerSize', 10, 'MarkerFaceColor', 'y', ...
        'DisplayName', sprintf('P_{mp} = %.2f W', Pmp_meas));
    
    xlabel('Voltage (V)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Current (A)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('I-V Curve: %s (V_{oc}=%.2fV, P_{mp}=%.2fW)', shortName, Voc_meas, Pmp_meas), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'none');
    legend('Location', 'northeast', 'FontSize', 9);
    hold off;
    
    % ---------------------------------------------------------------------
    % B. FIGURE 1: COMBINED MEASURED IV CURVES (WITH Voc & Pmp IN LEGEND)
    % ---------------------------------------------------------------------
    figure(combinedFig1);
    
    % Label string with Voc, Pmp, and Extrapolated Isc
    legLabel = sprintf('%s | V_{oc}=%.2fV | P_{mp}=%.2fW | I_{sc}=%.2fA', ...
        shortName, Voc_meas, Pmp_meas, I_sc_extrap);
    
    % Plot measured curve
    plot(V_meas, I_meas, '-o', 'Color', curveColor, 'LineWidth', 1.8, ...
        'MarkerSize', 5, 'MarkerFaceColor', curveColor, 'DisplayName', legLabel);
    
    % Mark Pmp on the combined plot
    plot(Vmp_meas, Imp_meas, 'kp', 'MarkerSize', 9, 'MarkerFaceColor', 'y', 'HandleVisibility', 'off');
    
    % ---------------------------------------------------------------------
    % C. FIGURE 2: COMBINED EXTRAPOLATED IV CURVES
    % ---------------------------------------------------------------------
    figure(combinedFig2);
    
    % Create full continuous voltage vector including 0V for complete extrapolated curve display
    V_full = [V_sc_extrap; V_meas];
    I_full = [I_sc_extrap; I_meas];
    
    % Plot main curve
    plot(V_meas, I_meas, '-', 'Color', curveColor, 'LineWidth', 1.8, 'DisplayName', shortName);
    
    % Plot dashed extrapolation line connecting 0V to the measured dataset
    plot([0, V_meas(1)], [I_sc_extrap, I_meas(1)], '--', 'Color', curveColor, ...
        'LineWidth', 1.5, 'HandleVisibility', 'off');
    
    % Mark Extrapolated Isc point at V = 0
    plot(V_sc_extrap, I_sc_extrap, '^', 'Color', curveColor, 'MarkerSize', 8, ...
        'MarkerFaceColor', curveColor, 'HandleVisibility', 'off');
end

% =========================================================================
% 3. FORMAT COMBINED FIGURES
% =========================================================================
% Format Combined Measured Plot
figure(combinedFig1);
xlabel('Voltage (V)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Current (A)', 'FontSize', 12, 'FontWeight', 'bold');
title('Combined Measured I-V Characteristics (with V_{oc} & P_{mp})', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 8, 'Interpreter', 'none');

% Format Combined Extrapolated Plot
figure(combinedFig2);
xlabel('Voltage (V)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Current (A)', 'FontSize', 12, 'FontWeight', 'bold');
title('Combined Extrapolated I-V Characteristics (I_{sc} at V = 0 V)', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northeast', 'FontSize', 9, 'Interpreter', 'none');

fprintf('====================================================================================\n');