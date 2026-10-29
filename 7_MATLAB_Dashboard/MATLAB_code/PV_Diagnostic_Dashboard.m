function PV_Diagnostic_Dashboard()
    % Clear workspace and close existing figures
    clear; clc; close all;
    % Create Main Dashboard Window
    fig = uifigure('Name', 'PV Digital Twin & EIS Shading Diagnostic Dashboard', ...
                   'Position', [50, 50, 1350, 850], 'Color', [0.94 0.94 0.94]);
    
    % Initialize figure UserData structure for cross-stage data sharing
    fig.UserData = struct('has_anomaly', false, 'sres_Isc', 0, 'sres_Pmp', 0, 'G', 0, 'T', 0);
    %% =====================================================================
    %% UI LAYOUT: PANELS & CONTROLS
    %% =====================================================================
    
    % --- AXES 1: I-V / P-V Plot Panel (Top Right) ---
    ax_iv_panel = uipanel(fig, 'Title', 'Macro I-V & P-V Curve Comparison', 'Position', [460, 440, 870, 390], 'FontSize', 12, 'FontWeight', 'bold');
    ax_iv = uiaxes(ax_iv_panel, 'Position', [40, 40, 360, 310]);
    ax_pv = uiaxes(ax_iv_panel, 'Position', [460, 40, 360, 310]);
    
    % --- AXES 2: Nyquist Overlay Plot Panel (Bottom Right) ---
    ax_eis_panel = uipanel(fig, 'Title', 'EIS Nyquist Spectrum Overlay', 'Position', [460, 20, 870, 405], 'FontSize', 12, 'FontWeight', 'bold');
    ax_nyquist = uiaxes(ax_eis_panel, 'Position', [180, 40, 520, 320]);
    
    % --- PANEL 1: Macro I-V Input & Analysis ---
    panel_iv = uipanel(fig, 'Title', 'Step 1: Macro I-V Digital Twin Check', ...
                    'Position', [20, 440, 420, 390], 'FontSize', 12, 'FontWeight', 'bold');
                
    uilabel(panel_iv, 'Position', [15, 330, 100, 22], 'Text', 'I-V Excel File:');
    txt_iv_file = uieditfield(panel_iv, 'text', 'Value', 'IV_02Oct_indoor_healthy_R01.xlsx', 'Position', [120, 330, 200, 22]);
    uibutton(panel_iv, 'Position', [330, 330, 70, 22], 'Text', 'Browse', ...
        'ButtonPushedFcn', @(~,~) browseIVFile(txt_iv_file));
    
    uilabel(panel_iv, 'Position', [15, 290, 100, 22], 'Text', 'Irradiance G (W/m²):');
    txt_G = uieditfield(panel_iv, 'numeric', 'Value', 390.3, 'Position', [120, 290, 80, 22]);
    
    uilabel(panel_iv, 'Position', [210, 290, 100, 22], 'Text', 'Temp T (°C):');
    txt_T = uieditfield(panel_iv, 'numeric', 'Value', 39.4, 'Position', [290, 290, 80, 22]);
    
    uilabel(panel_iv, 'Position', [15, 200, 100, 22], 'Text', 'Diagnostic Status:', 'FontWeight', 'bold');
    lbl_status = uilabel(panel_iv, 'Position', [120, 200, 280, 22], 'Text', 'Awaiting Execution...', 'FontWeight', 'bold', 'FontColor', [0.5 0.5 0.5]);
    
    txt_results = uitextarea(panel_iv, 'Position', [15, 15, 385, 175], 'Editable', 'off');
    txt_results.Value = {'[System Ready] Load file and click run to compute residuals.'};
    
    % --- PANEL 2: EIS Fast-Analysis & Shading Detection ---
    panel_eis = uipanel(fig, 'Title', 'Step 2: EIS Shading Micro-Diagnosis (Nyquist Overlay)', ...
                    'Position', [20, 20, 420, 405], 'FontSize', 12, 'FontWeight', 'bold');
                
    uilabel(panel_eis, 'Position', [15, 335, 120, 22], 'Text', 'Reference Params:');
    txt_p1 = uieditfield(panel_eis, 'text', 'Value', 'EIS_02Oct_indoor_healthy_OPX70_R01_PARAMS.xlsx', 'Position', [140, 335, 180, 22]);
    uibutton(panel_eis, 'Position', [330, 335, 70, 22], 'Text', 'Browse', 'ButtonPushedFcn', @(~,~) browseFile(txt_p1));
    
    uilabel(panel_eis, 'Position', [15, 300, 120, 22], 'Text', 'Reference Raw (Nyquist):');
    txt_r1 = uieditfield(panel_eis, 'text', 'Value', 'EIS_02Oct_indoor_healthy_OPX70_R01.xlsx', 'Position', [140, 300, 180, 22]);
    uibutton(panel_eis, 'Position', [330, 300, 70, 22], 'Text', 'Browse', 'ButtonPushedFcn', @(~,~) browseFile(txt_r1));
    
    uilabel(panel_eis, 'Position', [15, 250, 120, 22], 'Text', 'Test Params:');
    txt_p2 = uieditfield(panel_eis, 'text', 'Value', 'EIS_02Oct_indoor_PS75_cell31_OPX70_R01_PARAMS.xlsx', 'Position', [140, 250, 180, 22]);
    uibutton(panel_eis, 'Position', [330, 250, 70, 22], 'Text', 'Browse', 'ButtonPushedFcn', @(~,~) browseFile(txt_p2));
    
    uilabel(panel_eis, 'Position', [15, 215, 120, 22], 'Text', 'Test Raw (Nyquist):');
    txt_r2 = uieditfield(panel_eis, 'text', 'Value', 'EIS_02Oct_indoor_PS75_cell31_OPX70_R01.xlsx', 'Position', [140, 215, 180, 22]);
    uibutton(panel_eis, 'Position', [330, 215, 70, 22], 'Text', 'Browse', 'ButtonPushedFcn', @(~,~) browseFile(txt_r2));
    
    txt_eis_verdict = uitextarea(panel_eis, 'Position', [15, 15, 385, 140], 'Editable', 'off');
    txt_eis_verdict.Value = {'Stage 1 pending...'};
    
    % Create EIS button initially disabled (greyed out)
    btn_run_eis = uibutton(panel_eis, 'Position', [15, 165, 385, 35], ...
        'Text', 'NO NEED FOR EIS', ...
        'BackgroundColor', [0.7 0.7 0.7], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @(~,~) runEISAnalysis(txt_p1, txt_r1, txt_p2, txt_r2, ax_nyquist, txt_eis_verdict, fig));

    % Step 1 Run Button
    btn_run_iv = uibutton(panel_iv, 'Position', [15, 240, 385, 35], ...
        'Text', 'Run Macro I-V & Check Residuals', ...
        'BackgroundColor', [0.0 0.45 0.74], 'FontColor', [1 1 1], 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) runMacroIV(txt_iv_file, txt_G, txt_T, lbl_status, txt_results, ax_iv, ax_pv, fig, btn_run_eis, txt_eis_verdict));
end

%% =====================================================================
%% CALLBACK FUNCTIONS & CORE LOGIC
%% =====================================================================
function browseIVFile(txtField)
    [file, path] = uigetfile({'*.xlsx'; '*.xls'}, 'Select Measured I-V Excel File');
    if file ~= 0
        txtField.Value = fullfile(path, file);
    end
end

function browseFile(txtField)
    [file, path] = uigetfile({'*.xlsx'; '*.xls'; '*.csv'}, 'Select File');
    if file ~= 0
        txtField.Value = fullfile(path, file);
    end
end

function runMacroIV(txtFile, txtG, txtT, lblStatus, txtResults, ax_iv_plot, ax_pv_plot, fig, btn_eis, txt_eis_verdict)
    file_path = txtFile.Value;
    G_raw = txtG.Value;
    T_C = txtT.Value;
    
    if ~isfile(file_path)
        uialert(ancestor(txtFile, 'figure'), 'Excel file not found!', 'File Error');
        return;
    end
    
    % SDM Parameters
    sdm_params.Ns           = 36;              
    sdm_params.n            = 1.000;           
    sdm_params.I0_STC       = 4.0491e-11;      
    sdm_params.Rs_macro     = 0.13043;         
    sdm_params.Rsh_macro    = 1721.41;         
    sdm_params.Isc_STC      = 4.76;            
    sdm_params.Voc_STC      = 21.6;            
    sdm_params.alpha_Isc    = 0.0005;          
    sdm_params.alpha_Isc_rel= 0.0005;          
    sdm_params.beta_Voc     = -0.0422;         
    sdm_params.T_ref        = 25.0;            
    sdm_params.G_STC        = 1000;            
    
    K_outdoor = sdm_params.Isc_STC / sdm_params.G_STC;
    K_indoor  = 0.002425;
    G_eff = G_raw * (K_indoor / K_outdoor);
    
    % Read Data
    raw_data = readmatrix(file_path);
    V_unfiltered = raw_data(:, 6);
    I_unfiltered = raw_data(:, 7);
    valid_idx = ~isnan(V_unfiltered) & ~isnan(I_unfiltered);
    [V_unfiltered, sort_idx] = sort(V_unfiltered(valid_idx));
    I_unfiltered = I_unfiltered(sort_idx);
    
    dV_grid  = 0.05;  
    V_grid = (0 : dV_grid : max(V_unfiltered)).';
    I_resampled = interp1(V_unfiltered, I_unfiltered, V_grid, 'pchip', 'extrap');
    I_smooth = max(0, sgolayfilt(I_resampled, 2, 31));
    
    Isc_meas = I_smooth(1);
    Voc_idx_meas = find(I_smooth > 0.005, 1, 'last');
    Voc_meas = V_grid(Voc_idx_meas);
    P_meas = V_grid .* I_smooth;
    [Pmp_meas, ~] = max(P_meas);
    FF_meas = Pmp_meas / (Isc_meas * Voc_meas);
    
    % Simulate SDM Baseline
    [V_sdm, I_sdm, Pmp_sdm, ~, ~, Isc_sdm, Voc_sdm] = simulate_SDM_Baseline(G_eff, T_C, sdm_params);
    FF_sdm = Pmp_sdm / (Isc_sdm * Voc_sdm);
    
    % Signed residuals (measured - model)/model, in %.
    sres_Isc = (Isc_meas - Isc_sdm) / Isc_sdm * 100;
    sres_Voc = (Voc_meas - Voc_sdm) / Voc_sdm * 100;
    sres_Pmp = (Pmp_meas - Pmp_sdm) / Pmp_sdm * 100;
    sres_FF  = (FF_meas  - FF_sdm ) / FF_sdm  * 100;
    TH_ANOM = 5.0;   
    res_Isc = abs(sres_Isc);  res_Voc = abs(sres_Voc);
    res_Pmp = abs(sres_Pmp);  res_FF  = abs(sres_FF);
    is_anomaly = any([res_Isc res_Voc res_Pmp res_FF] > TH_ANOM);
    
    % Store results in fig.UserData for Step 2 shared interpretation
    fig.UserData.has_anomaly = is_anomaly;
    fig.UserData.sres_Isc    = sres_Isc;
    fig.UserData.sres_Pmp    = sres_Pmp;
    fig.UserData.G           = round(G_raw, -1);
    fig.UserData.T           = round(T_C);

    if is_anomaly
        lblStatus.Text = 'ANOMALY DETECTED -> PROCEED TO EIS';
        lblStatus.FontColor = [0.85 0.33 0.10];
        
        % Enable EIS button and style it active
        btn_eis.Enable = 'on';
        btn_eis.BackgroundColor = [0.85 0.33 0.10];
        btn_eis.Text = 'Run EIS Investigative Analysis & Plot Nyquist';
        txt_eis_verdict.Value = {'[EIS Ready] Select reference & test files to execute investigative analysis.'};
    else
        lblStatus.Text = 'NO ANOMALY (all residuals <= 5%)';   
        lblStatus.FontColor = [0.0 0.5 0.0];
        
        % Disable EIS button, make it grey, and update text
        btn_eis.Enable = 'off';
        btn_eis.BackgroundColor = [0.7 0.7 0.7];
        btn_eis.Text = 'NO NEED FOR EIS';
        txt_eis_verdict.Value = {'No need for EIS (Stage 1 healthy).'};
    end

    txtResults.Value = {
        sprintf('Residual Isc:  %+7.2f%%', sres_Isc);
        sprintf('Residual Voc:  %+7.2f%%', sres_Voc);
        sprintf('Residual Pmp:  %+7.2f%%', sres_Pmp);
        sprintf('Residual FF:   %+7.2f%%', sres_FF);
        sprintf('Residual = (measured - SDM)/SDM.');
        sprintf('Rule: any |residual| > %.1f%% triggers anomaly flag.', TH_ANOM);
    };

    % Plot I-V directly using passed handle
    cla(ax_iv_plot);
    plot(ax_iv_plot, V_grid, I_smooth, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Measured I-V');
    hold(ax_iv_plot, 'on');
    plot(ax_iv_plot, V_sdm, I_sdm, 'r--', 'LineWidth', 1.2, 'DisplayName', 'SDM Baseline');
    xlabel(ax_iv_plot, 'Voltage (V)'); ylabel(ax_iv_plot, 'Current (A)'); grid(ax_iv_plot, 'on');
    title(ax_iv_plot, sprintf('G = %.0f W/m^2, T = %.0f °C', round(G_raw,-1), round(T_C)));
    legend(ax_iv_plot, 'Location', 'northeast', 'FontSize', 8);
    hold(ax_iv_plot, 'off');
    
    % Plot P-V directly using passed handle
    cla(ax_pv_plot);
    plot(ax_pv_plot, V_grid, P_meas, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Measured P-V');
    hold(ax_pv_plot, 'on');
    plot(ax_pv_plot, V_sdm, V_sdm .* I_sdm, 'g--', 'LineWidth', 1.2, 'DisplayName', 'SDM Baseline P-V');
    xlabel(ax_pv_plot, 'Voltage (V)'); ylabel(ax_pv_plot, 'Power (W)'); grid(ax_pv_plot, 'on');
    title(ax_pv_plot, sprintf('Peak Power Res: %+7.2f%%', sres_Pmp));
    legend(ax_pv_plot, 'Location', 'northeast', 'FontSize', 8);
    hold(ax_pv_plot, 'off');
end

function runEISAnalysis(txtP1, txtR1, txtP2, txtR2, axNyquist, txtVerdict, fig)
    TH_RS  = 5.0;    
    TH_RCT = 10.0;   

    p_file1 = txtP1.Value; r_file1 = txtR1.Value;    
    p_file2 = txtP2.Value; r_file2 = txtR2.Value;    

    if ~isfile(p_file1) || ~isfile(r_file1) || ~isfile(p_file2) || ~isfile(r_file2)
        uialert(ancestor(txtP1, 'figure'), 'One or more EIS parameter or raw files could not be found!', 'File Error');
        return;
    end

    % Refit the Randles parameters to the capacitive arc (Nova values as starting point)
    nova1 = read_nova_params_local(p_file1);
    nova2 = read_nova_params_local(p_file2);
    [w1, Z1] = read_raw_local(r_file1);
    [w2, Z2] = read_raw_local(r_file2);
    p1 = refit_randles_local(w1, Z1, nova1);
    p2 = refit_randles_local(w2, Z2, nova2);

    dRs    = (p2.Rs    - p1.Rs)    / p1.Rs    * 100;
    dRct   = (p2.Rct   - p1.Rct)   / p1.Rct   * 100;
    dQ     = (p2.Q     - p1.Q)     / p1.Q     * 100;
    dAlpha = (p2.alpha - p1.alpha) / p1.alpha * 100;

    % --- Retrieve Stage 1 Context from fig.UserData ---
    ud = fig.UserData;
    if isfield(ud, 'has_anomaly') && ud.has_anomaly
        stage1_text = sprintf('Stage 1: Isc %+5.1f%%, Pmp %+5.1f%%, G = %d, T = %d', ud.sres_Isc, ud.sres_Pmp, ud.G, ud.T);
    else
        stage1_text = 'Stage 1: No anomaly / Not executed';
    end

    % --- Investigative Hypothesis Framework (Table Mapping) ---
    rs_stable = abs(dRs) < TH_RS;
    
    if ~ud.has_anomaly
        reading = 'no action (Stage 1 healthy)';
    elseif rs_stable && dRct <= -TH_RCT
        reading = 'consistent with partial shading';
    elseif rs_stable && dRct >= TH_RCT
        reading = 'irradiance or operating-point mismatch; check conditions';
    elseif ~rs_stable
        reading = 'series-resistance (contact/wiring) change';
    else
        reading = 'cause not resolved by EIS';
    end

    if rs_stable, rs_txt = 'stable'; else, rs_txt = 'CHANGED'; end

    lines = {
        stage1_text;
        sprintf('EIS vs Reference -> Rs: %s (d=%.1f%%), Rct: d=%.1f%%', rs_txt, dRs, dRct);
        sprintf('HYPOTHESIS READING: %s', reading);
        sprintf('alpha: ref %.3f -> test %.3f (d = %+6.2f%%)', p1.alpha, p2.alpha, dAlpha);
        sprintf('Q: ref %.2f mF -> test %.2f mF (d = %+6.1f%%)', p1.Q*1e3, p2.Q*1e3, dQ);
        sprintf('fc: ref %.0f Hz, test %.0f Hz (parameters refitted to the arc)', p1.fc, p2.fc);
    };
    txtVerdict.Value = lines;

    % --- Nyquist overlay ---
    cla(axNyquist);
    hold(axNyquist, 'on');
    plot_nyquist_uiaxes(axNyquist, w1, Z1, p1, 'Reference (unshaded)', 'b', 1.5);
    plot_nyquist_uiaxes(axNyquist, w2, Z2, p2, 'Test run', 'r', 1.5);
    set(axNyquist, 'YDir', 'normal'); grid(axNyquist, 'on'); box(axNyquist, 'on');
    xlabel(axNyquist, 'Z'' (\Omega)');
    ylabel(axNyquist, '-Z'''' (\Omega)');
    title(axNyquist, 'Nyquist Spectrum Overlay (Measured vs Fitted)');
    % Axis limits from the capacitive data of both runs (y-axis from 0)
    Zc = [Z1(-imag(Z1) > 0); Z2(-imag(Z2) > 0)];
    xr = [min(real(Zc)), max(real(Zc))];
    xlim(axNyquist, [xr(1) - 0.05*diff(xr), xr(2) + 0.05*diff(xr)]);
    ylim(axNyquist, [0, 1.15*max(-imag(Zc))]);
    legend(axNyquist, 'Location', 'best', 'FontSize', 8);
    hold(axNyquist, 'off');
end

%% =====================================================================
%% LOCAL HELPER FUNCTIONS
%% =====================================================================
function p = read_nova_params_local(filename)
    row_data = readmatrix(filename, 'Range', 'G2:J2');
    p.Q     = row_data(1);
    p.Rct   = row_data(2);
    p.Rs    = row_data(3);
    p.alpha = row_data(4);
end

function [w, Z] = read_raw_local(raw_file)
    % Nova raw export: col 1 = Z' (Ohm), col 3 = -Z'' (Ohm), col 8 = omega (rad/s)
    T = readtable(raw_file, detectImportOptions(raw_file));
    Zre    = T{:, 1};
    negZim = T{:, 3};            % sign KEPT: -Z'' < 0 are inductive HF points
    w      = T{:, 8};
    Z      = Zre - 1i*negZim;
end

function p = refit_randles_local(w, Z, p0)
    % Fit Rs, Rct, Q, alpha to the capacitive arc only (-Z'' > 0); the
    % inductive high-frequency points are excluded (no inductor in the model).
    use = -imag(Z) > 0;
    [~, k] = max(-imag(Z) .* use);               % apex of the measured arc
    Q0 = 1 / (p0.Rct * w(k)^p0.alpha);           % starting Q from the apex
    x0 = [p0.Rs, p0.Rct, log10(Q0), p0.alpha];
    model = @(x, ww) x(1) + x(2) ./ (1 + x(2) * 10^x(3) * (1i*ww).^x(4));
    cost  = @(x) sum(abs((model(x, w(use)) - Z(use)) ./ abs(Z(use))).^2) ...
                 + 1e3*max(0, x(4) - 1)^2;      % keep alpha <= 1
    opts = optimset('MaxFunEvals', 2e4, 'MaxIter', 2e4, 'TolX', 1e-10, 'TolFun', 1e-14);
    x = fminsearch(cost, x0, opts);
    p.Rs = x(1); p.Rct = x(2); p.Q = 10^x(3); p.alpha = x(4);
    p.fc = 1/(2*pi*(p.Rct*p.Q)^(1/p.alpha));
end

function plot_nyquist_uiaxes(ax, w, Z, p, label_str, col, line_width)
    cap = -imag(Z) > 0;                          % capacitive points only
    plot(ax, real(Z(cap)), -imag(Z(cap)), 'o', 'MarkerSize', 3, ...
        'MarkerEdgeColor', col, 'MarkerFaceColor', 'none', ...
        'DisplayName', [label_str ' (Meas)']);
    % Fitted arc on a dense frequency grid so the whole semicircle is drawn
    w_fit = 2*pi*logspace(-1, 6, 400)';
    Zcpe  = 1 ./ (p.Q * (1i*w_fit).^p.alpha);
    Z_fit = p.Rs + (p.Rct .* Zcpe) ./ (p.Rct + Zcpe);
    Z_fit = Z_fit(-imag(Z_fit) >= 0);
    plot(ax, real(Z_fit), -imag(Z_fit), '-', 'Color', col, 'LineWidth', line_width, ...
        'DisplayName', [label_str ' (Fit)']);
end

function [V_sdm, I_sdm, Pmp_sdm, Vmp_sdm, Imp_sdm, Isc_sdm, Voc_sdm] = simulate_SDM_Baseline(G_eff, T_C, sdm_params)
    q = 1.60217663e-19; k = 1.380649e-23; Eg = 1.12; T_STC = 298.15; T_K = T_C + 273.15;
    Iph_sdm = (G_eff / sdm_params.G_STC) * sdm_params.Isc_STC * (1 + sdm_params.alpha_Isc_rel * (T_C - sdm_params.T_ref)); 
    I0_sdm  = sdm_params.I0_STC * ((T_K / T_STC)^3) * exp((q * Eg / (sdm_params.n * k)) * ((1 / T_STC) - (1 / T_K)));
    Vt_sdm  = (sdm_params.Ns * sdm_params.n * k * T_K) / q;
    Voc_est = sdm_params.Voc_STC + sdm_params.beta_Voc * (T_C - sdm_params.T_ref);
    
    V_sdm = linspace(0, Voc_est * 1.05, 300).';
    I_sdm = zeros(size(V_sdm));
    
    for v_idx = 1:length(V_sdm)
        V_val = V_sdm(v_idx); I_val = Iph_sdm;
        for iter = 1:40
            exp_term = exp((V_val + I_val * sdm_params.Rs_macro) / Vt_sdm);
            f  = Iph_sdm - I0_sdm * (exp_term - 1) - (V_val + I_val * sdm_params.Rs_macro) / sdm_params.Rsh_macro - I_val;
            df = -I0_sdm * (sdm_params.Rs_macro / Vt_sdm) * exp_term - (sdm_params.Rs_macro / sdm_params.Rsh_macro) - 1;
            I_next = I_val - f / df;
            if abs(I_next - I_val) < 1e-6, break; end
            I_val = max(0, I_next);
        end
        I_sdm(v_idx) = I_val;
    end
    Isc_sdm = I_sdm(1);
    Voc_idx_sdm = find(I_sdm > 0.005, 1, 'last');
    if isempty(Voc_idx_sdm), Voc_idx_sdm = length(V_sdm); end
    Voc_sdm = V_sdm(Voc_idx_sdm);
    P_sdm = V_sdm .* I_sdm;
    [Pmp_sdm, max_p_idx] = max(P_sdm);
    Vmp_sdm = V_sdm(max_p_idx);
    Imp_sdm = I_sdm(max_p_idx);
end