%% MATLAB Script: Overlay PV & IV Curves on the Same Axis (Voc at I = 0)
clear; clc; close all;

%% 1. Specify Input Excel Files 
% Excel files in second sub-string from col 3 row 1-11 to col 2 1-6 
excel_files = {
    'BAELINE_indoors_08Oct.xlsx', ...
    'BASELINE_TAKE2_indoors_08Oct.xlsx',...
    'IV_PS_COL1ROW1_75%_indoors_08Oct.xlsx',...
    'IV_PS_COL2ROW1_75%_indoors_08Oct.xlsx',...
    'IV_PS_COL3ROW1_75%_indoors_08Oct.xlsx',...
    'IV_PS_COL2ROW6_75%_indoors_08Oct.xlsx'
};  

num_files = length(excel_files);

%% 2. Figure Setup
figure('Name', 'I-V Curve Overlay Comparison', ...
       'Color', [1 1 1], ...
       'Position', [100, 100, 950, 600]);

hold on; grid on; box on;

% Define distinct color map for each file
colors = lines(num_files);

% Pre-allocate global limits for axes adjustment
max_V_global = 0;
max_I_global = 0;

%% 3. Processing and Plotting Loop
for i = 1:num_files
    file_name = excel_files{i};
    
    % Read data from Excel file
    try
        data = readmatrix(file_name);
    catch ME
        warning('Could not read file: %s. Error: %s', file_name, ME.message);
        continue;
    end
    
    % Check if file has at least 8 columns
    if size(data, 2) < 8
        warning('File %s does not have at least 8 columns. Skipping...', file_name);
        continue;
    end
    
    % Extract Column 6 (Voltage), Column 7 (Current), and Column 8 (Power)
    V = data(:, 6);
    I = data(:, 7);
    P = data(:, 8);
    
    % Filter out NaN or missing values across all three signals
    valid_idx = ~isnan(V) & ~isnan(I) & ~isnan(P);
    V = V(valid_idx);
    I = I(valid_idx);
    P = P(valid_idx);
    
    if isempty(V) || isempty(I)
        continue;
    end
    
    % Sort by Voltage for clean line plotting
    [V, sort_idx] = sort(V);
    I = I(sort_idx);
    P = P(sort_idx);
    
    % =====================================================================
    % CALCULATE Voc WHERE I = 0 A
    % =====================================================================
    % Method A: Exact zero match
    zero_I_idx = find(I == 0, 1);
    
    if ~isempty(zero_I_idx)
        Voc = V(zero_I_idx);
    else
        % Method B: Linear interpolation at I = 0 A (requires unique current values)
        [unique_I, unique_idx] = unique(I, 'stable');
        unique_V = V(unique_idx);
        
        if min(unique_I) <= 0 && max(unique_I) >= 0
            Voc = interp1(unique_I, unique_V, 0, 'linear');
        else
            % Fallback Method C: Nearest value to I = 0 A
            [~, min_I_idx] = min(abs(I));
            Voc = V(min_I_idx);
        end
    end
    % =====================================================================
    
    % Locate Maximum Power Point (MPP)
    [Pmp, mpp_idx] = max(P);
    Vmp = V(mpp_idx);
    Imp = I(mpp_idx);
    
    % Track global maximums for plot scaling
    max_V_global = max(max_V_global, max(V));
    max_I_global = max(max_I_global, max(I));
    
    % Format clean label for the legend
    [~, clean_label, ~] = fileparts(file_name);
    clean_label = strrep(clean_label, '_', ' ');
    
    % Plot I-V Curve with Voc (at I=0), Imp, and Pmp in legend
    legend_str = sprintf('%s (V_{oc} = %.2f V, I_{mp} = %.2f A, P_{mp} = %.1f W)', ...
                         clean_label, Voc, Imp, Pmp);
                     
    plot(V, I, 'LineWidth', 2, 'Color', colors(i, :), 'DisplayName', legend_str);
    
    % Highlight MPP Operating Point
    plot(Vmp, Imp, 'o', 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', 'k', ...
        'MarkerSize', 6, 'HandleVisibility', 'off');
    
    % Highlight Voc (I = 0) Point on x-axis
    plot(Voc, 0, 's', 'MarkerFaceColor', colors(i, :), 'MarkerEdgeColor', 'k', ...
        'MarkerSize', 6, 'HandleVisibility', 'off');
end

%% 4. Format Axes & Labels
xlabel('Voltage (V)', 'FontWeight', 'bold', 'FontSize', 11);
ylabel('Current (A)', 'FontWeight', 'bold', 'FontSize', 11);
title('I-V Curve PANEL CONTROL INDOORS', 'FontSize', 13, 'FontWeight', 'bold');

% Configure Legend
legend('Location', 'northeastoutside', 'FontSize', 9, 'Interpreter', 'tex');

% Apply plot limits
if max_V_global > 0 && max_I_global > 0
    xlim([0, max_V_global * 1.05]);
    ylim([0, max_I_global * 1.1]);
end

hold off;