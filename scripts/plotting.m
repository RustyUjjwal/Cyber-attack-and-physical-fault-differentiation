% Clear workspace and command window for a fresh run
clc; clear; close all;

% =========================================================================
% 1. Load the Data Files
% =========================================================================
% Make sure these CSV files are in your current writable MATLAB directory
main_data = readtable('Cyber_Physical_System_Data_Perfected.csv');
before_data = readtable('z_B5_BeforeFault_data.csv');
after_data = readtable('z_B5_AfterFault_data.csv');

% =========================================================================
% SYSTEM LOGIC & DETECTION FLAGS (Separated into 3 Individual Figures)
% =========================================================================

% --- Plot 1A: Fault Classification Level ---
fig1A = figure('Name', 'Plot 1A: Fault Classification Level', 'Position', [100, 100, 800, 400]);
stairs(main_data.Time, main_data.fault_classification, 'b', 'LineWidth', 1.5);
title('Fault Classification Level');
xlabel('Time (Seconds)');
ylabel('Fault Type');

max_class = max(main_data.fault_classification);
ylim([-0.5, max_class+0.5]);
yticks(0:max_class);
if max_class == 4
    yticklabels({'Normal/Cyber (0)', 'Symmetrical (1)', 'Unsymmetrical (2)', 'RPF (3)', 'Intermittent (4)'});
end
grid on;
saveas(fig1A, 'Plot 1A - Fault Classification Level.png');


% --- Plot 1B: Anomaly Detection Flag ---
fig1B = figure('Name', 'Plot 1B: Anomaly Detection Flag', 'Position', [150, 150, 800, 400]);
stairs(main_data.Time, main_data.flag_detection, 'r', 'LineWidth', 1.5);
title('Anomaly Detection Flag');
xlabel('Time (Seconds)');
ylabel('Detection Status');
ylim([-0.5, 2.5]);
yticks([0, 1, 2]);
yticklabels({'Normal (0)', 'Cyber (1)', 'Physical (2)'});
grid on;
saveas(fig1B, 'Plot 1B - Anomaly Detection Flag.png');


% --- Plot 1C: Cyber Attack Ground Truth ---
fig1C = figure('Name', 'Plot 1C: Cyber Attack Ground Truth', 'Position', [200, 200, 800, 400]);

if ismember('flag_cyber', main_data.Properties.VariableNames)
    hold on;
    
    % 1. Plot the digital cyber flag
    stairs(main_data.Time, main_data.flag_cyber, 'k', 'LineWidth', 1.5);
    
    % 2. Identify start and end indices of each attack block
    is_attack = main_data.flag_cyber == 1;
    starts = find(diff([0; is_attack]) == 1); % Rising edges
    ends = find(diff([is_attack; 0]) == -1);  % Falling edges
    
    % 3. Define the sequential list of attack labels exactly as requested
    attack_labels = {'Fake-Short', 'Fake-Sag', 'Fake-Swell', 'Replay Attack', 'Noise Injection'};
    
    % 4. Loop through each detected attack window ('i' acts as our counter)
    for i = 1:length(starts)
        t_start = main_data.Time(starts(i));
        t_end = main_data.Time(ends(i));
        
        % Draw a transparent red shaded window highlighting the duration
        patch([t_start t_end t_end t_start], [-0.5 -0.5 1.5 1.5], 'r', ...
            'FaceAlpha', 0.1, 'EdgeColor', 'none');
            
        % Assign the label sequentially based on the counter 'i'
        if i <= length(attack_labels)
            label_str = attack_labels{i};
        else
            % Failsafe: just in case there are more than 5 triggers in your data
            label_str = sprintf('Attack %d', i); 
        end
        
        % Calculate midpoint of the window to center the text
        t_mid = (t_start + t_end) / 2;
        
        % Add the text box above the active flag line
        text(t_mid, 1.15, label_str, 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', 'FontWeight', 'bold', 'Color', '#A2142F', ...
            'BackgroundColor', 'w', 'EdgeColor', '#A2142F', 'Margin', 2);
    end

    % Standard Formatting
    title('Cyber Attack Ground Truth');
    xlabel('Time (Seconds)');
    ylabel('Ground Truth Status');
    ylim([-0.5, 1.5]);
    yticks([0, 1]);
    yticklabels({'Inactive (0)', 'Active (1)'});
    grid on;
    hold off;
    
    saveas(fig1C, 'Plot 1C - Cyber Attack Ground Truth.png');
else
    title('Cyber Flag not found in dataset');
end

% =========================================================================
% MANIPULATED CYBER DATA (Figures 2 & 3)
% =========================================================================

% --- Figure 2: Bus 5: 3-Phase Manipulated Cyber Voltages ---
fig2 = figure('Name', 'Figure 2: Bus 5: 3-Phase Manipulated Cyber Voltages', 'Position', [250, 250, 800, 400]);
plot(main_data.Time, main_data.cyber_V_PhaseA, 'r', 'LineWidth', 1.2); hold on;
plot(main_data.Time, main_data.cyber_V_PhaseB, 'g', 'LineWidth', 1.2);
plot(main_data.Time, main_data.cyber_V_PhaseC, 'b', 'LineWidth', 1.2);
title('Bus 5: 3-Phase Manipulated Cyber Voltages');
xlabel('Time (Seconds)');
ylabel('Voltage (p.u.)');
legend('Phase A', 'Phase B', 'Phase C', 'Location', 'best');
grid on;
saveas(fig2, 'Figure 2 - Bus 5 - 3-Phase Manipulated Cyber Voltages.png');


% --- Figure 3: Bus 5: 3-Phase Manipulated Cyber Currents ---
fig3 = figure('Name', 'Figure 3: Bus 5: 3-Phase Manipulated Cyber Currents', 'Position', [300, 300, 800, 400]);
plot(main_data.Time, main_data.cyber_I_PhaseA, 'r', 'LineWidth', 1.2); hold on;
plot(main_data.Time, main_data.cyber_I_PhaseB, 'g', 'LineWidth', 1.2);
plot(main_data.Time, main_data.cyber_I_PhaseC, 'b', 'LineWidth', 1.2);
title('Bus 5: 3-Phase Manipulated Cyber Currents');
xlabel('Time (Seconds)');
ylabel('Current (p.u.)');
legend('Phase A', 'Phase B', 'Phase C', 'Location', 'best');
grid on;
saveas(fig3, 'Figure 3 - Bus 5 - 3-Phase Manipulated Cyber Currents.png');

% =========================================================================
% VOLTAGE STAGE COMPARISON (Separated into 3 Individual Figures)
% =========================================================================

% --- Subplot 1: Pre-Fault / Steady State Voltage ---
fig4A = figure('Name', 'Subplot 1: Pre-Fault / Steady State Voltage', 'Position', [350, 350, 800, 400]);
plot(before_data.Time, before_data.Va_B5, 'r', before_data.Time, before_data.Vb_B5, 'g', before_data.Time, before_data.Vc_B5, 'b');
title('Pre-Fault / Steady State Voltage');
xlabel('Time (Seconds)'); ylabel('Voltage (p.u.)'); grid on;
legend('Phase A', 'Phase B', 'Phase C', 'Location', 'best');
saveas(fig4A, 'Subplot 1 - Pre-Fault Steady State Voltage.png');


% --- Subplot 2: Actual Physical Grid Voltage ---
fig4B = figure('Name', 'Subplot 2: Actual Physical Grid Voltage', 'Position', [400, 400, 800, 400]);
plot(after_data.Time, after_data.Va_B5, 'r', after_data.Time, after_data.Vb_B5, 'g', after_data.Time, after_data.Vc_B5, 'b');
title('Actual Physical Grid Voltage');
xlabel('Time (Seconds)'); ylabel('Voltage (p.u.)'); grid on;
legend('Phase A', 'Phase B', 'Phase C', 'Location', 'best');
saveas(fig4B, 'Subplot 2 - Actual Physical Grid Voltage.png');


% --- Subplot 3: Manipulated Cyber Output Voltage ---
fig4C = figure('Name', 'Subplot 3: Manipulated Cyber Output Voltage', 'Position', [450, 450, 800, 400]);
plot(main_data.Time, main_data.cyber_V_PhaseA, 'r', main_data.Time, main_data.cyber_V_PhaseB, 'g', main_data.Time, main_data.cyber_V_PhaseC, 'b');
title('Manipulated Cyber Output Voltage');
xlabel('Time (Seconds)'); ylabel('Voltage (p.u.)'); grid on;
legend('Phase A', 'Phase B', 'Phase C', 'Location', 'best');
saveas(fig4C, 'Subplot 3 - Manipulated Cyber Output Voltage.png');

% =========================================================================
% CURRENT STAGE COMPARISON (Separated into 3 Individual Figures)
% =========================================================================

% --- Subplot 1: Pre-Fault / Steady State Current ---
fig5A = figure('Name', 'Subplot 1: Pre-Fault / Steady State Current', 'Position', [500, 500, 800, 400]);
plot(before_data.Time, before_data.Ia_B5, 'r', before_data.Time, before_data.Ib_B5, 'g', before_data.Time, before_data.Ic_B5, 'b');
title('Pre-Fault / Steady State Current');
xlabel('Time (Seconds)'); ylabel('Current (p.u.)'); grid on;
legend('Phase A', 'Phase B', 'Phase C', 'Location', 'best');
saveas(fig5A, 'Subplot 1 - Pre-Fault Steady State Current.png');


% --- Subplot 2: Actual Physical Grid Current ---
fig5B = figure('Name', 'Subplot 2: Actual Physical Grid Current', 'Position', [550, 550, 800, 400]);
plot(after_data.Time, after_data.Ia_B5, 'r', after_data.Time, after_data.Ib_B5, 'g', after_data.Time, after_data.Ic_B5, 'b');
title('Actual Physical Grid Current');
xlabel('Time (Seconds)'); ylabel('Current (p.u.)'); grid on;
legend('Phase A', 'Phase B', 'Phase C', 'Location', 'best');
saveas(fig5B, 'Subplot 2 - Actual Physical Grid Current.png');


% --- Subplot 3: Manipulated Cyber Output Current ---
fig5C = figure('Name', 'Subplot 3: Manipulated Cyber Output Current', 'Position', [600, 600, 800, 400]);
plot(main_data.Time, main_data.cyber_I_PhaseA, 'r', main_data.Time, main_data.cyber_I_PhaseB, 'g', main_data.Time, main_data.cyber_I_PhaseC, 'b');
title('Manipulated Cyber Output Current');
xlabel('Time (Seconds)'); ylabel('Current (p.u.)'); grid on;
legend('Phase A', 'Phase B', 'Phase C', 'Location', 'best');
saveas(fig5C, 'Subplot 3 - Manipulated Cyber Output Current.png');

% =========================================================================
% ADVANCED OVERLAY
% =========================================================================

% --- Figure 6: Cyber Data & Attack Window Overlay ---
fig6 = figure('Name', 'Figure 6: Cyber Data & Attack Window Overlay', 'Position', [650, 100, 1000, 500]);

if ismember('flag_cyber', main_data.Properties.VariableNames)
    yyaxis left
    plot(main_data.Time, main_data.cyber_V_PhaseA, 'r', 'LineWidth', 1); hold on;
    plot(main_data.Time, main_data.cyber_V_PhaseB, 'g', 'LineWidth', 1);
    plot(main_data.Time, main_data.cyber_V_PhaseC, 'b', 'LineWidth', 1);
    ylabel('Manipulated Cyber Voltage (p.u.)');
    ylim([-2.0 2.0]); 
    
    yyaxis right
    area(main_data.Time, main_data.flag_cyber, 'FaceColor', 'k', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    hold on;
    stairs(main_data.Time, main_data.flag_cyber, 'k', 'LineWidth', 1.5);
    
    ylabel('Cyber Attack Status');
    ylim([-0.1 1.2]); 
    yticks([0 1]);
    yticklabels({'Inactive (0)', 'Active Attack (1)'});
    
    title('Cyber Data & Attack Window Overlay');
    xlabel('Time (Seconds)');
    
    ax = gca;
    ax.YAxis(1).Color = 'k';
    ax.YAxis(2).Color = 'k';
    
    legend('Phase A', 'Phase B', 'Phase C', 'Attack Window Shading', 'Ground Truth Flag', 'Location', 'southwest', 'Orientation', 'horizontal');
    grid on;
    
    saveas(fig6, 'Figure 6 - Cyber Data & Attack Window Overlay.png');
else
    disp('Warning: Cannot plot overlay because "flag_cyber" is missing from the dataset.');
end