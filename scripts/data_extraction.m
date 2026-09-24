%% --- Menu-Driven Dynamic Data Extraction (With File Naming Feature) ---
clc;
disp('========================================');
disp('   IEEE Bus Data Extraction Menu');
disp('========================================');
disp('1. Extract data for a SPECIFIC bus');
disp('2. Extract data for ALL buses');
choice = input('Enter your choice (1 or 2): ');

% Determine which buses to process based on user choice
if choice == 1
    bus_list = input('Enter the specific bus number (e.g., 5): ');
elseif choice == 2
    max_bus = input('Enter the total number of buses in the system (e.g., 5): ');
    bus_list = 1:max_bus;
else
    disp('Invalid choice. Exiting script...');
    bus_list = [];
end

% Exit if no buses selected
if isempty(bus_list), return; end

% ========================================
%    NEW: File Naming Menu
% ========================================
disp(' ');
disp('==========================');
disp('   File Naming Menu');
disp('==========================');
disp('3. File for analysis AFTER fault (Fault/Testing Data)');
disp('4. File for analysis BEFORE fault (Healthy/Baseline Data)');
file_choice = input('Enter your choice (3 or 4): ');

% Set the file tag based on choice
if file_choice == 3
    file_tag = 'AfterFault';
elseif file_choice == 4
    file_tag = 'BeforeFault';
else
    disp('Invalid choice. Defaulting to "RawData"...');
    file_tag = 'RawData';
end

% Loop through the selected bus list
for i = 1:length(bus_list)
    bus_num = bus_list(i);
    
    % Dynamically generate the workspace variable names
    volt_var = sprintf('voltage_B%d', bus_num);
    curr_var = sprintf('current_B%d', bus_num);
    apower_var = sprintf('APower_B%d', bus_num);
    rpower_var = sprintf('RPower_B%d', bus_num);
    
    % Initialize presence flags and storage
    has_V = false; has_I = false; has_P = false; has_Q = false;
    lengths_array = [];
    missing_str = "";

    % 1. TIME VECTOR (Mandatory for CSV structure)
    try
        t_vec_full = out.tout(:, 1);
        lengths_array(end+1) = length(t_vec_full);
    catch
        fprintf('Warning: Time vector (tout) not found. Cannot create CSV for Bus %d. Skipping...\n', bus_num);
        continue;
    end

    % 2. VOLTAGE EXTRACTION
    try
        va_full = out.(volt_var)(:, 1); vb_full = out.(volt_var)(:, 2); vc_full = out.(volt_var)(:, 3);
        has_V = true;
        lengths_array(end+1) = length(va_full);
    catch
        missing_str = missing_str + "Voltage ";
    end

    % 3. CURRENT EXTRACTION
    try
        ia_full = out.(curr_var)(:, 1); ib_full = out.(curr_var)(:, 2); ic_full = out.(curr_var)(:, 3);
        has_I = true;
        lengths_array(end+1) = length(ia_full);
    catch
        missing_str = missing_str + "Current ";
    end

    % 4. ACTIVE POWER EXTRACTION
    try
        pa_full = out.(apower_var)(:, 1); pb_full = out.(apower_var)(:, 2); pc_full = out.(apower_var)(:, 3);
        has_P = true;
        lengths_array(end+1) = length(pa_full);
    catch
        missing_str = missing_str + "APower ";
    end

    % 5. REACTIVE POWER EXTRACTION
    try
        qa_full = out.(rpower_var)(:, 1); qb_full = out.(rpower_var)(:, 2); qc_full = out.(rpower_var)(:, 3);
        has_Q = true;
        lengths_array(end+1) = length(qa_full);
    catch
        missing_str = missing_str + "RPower ";
    end

    % --- ALIGNMENT ---
    min_len = min(lengths_array);

    % --- DYNAMIC TABLE CONSTRUCTION ---
    table_vars = {t_vec_full(1:min_len)};
    headers = {'Time'};

    if has_V
        table_vars = [table_vars, {va_full(1:min_len), vb_full(1:min_len), vc_full(1:min_len)}];
        headers = [headers, {sprintf('Va_B%d', bus_num), sprintf('Vb_B%d', bus_num), sprintf('Vc_B%d', bus_num)}];
    end

    if has_I
        table_vars = [table_vars, {ia_full(1:min_len), ib_full(1:min_len), ic_full(1:min_len)}];
        headers = [headers, {sprintf('Ia_B%d', bus_num), sprintf('Ib_B%d', bus_num), sprintf('Ic_B%d', bus_num)}];
    end

    if has_P
        table_vars = [table_vars, {pa_full(1:min_len), pb_full(1:min_len), pc_full(1:min_len)}];
        headers = [headers, {sprintf('Pa_B%d', bus_num), sprintf('Pb_B%d', bus_num), sprintf('Pc_B%d', bus_num)}];
    end

    if has_Q
        table_vars = [table_vars, {qa_full(1:min_len), qb_full(1:min_len), qc_full(1:min_len)}];
        headers = [headers, {sprintf('Qa_B%d', bus_num), sprintf('Qb_B%d', bus_num), sprintf('Qc_B%d', bus_num)}];
    end

    % --- NEW FILENAME LOGIC ---
    % Filename will look like: z_B5_BeforeFault_data.csv
    filename = sprintf('z_B%d_%s_data.csv', bus_num, file_tag);
    
    final_table = table(table_vars{:}, 'VariableNames', headers);
    writetable(final_table, filename);
    
    if missing_str == ""
        fprintf('Created %s (%d rows).\n', filename, min_len);
    else
        fprintf('Created %s (%d rows) | Omitted: %s\n', filename, min_len, missing_str);
    end
end

disp('========================================');
disp('   Extraction Process Complete!');
disp('========================================');
%%
% 1. Extract data from the 'out' object, squeeze, and transpose
% This converts the 3x1x20001 arrays inside 'out' into 20001x3 matrices
I_3ph = squeeze(out.cyber_current_B5)'; 
V_3ph = squeeze(out.cyber_voltage_B5)';

% Extract the time vector from the 'out' object
time_vector = out.tout;

% 2. Combine Time, Current (3 phases), and Voltage (3 phases) into one matrix
% The resulting matrix will have 20001 rows and 7 columns
combined_data = [time_vector, I_3ph, V_3ph];

% 3. Define clear column headers for the CSV file
headers = {'Time', 'Current_PhaseA', 'Current_PhaseB', 'Current_PhaseC', ...
           'Voltage_PhaseA', 'Voltage_PhaseB', 'Voltage_PhaseC'};

% 4. Convert the matrix into a MATLAB Table for easy export
dataTable = array2table(combined_data, 'VariableNames', headers);

% 5. Write the table to a CSV file in your current directory
writetable(dataTable, 'cyber_data.csv');

disp('Data successfully saved to extracted_3phase_data_from_out.csv!');

%% MATLAB Script to Extract and Export 3-Phase Data to CSV
% Handles the Simulink 'out' object and 3D array dimensions

% 1. Extract Data from Workspace or 'out' object
try
    if exist('out', 'var') == 1
        % Extract from modern Simulink 'out' object
        time_data = out.tout;
        I_abc_raw = out.cyber_current_B5;
        V_abc_raw = out.cyber_voltage_B5;
        f_class   = out.fault_classificaton; % Check spelling here vs Simulink!
        f_detect  = out.flag_detection;
        f_cyber   = out.flag_cyber;
        disp('Data extracted successfully from the "out" object.');
    else
        % Extract from base workspace (legacy or manual export)
        time_data = tout;
        I_abc_raw = cyber_current_B5;
        V_abc_raw = cyber_voltage_B5;
        f_class   = fault_classificaton;
        f_detect  = flag_detection;
        f_cyber   = flag_cyber; % [FIXED] Added missing extraction
        disp('Data extracted successfully from the base workspace.');
    end
catch ME
    error('Data extraction failed. Ensure the variables are in the workspace or inside the "out" object.');
end

% 2. Reshape 3-Phase Dimensions
% Squeeze removes the singleton dimension (3x1xN -> 3xN).
% The transpose (') flips it to Nx3 to align with the time column.
I_abc = squeeze(I_abc_raw)';
V_abc = squeeze(V_abc_raw)';

% [FIXED] Force all single-value arrays to be column vectors (Nx1)
% This prevents dimension mismatch errors in the table creation
f_class  = f_class(:);
f_detect = f_detect(:);
f_cyber  = f_cyber(:);

% 3. Create Table with "cyber" Prefixes
% [FIXED] Added the missing comma before 'VariableNames'
T = table(time_data, ...
    I_abc(:,1), I_abc(:,2), I_abc(:,3), ...
    V_abc(:,1), V_abc(:,2), V_abc(:,3), ...
    f_class, f_detect, f_cyber, ... 
    'VariableNames', { ...
        'Time', ...
        'cyber_I_PhaseA', 'cyber_I_PhaseB', 'cyber_I_PhaseC', ...
        'cyber_V_PhaseA', 'cyber_V_PhaseB', 'cyber_V_PhaseC', ...
        'fault_classification', 'flag_detection', 'flag_cyber'});

% 4. Export to CSV
filename = 'Cyber_Physical_System_Data.csv';
writetable(T, filename);
fprintf('Success: Data exported to %s\n', filename);