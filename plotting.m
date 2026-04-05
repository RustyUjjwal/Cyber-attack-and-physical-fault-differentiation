disp('--- Extracting Workspace Data ---');

time = out.t_data;             
v_true = out.v_true;         
v_hacked = out.v_hacked;     
i_true = out.i_true;         
ids_status = out.IDS_status; 
fault_type = out.Fault_type; 

anomaly_signal_v = abs(v_true - v_hacked);
tolerance_band = 0.05; 

disp('--- Generating High-Visibility Diagnostic Plots ---');
figure('Name', 'SCADA Master Dashboard: Security & Fault Classification', 'Position', [100, 50, 900, 1000]);

% =========================================================
% --- Plot 1: Voltage Overlay ---
% =========================================================
subplot(4, 1, 1);
p1 = plot(time, v_true, 'Color', [0, 0.4470, 0.7410], 'LineWidth', 2); hold on;
p2 = plot(time, v_hacked, 'Color', [0.8500, 0.3250, 0.0980], 'LineStyle', '--', 'LineWidth', 2.5);
title('1. Control Room Monitor: True Grid Voltage vs. Spoofed Voltage');
ylabel('Voltage (p.u.)');

% THE FIX: Added 'AutoUpdate', 'off' to lock the legend
legend([p1(1), p2(1)], {'True Grid Voltage', 'Spoofed (Hacked) Voltage'}, 'Location', 'best', 'AutoUpdate', 'off');
ylim([-1.5 1.5]); 
grid on;
xline(0.2, ':k', 'Voltage Attack Strikes', 'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.5);

% =========================================================
% --- Plot 2: Physical Current ---
% =========================================================
subplot(4, 1, 2);
% THE FIX: Added a handle (p3) so the legend knows exactly what to grab
p3 = plot(time, i_true, 'Color', [0.4660, 0.6740, 0.1880], 'LineWidth', 2); 
title('2. Physical Grid Response: Line Current');
ylabel('Current (p.u.)');

% THE FIX: Added handle p3(1) and 'AutoUpdate', 'off'
legend(p3(1), {'True Line Current'}, 'Location', 'best', 'AutoUpdate', 'off');
grid on;
xline(0.6, ':k', 'Physical Fault Strikes', 'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.5);

% =========================================================
% --- Plot 3: IDS Decision & Deviation ---
% =========================================================
subplot(4, 1, 3);
h1 = plot(time, anomaly_signal_v, 'Color', [0.8 0.8 0.8], 'LineWidth', 1); hold on;
h2 = yline(tolerance_band, 'r--', 'LineWidth', 2); 
h3 = stairs(time, ids_status * 0.1, 'Color', [0 0 0], 'LineWidth', 3); 

title('3. Intrusion Detection System: Anomaly Deviation & Relay Action');
ylabel('Deviation / Status');
ylim([-0.05 0.3]); 

% THE FIX: Added 'AutoUpdate', 'off' to lock the legend
legend([h1(1), h2, h3], {'Voltage Deviation (AC Ripple)', '5% Tolerance Band', 'Relay Status (0=Norm, 1=Hack, 2=Fault)'}, 'Location', 'best', 'AutoUpdate', 'off');
grid on;

% =========================================================
% --- Plot 4: The 5-State Fault Classifier ---
% =========================================================
subplot(4, 1, 4);
stairs(time, fault_type, 'Color', [0.4940, 0.1840, 0.5560], 'LineWidth', 3); 
title('4. Diagnostic System: Exact Event Classification');
xlabel('Time (Seconds)');
ylabel('Fault Type State');
ylim([-0.5 5.5]); 
yticks([0 1 2 3 4 5]);
yticklabels({'0: None', '1: LG', '2: LL', '3: LLG', '4: LLL', '5: SCADA Hack'});
grid on;

disp('>> Analysis Complete. Master dashboard graph ready for export.');