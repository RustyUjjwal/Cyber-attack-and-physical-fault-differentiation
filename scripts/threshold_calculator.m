%% --- Menu-Driven Full Statistical & Threshold Analyzer (Complete Bounds) ---
clc;
disp('==================================================');
disp('   IEEE Bus Full Data Analysis Menu');
disp('==================================================');
disp('1. Analyze thresholds for a SPECIFIC bus');
disp('2. Analyze thresholds for ALL buses');
choice = input('Enter your choice (1 or 2): ');

% Determine which buses to process
if choice == 1
    bus_list = input('Enter the specific bus number (e.g., 5): ');
elseif choice == 2
    max_bus = input('Enter the total number of buses in the system (e.g., 5): ');
    bus_list = 1:max_bus;
else
    disp('Invalid choice. Exiting script...');
    bus_list = [];
end

% Loop through selected buses
for i = 1:length(bus_list)
    bus_num = bus_list(i);
    filename = sprintf('z_B%d_data.csv', bus_num);
    
    % Load Data
    try
        data = readtable(filename);
    catch
        fprintf('\n⚠️ Warning: File %s not found. Skipping...\n', filename);
        continue;
    end

    % -------- DYNAMICALLY EXTRACT SIGNALS --------
    va_col = sprintf('Va_B%d', bus_num); vb_col = sprintf('Vb_B%d', bus_num); vc_col = sprintf('Vc_B%d', bus_num);
    ia_col = sprintf('Ia_B%d', bus_num); ib_col = sprintf('Ib_B%d', bus_num); ic_col = sprintf('Ic_B%d', bus_num);

    va = data.(va_col); vb = data.(vb_col); vc = data.(vc_col);
    ia = data.(ia_col); ib = data.(ib_col); ic = data.(ic_col);

    % -------- CALCULATIONS --------
    eps_val = 1e-6;
    Vrms = sqrt((va.^2 + vb.^2 + vc.^2)/3);
    Irms = sqrt((ia.^2 + ib.^2 + ic.^2)/3);
    Z = Vrms ./ (Irms + eps_val);
    P = va.*ia + vb.*ib + vc.*ic;
    
    % -------- 4-PARAMETER STATISTICS --------
    Z_mean = mean(Z);    Z_std  = std(Z);    Z_min = min(Z);    Z_max = max(Z);
    V_mean = mean(Vrms); V_std  = std(Vrms); V_min = min(Vrms); V_max = max(Vrms);
    I_mean = mean(Irms); I_std  = std(Irms); I_min = min(Irms); I_max = max(Irms);
    P_mean = mean(P);    P_std  = std(P);    P_min = min(P);    P_max = max(P);

    % -------- CALCULATED THRESHOLDS (Pure Math: 3-Sigma) --------
    k = 3; 
    Z_upper_calc = Z_mean + (k * Z_std);
    Z_lower_calc = Z_mean - (k * Z_std);

    V_upper_calc = V_mean + (k * V_std);
    V_lower_calc = V_mean - (k * V_std);
    
    I_upper_calc = I_mean + (k * I_std);
    I_lower_calc = I_mean - (k * I_std);
    
    P_upper_calc = P_mean + (k * P_std);
    P_lower_calc = P_mean - (k * P_std);

    % -------- PRACTICAL THRESHOLDS (System Logic) --------
    % Impedance (Enforce min tolerance)
    Z_tol_prac = max((k * Z_std), 0.2); 
    Z_upper_prac = Z_mean + Z_tol_prac;
    Z_lower_prac = Z_mean - Z_tol_prac;

    % Voltage (±20%)
    V_upper_prac = 1.2 * V_mean;
    V_lower_prac = 0.8 * V_mean;

    % Current (HIF Protection Lower Bound, No strict upper bound for healthy/cyber separation)
    I_lower_prac = 0.75 * I_mean; 
    
    % Power (Absolute strict limit translates to +/- bounds)
    P_strict_prac = 2.0 + 0.3; 
    P_upper_prac  = P_strict_prac;
    P_lower_prac  = -P_strict_prac;

    % -------- DISPLAY RESULTS --------
    fprintf('\n\n');
    disp('==================================================');
    fprintf('   FULL STATISTICAL & THRESHOLD ANALYSIS (BUS %d)\n', bus_num);
    disp('==================================================');

    % --- IMPEDANCE ---
    fprintf('\n>>> IMPEDANCE (Z) <<<\n');
    fprintf('Mean : %8.4f pu  |  Std  : %8.4f pu\n', Z_mean, Z_std);
    fprintf('Min  : %8.4f pu  |  Max  : %8.4f pu\n', Z_min, Z_max);
    fprintf('--------------------------------------------------\n');
    fprintf('          CALCULATED (3-Sigma)  |  PRACTICAL (Applied)\n');
    fprintf('Upper Z : %10.4f pu         | %10.4f pu\n', Z_upper_calc, Z_upper_prac);
    fprintf('Lower Z : %10.4f pu         | %10.4f pu\n', Z_lower_calc, Z_lower_prac);

    % --- VOLTAGE ---
    fprintf('\n>>> VOLTAGE (Vrms) <<<\n');
    fprintf('Mean : %8.4f pu  |  Std  : %8.4f pu\n', V_mean, V_std);
    fprintf('Min  : %8.4f pu  |  Max  : %8.4f pu\n', V_min, V_max);
    fprintf('--------------------------------------------------\n');
    fprintf('          CALCULATED (3-Sigma)  |  PRACTICAL (±20%%)\n');
    fprintf('Upper V : %10.4f pu         | %10.4f pu\n', V_upper_calc, V_upper_prac);
    fprintf('Lower V : %10.4f pu         | %10.4f pu\n', V_lower_calc, V_lower_prac);

    % --- CURRENT ---
    fprintf('\n>>> CURRENT (Irms) <<<\n');
    fprintf('Mean : %8.4f pu  |  Std  : %8.4f pu\n', I_mean, I_std);
    fprintf('Min  : %8.4f pu  |  Max  : %8.4f pu\n', I_min, I_max);
    fprintf('--------------------------------------------------\n');
    fprintf('          CALCULATED (3-Sigma)  |  PRACTICAL (Applied)\n');
    fprintf('Upper I : %10.4f pu         | %10s\n', I_upper_calc, 'N/A (Used as trigger)');
    fprintf('Lower I : %10.4f pu         | %10.4f pu (HIF bound)\n', I_lower_calc, I_lower_prac);

    % --- POWER ---
    fprintf('\n>>> POWER (P) <<<\n');
    fprintf('Mean : %8.4f pu  |  Std  : %8.4f pu\n', P_mean, P_std);
    fprintf('Min  : %8.4f pu  |  Max  : %8.4f pu\n', P_min, P_max);
    fprintf('--------------------------------------------------\n');
    fprintf('          CALCULATED (3-Sigma)  |  PRACTICAL (Applied)\n');
    fprintf('Upper P : %10.4f pu         | %10.4f pu\n', P_upper_calc, P_upper_prac);
    fprintf('Lower P : %10.4f pu         | %10.4f pu\n', P_lower_calc, P_lower_prac);

    disp('==================================================');
end

if ~isempty(bus_list)
    fprintf('\n✅ Analysis Complete for all selected buses.\n');
end