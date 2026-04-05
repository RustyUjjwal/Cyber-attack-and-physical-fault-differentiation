clc;clear;close all;
% This script prepares a cyber-attack that only targets the Voltage sensor,
% which your V-I relay will successfully catch!

define_constants;
mpc = loadcase('case14');
opt = mpoption('out.all', 0);
results = runpf(mpc, opt);

% Extract baseline state and system matrices
V_mag = results.bus(:, VM);
Theta = results.bus(:, VA) * (pi/180);
V_complex = V_mag .* exp(1j * Theta); 
[Ybus, Yf, Yt] = makeYbus(mpc.baseMVA, mpc.bus, mpc.branch);
[dSbus_dVm, dSbus_dVa] = dSbus_dV(Ybus, V_complex);

% Design the VOLTAGE Attack Vector
num_buses = size(mpc.bus, 1);
c_voltage = zeros(num_buses, 1);
target_bus = 10; % Change this to 4 if you wanted to attack Bus 4!
c_voltage(target_bus) = -0.15; % Fake a 0.15 p.u. voltage drop

% Calculate required MW spoofing to hide from SCADA
J_P_Vm = real(dSbus_dVm); 
a_power_injection = J_P_Vm * c_voltage;

disp('--- FDI Attack Vector Calculated (Voltage Only) ---');
compromised_sensors = find(abs(a_power_injection) > 1e-4); 
for i = 1:length(compromised_sensors)
    bus_num = compromised_sensors(i);
    fprintf('Hack Sensor at Bus %d: Change reading by %.4f p.u.\n', bus_num, a_power_injection(bus_num));
end

% --- DYNAMIC SIMULINK INJECTION SETUP ---
attack_voltage_pu = c_voltage(target_bus); % The -0.15 p.u. signal
attack_trigger_time = 0.2; % Strikes at 0.2s

disp(' ');
disp('>> SINGLE-SENSOR ATTACK ARMED:');
disp(['   - Faking a ', num2str(attack_voltage_pu), ' p.u. Voltage Drop']);
disp(['   - Striking at t = ', num2str(attack_trigger_time), 's']);