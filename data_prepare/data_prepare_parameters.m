%% Read Other Resource Parameters
% All values need to be converted to MW units

%% Photovoltaic (PV)
load("output_pv.mat");
param.power_dis_upper_limit_pv = 0.0 * output_pv'; % 1MW capacity
param.power_dis_lower_limit_pv = 0 * output_pv';

%% Energy Storage (ES)
es_cap = 1; % Power capacity
param.energy_init_es = 0.4 * es_cap; % Initial energy
param.energy_upper_limit_es = 0.9 * es_cap; % Energy upper limit
param.energy_lower_limit_es = 0.1 * es_cap; % Energy lower limit
param.power_dis_upper_limit_es = 0.5 * es_cap; % Discharge power upper limit
param.power_dis_lower_limit_es = 0; % Discharge power lower limit
param.power_ch_upper_limit_es = 0.5 * es_cap; % Charge power upper limit
param.power_ch_lower_limit_es = 0; % Charge power lower limit
param.theta_es = 1; % Maintenance
param.eta_dis_es = 0.92; % Discharge efficiency
param.eta_ch_es = 0.92; % Charge efficiency
param.pr_dis_es = 40; % Discharge cost $/MWh
param.pr_ch_es = 40; % Charge cost $/MWh

%% Electric Vehicles (EV)
% Read EV arrival time from excel
filename = 'EV_arrive_leave.xlsx';
sheet = 'EV_arrive_leave'; % Current sheet
xlRange = 'A2:C121'; % Range

EV_arrive_leave = xlsread(filename, sheet, xlRange);
EV_arrive_leave = EV_arrive_leave(1 : 1000 : end, :); % Reduce problem scale for testing

ratio_ev = 1e-3 * 30;
ratio_ev1 = 0;
param.energy_init_ev = 20 * ratio_ev; % Initial energy
param.energy_end_ev = 50 * ratio_ev; % End energy
param.energy_upper_limit_ev = 60 * 0.9 * ratio_ev; % Energy upper limit, converting 60kWh to MWh
param.energy_lower_limit_ev = 60 * 0.1 * ratio_ev; % Energy lower limit
param.power_dis_upper_limit_ev = 7.68 * ratio_ev; % Discharge power upper limit
param.power_dis_lower_limit_ev = 0; % Discharge power lower limit
param.power_ch_upper_limit_ev = 7.68 * ratio_ev; % Charge power upper limit
param.power_ch_lower_limit_ev = 0; % Charge power lower limit
param.theta_ev = 1; % Maintenance
param.eta_dis_ev = 0.92; % Discharge efficiency
param.eta_ch_ev = 0.92; % Charge efficiency
param.pr_dis_ev = 100; % Discharge cost $/MWh
param.pr_ch_ev = 0; % Charge cost $/MWh

% Number of EVs
NOFEV = size(EV_arrive_leave, 1);
param.u = zeros(NOFEV, NOFSLOTS);
for idx = 1 : NOFEV
    for jdx = 1 : NOFSLOTS
        if EV_arrive_leave(idx, 2) <= jdx && jdx <= EV_arrive_leave(idx, 3)
            param.u(idx, jdx) = 1;
        end
    end
end

%% Temperature Controlled Loads (TCL)
load("h_load_temperature.mat"); % Outdoor temperature data
load("h_load.mat"); % Heat load data

tcl_c = [500]' * 1e-3; % Equivalent capacitance
tcl_r = [0.01]' * 1e3; % Equivalent resistance
tcl_cop = [3.6]'; % Coefficient of performance
h_load = [1]' * h_load(:, 2)';
param.power_ch_upper_limit_tcl = [1]'; % Charge power upper limit
param.power_ch_lower_limit_tcl =  [0]'; % Charge power lower limit

NOFTCL = size(tcl_c, 1);

T_ref = 28; % Temperature transformation T' = T_ref - T
param.energy_init_tcl = T_ref - 26; % Initial energy
param.energy_upper_limit_tcl = 3; % Energy upper limit
param.energy_lower_limit_tcl = 1; % Energy lower limit

gama = 1 ./ (tcl_c .* tcl_r);
alpha = ones(NOFTCL, 1) - gama;
beta = 1 ./ tcl_c;
param.theta_tcl = alpha; % Maintenance
param.eta_ch_tcl = beta .* tcl_cop; % Charge efficiency
h_load_temperature = ones(1, NOFSLOTS) * T_ref - h_load_temperature(:, 2)';
param.wOmiga = -repmat(beta, 1, NOFSLOTS) .* h_load - gama * h_load_temperature;

clear alpha beta EV_arrive_leave gama h_load h_load_temperature idx jdx load_parameter ...
    output_pv tcl_c tcl_cop tcl_r;
