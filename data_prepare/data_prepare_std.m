%% Consolidate All Resources Parameters

% 1 PV  2 ES     3-42 EV  43-45 TCL    46-55 IPP
% All matrices except init/end should be 55*24
NOFDER = 1 + 1 + NOFEV + NOFTCL;

% Initial energy
param_std.energy_init = [ratio_ev1 * param.energy_init_ev; param.energy_init_es; ...
    param.energy_init_ev * ones(NOFEV, 1); ...
    param.energy_init_tcl * ones(NOFTCL, 1)];

% Energy upper limit
param_std.energy_upper_limit = [ratio_ev1 * param.energy_upper_limit_ev; param.energy_upper_limit_es; ...
    param.energy_upper_limit_ev * ones(NOFEV, 1); ...
    param.energy_upper_limit_tcl * ones(NOFTCL, 1)];
param_std.energy_upper_limit = repmat(param_std.energy_upper_limit, 1, NOFSLOTS);

% Ending energy limit
param_std.energy_end =  [ratio_ev1 * param.energy_end_ev; param.energy_init_es; ...
    param.energy_end_ev * ones(NOFEV, 1); ...
    param.energy_lower_limit_tcl * ones(NOFTCL, 1)];

% Energy lower limit
param_std.energy_lower_limit = [ratio_ev1 * param.energy_lower_limit_ev; param.energy_lower_limit_es; ...
    param.energy_lower_limit_ev * ones(NOFEV, 1); ...
    param.energy_lower_limit_tcl * ones(NOFTCL, 1)];
param_std.energy_lower_limit = [repmat(param_std.energy_lower_limit, 1, 23), ...
    param_std.energy_end];

% Discharging power upper limit
param_std.power_dis_upper_limit = [ratio_ev1 * repmat(param.power_dis_upper_limit_ev, 1, NOFSLOTS) .* param.u; ...
    repmat(param.power_dis_upper_limit_es, 1, NOFSLOTS); ...
    repmat(param.power_dis_upper_limit_ev, NOFEV, NOFSLOTS) .* param.u; ...
    zeros(NOFTCL, NOFSLOTS)];
% Discharging power lower limit
param_std.power_dis_lower_limit = zeros(size(param_std.power_dis_upper_limit));
% Charging power upper limit
param_std.power_ch_upper_limit =  [ratio_ev1 * repmat(param.power_ch_upper_limit_ev, NOFEV, NOFSLOTS) .* param.u; ...
    repmat(param.power_ch_upper_limit_es, 1, NOFSLOTS); ...
    repmat(param.power_ch_upper_limit_ev, NOFEV, NOFSLOTS) .* param.u; ...
    repmat(param.power_ch_upper_limit_tcl, 1, NOFSLOTS)];
% Charging power lower limit
param_std.power_ch_lower_limit = zeros(size(param_std.power_ch_upper_limit));
% Holding cost
param_std.theta = [1; ones(1 + NOFEV, 1); ...
    param.theta_tcl];
% Discharging efficiency
param_std.eta_dis = zeros(NOFDER, NOFDER);
param_std.eta_dis(2, 2) = 1 / param.eta_dis_es;
for idx = 3 : 2 + NOFEV % Electric Vehicles
    param_std.eta_dis(idx, idx) = 1 / param.eta_dis_ev;
end
param_std.eta_dis(1, 1) = 1 / param.eta_dis_ev;

% Charging efficiency
param_std.eta_ch = zeros(NOFDER, NOFDER);
param_std.eta_ch(2, 2) = param.eta_ch_es;
for idx = 3 : 2 + NOFEV % Electric Vehicles
    param_std.eta_ch(idx, idx) = param.eta_ch_ev;
end
param_std.eta_ch(1, 1) = param.eta_ch_ev;
for idx = 3 + NOFEV : 2 + NOFEV + NOFTCL % Temperature Control Load
    param_std.eta_ch(idx, idx) = param.eta_ch_tcl(idx - 2 - NOFEV);
end

% Discharging cost $/MWh
param_std.pr_dis = [param.pr_dis_ev; param.pr_dis_es; ...
    repmat(param.pr_dis_ev, NOFEV, 1); ...
    zeros(NOFTCL, 1)];
% Charging cost $/MWh
param_std.pr_ch = [param.pr_ch_ev; param.pr_ch_es; ...
    repmat(param.pr_ch_ev, NOFEV, 1); ...
    zeros(NOFTCL, 1)];

% External influences
param_std.wOmiga = [zeros(2 + NOFEV, NOFSLOTS); ...
    param.wOmiga];

% Modify the lowest energy level of EV when leaving a time slot
for idx = 1 : NOFEV
    for jdx = 1 : NOFSLOTS - 1
        if param.u(idx, jdx) - param.u(idx, jdx + 1) == 1 % Next time slot
            param_std.energy_lower_limit(2 + idx, jdx) = param_std.energy_end(2 + idx);
        end
    end
end

% Modify the lowest energy level of EV before leaving the previous time slot
for idx = 1 : NOFEV
    for jdx = 1 : NOFSLOTS - 1
        if param.u(idx, jdx) - param.u(idx, jdx + 1) == 1 % Next time slot
            param_std.energy_lower_limit(2 + idx, jdx - 1) = ...
                param_std.energy_end(2 + idx) - ...
                param_std.power_ch_upper_limit(2 + idx, jdx) * 0.92;
            param_std.energy_lower_limit(2 + idx, jdx - 2) = ...
                param_std.energy_end(2 + idx) - ...
                param_std.power_ch_upper_limit(2 + idx, jdx) * 0.92 * 2;
        end
    end
end

param_std.energy_lower_limit(1, :) = ratio_ev1 * param_std.energy_lower_limit(3, :);

% Ramp rate capability of the resources (MW/min)
% PV, ES, EV: equals 6 times the power capacity (reach any power within 5 seconds)
param_std.ramp_limit_up = 12 * max(param_std.power_dis_upper_limit, param_std.power_ch_upper_limit);
param_std.ramp_limit_dn = param_std.ramp_limit_up;

% TCL: 10% of the power capacity
for idx = 3 + NOFEV : 2 + NOFEV + NOFTCL % Electric Vehicles
    param_std.ramp_limit_up(idx, :) = 1/10 * max(param_std.power_dis_upper_limit(idx, :), param_std.power_ch_upper_limit(idx, :));
    param_std.ramp_limit_dn(idx, :) = param_std.ramp_limit_up(idx, :);
end
