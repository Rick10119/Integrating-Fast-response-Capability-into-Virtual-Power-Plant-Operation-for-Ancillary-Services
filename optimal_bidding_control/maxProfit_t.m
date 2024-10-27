%% Bidding Program Starting from Time Slot t. Calculate Shadow Prices of Battery Energy for the Next Time Slot Bidding Problem, Used for Allocation in the Current Time Slot

% For: Updating bidding amounts for the next time slots, updating Lagrange multipliers

% Input: Energy in each time slot, frequency regulation market prices; Time slots for electric vehicle arrival and departure, energy levels; Current time slot index t_cap; Bidding amounts for the current time slot
% Input: Current battery energy levels
% Initial Values: Bidding amounts in each time slot from the previous bidding, for time slots t + 1 to T, where t + 1 is the first entry
% Output: Bidding amounts and battery energy levels for future time slots t + 1 to T. Lagrange multiplier L for the next time slot

%% Parameter Setting

% More: See data_prepare.m

% Current time slot number CUR_SLOT
CUR_SLOT = ceil(t_cap / 1800); % 2s per slot, rounded up when divided by 1800, for the current time slot number
% Remaining time slots
REST_SLOTS = NOFSLOTS - CUR_SLOT;

% Read the winning bids and state values for the current time slot
Bid_reg_cur = result.Bid_reg_rev(CUR_SLOT);
Bid_res_cur = result.Bid_res_rev(CUR_SLOT);
Bid_p_cur = result.Bid_p_rev(CUR_SLOT);
result.Bid_reg_cur = result.Bid_reg_rev(CUR_SLOT);
result.Bid_p_cur = result.Bid_p_rev(CUR_SLOT);
E_cur = result.E_cur;

%% Variables
% Bidding capacity: Energy, Frequency regulation (MW), Reserve, from t + 1 to T, where t + 1 is the first entry
Bid_p = sdpvar(REST_SLOTS, 1, 'full');
Bid_reg = sdpvar(REST_SLOTS, 1, 'full');
Bid_res = sdpvar(REST_SLOTS, 1, 'full');

% DER Procurement Amount
Cap_der_up = sdpvar(NOFDER, REST_SLOTS, 'full'); % Upward regulation capacity purchased by VPP from DER
Cap_der_dn = sdpvar(NOFDER, REST_SLOTS, 'full'); % Downward regulation capacity purchased by VPP from DER
R_der_up = sdpvar(NOFDER, REST_SLOTS, 'full'); % Upward ramping capacity purchased by VPP from DER
R_der_dn = sdpvar(NOFDER, REST_SLOTS, 'full'); % Downward ramping capacity purchased by VPP from DER

% Auxiliary Variables
P_dis = sdpvar(NOFDER, REST_SLOTS + 1, NOFSCEN, 'full'); % Power discharged by DER in each scenario (kW), time remaining in the current time slot needs to be allocated, hence one extra time slot dimension
P_ch = sdpvar(NOFDER, REST_SLOTS + 1, NOFSCEN, 'full'); % Power charged by DER in each scenario (kW), time remaining in the current time slot needs to be allocated, hence one extra time slot dimension
% DER Baseline Power (kW)
P_bl = reshape(P_dis(:, :, ceil(NOFSCEN/2)) - P_ch(:, :, ceil(NOFSCEN/2)), NOFDER, REST_SLOTS + 1);
P_minus1 = reshape(P_dis(:, :, 1) - P_ch(:, :, 1), NOFDER, REST_SLOTS + 1); % Maximum charging
P_1 = reshape(P_dis(:, :, end) - P_ch(:, :, end), NOFDER, REST_SLOTS + 1); % Maximum discharging
Cap_der_up = P_1(:, 2 : end) - P_bl(:, 2 : end);
Cap_der_dn = P_bl(:, 2 : end) - P_minus1(:, 2 : end);

E = sdpvar(NOFDER, REST_SLOTS + 2, 'full'); % Initial battery energy of DER in each time slot. Includes current time, departure time, hence 2 extra dimensions
delta_E1 = sdpvar(NOFDER, REST_SLOTS + 1, 'full'); % Used for penalty calculation
delta_E2 = sdpvar(NOFDER, REST_SLOTS + 1, 'full'); % Used for penalty calculation
delta_E3 = sdpvar(NOFDER, REST_SLOTS, NOFSCEN, 'full'); % Used for penalty calculation
delta_E4 = sdpvar(NOFDER, REST_SLOTS, NOFSCEN, 'full'); % Used for penalty calculation

%% Objective Function

% Adjustment costs for future time slots and scenarios ($/h)
temp = permute(sum(repmat(param_std.pr_dis, 1, REST_SLOTS + 1, NOFSCEN) .* P_dis + ...
    repmat(param_std.pr_ch, 1, REST_SLOTS + 1, NOFSCEN) .* P_ch), [2, 3, 1]); % Aggregate DER power, swap rows and columns
temp = reshape(temp, REST_SLOTS + 1, NOFSCEN);

% Current time slot has only one segment left
Cost_deg = temp .* [delta_t_rest * ones(1, NOFSCEN); ones(REST_SLOTS, NOFSCEN)];

% Energy revenue, frequency regulation capacity revenue, frequency regulation mileage revenue, deployment cost, performance cost
Profit = param.price_e(CUR_SLOT + 1 : end)' * Bid_p + param.price_reg(CUR_SLOT + 1 : end)' * Bid_reg * param.s_perf + ...
    ((param.hourly_Distribution(CUR_SLOT + 1 : end, :) * param.d_s(:, 1)) .* param.price_e(CUR_SLOT + 1 : end))' * Bid_reg + ...
    ((param.hourly_Distribution(CUR_SLOT + 1 : end, :) * param.d_s(:, 2)) .* param.price_e(CUR_SLOT + 1 : end))' * Bid_res + ...
    param.price_res(CUR_SLOT + 1 : end)' * Bid_res - ...
    sum(sum(param.hourly_Distribution(CUR_SLOT : end, :) .* Cost_deg));

% Energy constraint penalty
Profit = Profit - 1e4 * sum(sum(delta_E1)) - 1e4 * sum(sum(delta_E2)) ...
    - 1e2 * sum(sum(sum(delta_E3))) - 1e2 * sum(sum(sum(delta_E4)));

%% Constraints

Constraints = [];

% Power limits (MW) NOFDER * REST_SLOTS * NOFSCEN
Constraints = [Constraints, repmat(param_std.power_dis_lower_limit(:, CUR_SLOT : end), 1, 1, NOFSCEN) <= P_dis];
Constraints = [Constraints, repmat(param_std.power_ch_lower_limit(:, CUR_SLOT : end), 1, 1, NOFSCEN) <= P_ch];
Constraints = [Constraints, P_dis <= repmat(param_std.power_dis_upper_limit(:, CUR_SLOT : end), 1, 1, NOFSCEN)];
Constraints = [Constraints, P_ch <= repmat(param_std.power_ch_upper_limit(:, CUR_SLOT : end), 1, 1, NOFSCEN)];

% Energy between maximum and minimum NOFDER * REST_SLOTS + 1
Constraints = [Constraints, param_std.energy_lower_limit(:, CUR_SLOT : end) <= E(:, 2 : end) + delta_E1];
Constraints = [Constraints, E(:, 2 : end) <= param_std.energy_upper_limit(:, CUR_SLOT : end) + delta_E2];
Constraints = [Constraints, 0 <= delta_E1];
Constraints = [Constraints, 0 <= delta_E2];

% Current energy, used to derive Lagrange multiplier
Constraints = [Constraints, E_cur - E(:, 1) == 0];

% Connection between adjacent time slots NOFDER * (REST_SLOTS + 1)
temp = repmat(param.hourly_Distribution(CUR_SLOT : end, :)', 1, NOFDER);
% Distribution repeated for SCEN * (SLOTS * DER)
temp_ch = permute(P_ch, [3, 2, 1]); % Swap rows and columns
temp_ch = reshape(temp_ch, NOFSCEN, (REST_SLOTS + 1) * NOFDER); % Flatten power to SCEN * (SLOTS * DER)
temp_ch = sum(temp_ch .* temp); % Multiply and sum weighted by probability
temp_ch = reshape(temp_ch, (REST_SLOTS + 1), NOFDER)'; % Rearrange to SLOTS * DER and transpose to DER * SLOTS

temp_dis = permute(P_dis, [3, 2, 1]); % Swap rows and columns
temp_dis = reshape(temp_dis, NOFSCEN, (REST_SLOTS + 1) * NOFDER); % Flatten power to SCEN * (SLOTS * DER)
temp_dis = sum(temp_dis .* temp); % Multiply and sum weighted by probability
temp_dis = reshape(temp_dis, (REST_SLOTS + 1), NOFDER)'; % Rearrange to SLOTS * DER and transpose to DER * SLOTS

Constraints = [Constraints, E(:, 3 : end) == repmat(param_std.theta, 1, REST_SLOTS) .* E(:, 2 : end - 1) ...
    + param_std.eta_ch * temp_ch(:, 2 : end) * delta_t ...
    - param_std.eta_dis * temp_dis(:, 2 : end) * delta_t ...
    + param_std.wOmiga(:, CUR_SLOT + 1 : end) * delta_t]; % Future time slots

Constraints = [Constraints, E(:, 2) == (ones(NOFDER, 1) - delta_t_rest * (ones(NOFDER, 1) - param_std.theta)) .* E(:, 1) ...
    + param_std.eta_ch * temp_ch(:, 1) * delta_t_rest ...
    - param_std.eta_dis * temp_dis(:, 1) * delta_t_rest ...
    + param_std.wOmiga(:, CUR_SLOT) * delta_t_rest]; % Current time slot

%% Ancillary Service Constraints
% Capacity constraints
% (7a, 7b) Aggregated capacity
Constraints = [Constraints, sum(Cap_der_up) >= Bid_res' + Bid_reg'];
Constraints = [Constraints, sum(Cap_der_dn) >= Bid_res'];
% (7c) Non-negative
Constraints = [Constraints, [Cap_der_dn, Cap_der_up] >= 0];
Constraints = [Constraints, [Bid_res, Bid_reg] >= 0];

% Power balance REST_SLOTS + 1 * NOFSCEN
temp = permute(sum(P_dis - P_ch), [2, 3, 1]); % Aggregate DER power
temp = reshape(temp, REST_SLOTS + 1, NOFSCEN);

Constraints = [Constraints, repmat([Bid_p_cur; Bid_p], 1, NOFSCEN) + ...
    repmat([Bid_reg_cur; Bid_reg], 1, NOFSCEN) .* repmat(param.d_s(:, 1)', REST_SLOTS + 1, 1) + ...
    repmat([Bid_res_cur; Bid_res], 1, NOFSCEN) .* repmat(param.d_s(:, 2)', REST_SLOTS + 1, 1) - temp == 0];

% Energy reserve ratio
for scen_idx = 1 : NOFSCEN
    Constraints = [Constraints, repmat((ones(NOFDER, 1) - delta_t_req * (ones(NOFDER, 1) - param_std.theta)), 1, REST_SLOTS) ...
        .* E(:, 2 : end - 1) - delta_t_req * param_std.eta_dis * P_dis(:, 2 : end, scen_idx) + delta_t_req * param_std.eta_ch * P_ch(:, 2 : end, scen_idx) ...
        + delta_t_req * param_std.wOmiga(:, CUR_SLOT + 1 : end) >= param_std.energy_lower_limit(:, [CUR_SLOT : end - 1]) - delta_E3(:, :, scen_idx)];

    % Charge: d_s = (-1, 0)
    Constraints = [Constraints, repmat((ones(NOFDER, 1) - delta_t_req * (ones(NOFDER, 1) - param_std.theta)), 1, REST_SLOTS) ...
        .* E(:, 2 : end - 1) - delta_t_req * param_std.eta_dis * P_dis(:, 2 : end, scen_idx) + delta_t_req * param_std.eta_ch * P_ch(:, 2 : end, scen_idx) ...
        + delta_t_req * param_std.wOmiga(:, CUR_SLOT + 1 : end) <= param_std.energy_upper_limit(:, [CUR_SLOT : end - 1]) + delta_E4(:, :, scen_idx)];
end

% Non-negative
Constraints = [Constraints, 0 == delta_E3];
Constraints = [Constraints, 0 == delta_E4];

% Ramp rate constraints
% Resource limit (10a)
Constraints = [Constraints, 0 <= [R_der_dn, R_der_up]];
Constraints = [Constraints, R_der_dn <= param_std.ramp_limit_dn(:, CUR_SLOT + 1 : end)];
Constraints = [Constraints, R_der_up <= param_std.ramp_limit_up(:, CUR_SLOT + 1 : end)];
% Capacity limit
Constraints = [Constraints, param.h_R * R_der_dn <= Cap_der_dn + Cap_der_up];
Constraints = [Constraints, param.h_R * R_der_up <= Cap_der_dn + Cap_der_up];
% Ramp rate demand
Constraints = [Constraints, sum(R_der_dn) >= (- param.epsilon_dn(CUR_SLOT + 1 : end) .* Bid_reg)'];
Constraints = [Constraints, sum(R_der_up) >= (param.epsilon_up(CUR_SLOT + 1 : end) .* Bid_reg + param.epsilon_res * Bid_res)'];

%% Solve
ops = sdpsettings('debug',0,'solver','gurobi','savesolveroutput',1,'savesolverinput',1,'verbose', 0);

sol = optimize(Constraints, - Profit, ops);

%% Record
if sol.problem == 0 || sol.problem == 4 % Successful optimization
    disp("Time Slot " + (CUR_SLOT) + " : Updated bidding completed. Time: " + t_cap)
    % Record, update bidding
    result.Bid_reg_rev(CUR_SLOT + 1 : end) = value(Bid_reg);
    result.Bid_res_rev(CUR_SLOT + 1 : end) = value(Bid_res);
    result.Bid_p_rev(CUR_SLOT + 1 : end) = value(Bid_p);

    % Update the cap of the DERs
    result.Cap_der_up_rev(:, CUR_SLOT + 1 : end) = value(Cap_der_up);
    result.Cap_der_dn_rev(:, CUR_SLOT + 1 : end) = value(Cap_der_dn);
    result.R_der_up_rev(:, CUR_SLOT + 1 : end) = value(R_der_up);
    result.R_der_dn_rev(:, CUR_SLOT + 1 : end) = value(R_der_dn);
    result.P_bl_rev(:, CUR_SLOT + 1 : end) = value(P_bl(:, 2 : end));
    result.P_ch_opt(:, CUR_SLOT + 1 : end, :) = value(P_ch(:, 2 : end, :));
    result.P_dis_opt(:, CUR_SLOT + 1 : end, :) = value(P_dis(:, 2 : end, :));

    % Lagrange multipliers
    pi = - sol.solveroutput.result.pi; % Negative for Gurobi
    result.lambda.e = pi(1 : NOFDER);

    temp1 = NOFSCEN * (REST_SLOTS + 1) * NOFDER;
    temp2 = (REST_SLOTS + 1) * NOFDER;
    temp_eq = NOFDER + NOFDER * (REST_SLOTS + 1) + NOFSCEN * (REST_SLOTS + 1);
    result.lambda_rev.cap_up(CUR_SLOT + 1 : end) = pi(temp_eq + temp1 * 4 + temp2 * 4 + 1 : ...
        temp_eq + temp1 * 4 + temp2 * 4 + REST_SLOTS);
    result.lambda_rev.cap_dn(CUR_SLOT + 1 : end) = pi(temp_eq + temp1 * 4 + temp2 * 4 + REST_SLOTS + 1 : ...
        temp_eq + temp1 * 4 + temp2 * 4 + 2 * REST_SLOTS);
    result.lambda_rev.R_dn(CUR_SLOT + 1 : end) = pi(end - 2 * REST_SLOTS + 1 : end - REST_SLOTS);
    result.lambda_rev.R_up(CUR_SLOT + 1 : end) = pi(end - REST_SLOTS + 1 : end);

else
    disp("Time Slot " + (CUR_SLOT) + " : Bidding optimization failed.")
end
