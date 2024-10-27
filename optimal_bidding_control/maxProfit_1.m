%% Bidding Program Starting from Time Slot 1

% For: 1. Initial value generation; 2. Calculation of Lagrange multipliers

% Input: Energy in each time slot, frequency regulation market prices; Time slots for electric vehicle arrival and departure, energy levels;
% Output: Bidding amounts in each time slot, battery energy levels

%% Parameter Setting

% See data_prepare_main.m

%% Variable Definitions
% Bidding capacity: Energy, Frequency regulation (MW), Reserve
Bid_p = sdpvar(NOFSLOTS, 1, 'full');
Bid_reg = sdpvar(NOFSLOTS, 1, 'full');
Bid_res = sdpvar(NOFSLOTS, 1, 'full');

% DER Procurement Amount
Cap_der_up = sdpvar(NOFDER, NOFSLOTS, 'full'); % Upward regulation capacity purchased by VPP from DER
Cap_der_dn = sdpvar(NOFDER, NOFSLOTS, 'full'); % Downward regulation capacity purchased by VPP from DER
R_der_up = sdpvar(NOFDER, NOFSLOTS, 'full'); % Upward ramping capacity purchased by VPP from DER
R_der_dn = sdpvar(NOFDER, NOFSLOTS, 'full'); % Downward ramping capacity purchased by VPP from DER

% Auxiliary Variables
P_dis = sdpvar(NOFDER, NOFSLOTS, NOFSCEN, 'full'); % Power discharged by DER in each scenario (kW)
P_ch = sdpvar(NOFDER, NOFSLOTS, NOFSCEN, 'full'); % Power charged by DER in each scenario (kW)
% DER Baseline Power (kW)
P_bl = reshape(P_dis(:, :, ceil(NOFSCEN/2)) - P_ch(:, :, ceil(NOFSCEN/2)), NOFDER, NOFSLOTS);
P_minus1 = reshape(P_dis(:, :, 1) - P_ch(:, :, 1), NOFDER, NOFSLOTS); % Maximum charging
P_1 = reshape(P_dis(:, :, end) - P_ch(:, :, end), NOFDER, NOFSLOTS); % Maximum discharging
% (7a) Power Limits
Cap_der_up = P_1 - P_bl;
Cap_der_dn = P_bl - P_minus1;

E = sdpvar(NOFDER, NOFSLOTS + 1, 'full'); % Initial battery energy of DER in each time slot. Includes departure time (beginning of time slot), hence one extra dimension

%% Objective Function

% Cost due to power NOFSLOTS * NOFSCEN
temp = permute(sum(repmat(param_std.pr_dis, 1, NOFSLOTS, NOFSCEN) .* P_dis + ...
    repmat(param_std.pr_ch, 1, NOFSLOTS, NOFSCEN) .* P_ch), [2, 3, 1]); % Aggregate DER power, swap rows and columns
temp = reshape(temp, NOFSLOTS, NOFSCEN);

Cost_deg = temp; % Aging cost for each time slot and scenario ($)

% Energy revenue, frequency regulation capacity revenue, frequency regulation mileage revenue, deployment cost, performance cost
Profit = param.price_e' * Bid_p + param.price_reg' * Bid_reg * param.s_perf + ...
    ((param.hourly_Distribution * param.d_s(:, 1)) .* param.price_e)' * Bid_reg + ...
    ((param.hourly_Distribution * param.d_s(:, 2)) .* param.price_e)' * Bid_res + ...
    param.price_res' * Bid_res - ...
    sum(sum(param.hourly_Distribution .* Cost_deg));
% Multiply by time slot length
Profit = Profit * delta_t;

%% Constraints

Constraints = [];

%% DER Operation Constraints
% Power limits (MW) NOFDER * NOFSLOTS * NOFSCEN
Constraints = [Constraints, repmat(param_std.power_dis_lower_limit, 1, 1, NOFSCEN) <= P_dis];
Constraints = [Constraints, repmat(param_std.power_ch_lower_limit, 1, 1, NOFSCEN) <= P_ch];
Constraints = [Constraints, P_dis <= repmat(param_std.power_dis_upper_limit, 1, 1, NOFSCEN)];
Constraints = [Constraints, P_ch <= repmat(param_std.power_ch_upper_limit, 1, 1, NOFSCEN)];

% Energy limits
% Energy in intermediate time slots should be between maximum and minimum NOFDER * NOFSLOTS
Constraints = [Constraints, param_std.energy_lower_limit <= E(:, 2 : end)];
Constraints = [Constraints, E(:, 2 : end) <= param_std.energy_upper_limit];

% Initial energy state NOFDER
Constraints = [Constraints, param_std.energy_init - E(:, 1) == 0];

% Connection between adjacent time slots NOFDER * NOFSLOTS
% Avoid no cost regarding (0, 0)
param.hourly_Distribution(:, ceil(NOFSCEN/2)) = 1e-3;
temp = repmat(param.hourly_Distribution', 1, NOFDER);
% Repeat distribution for SCEN * (SLOTS * DER)
temp_ch = permute(P_ch, [3, 2, 1]); % Swap rows and columns
temp_ch = reshape(temp_ch, NOFSCEN, NOFSLOTS * NOFDER); % Flatten power to SCEN * (SLOTS * DER)
temp_ch = sum(temp_ch .* temp); % Multiply and sum weighted by probability
temp_ch = reshape(temp_ch, NOFSLOTS, NOFDER)'; % Rearrange to SLOTS * DER and transpose to DER * SLOTS

temp_dis = permute(P_dis, [3, 2, 1]); % Swap rows and columns
temp_dis = reshape(temp_dis, NOFSCEN, NOFSLOTS * NOFDER); % Flatten power to SCEN * (SLOTS * DER)
temp_dis = sum(temp_dis .* temp); % Multiply and sum weighted by probability
temp_dis = reshape(temp_dis, NOFSLOTS, NOFDER)'; % Rearrange to SLOTS * DER and transpose to DER * SLOTS

Constraints = [Constraints, E(:, 2 : end) == repmat(param_std.theta, 1, NOFSLOTS) .* E(:, 1 : end - 1) ...
    + param_std.eta_ch * temp_ch * delta_t ...
    - param_std.eta_dis * temp_dis * delta_t ...
    + param_std.wOmiga * delta_t];

%% Ancillary Service Constraints
% Capacity constraints
% (7a, 7b) Aggregated capacity
Constraints = [Constraints, sum(Cap_der_up) >= Bid_res' + Bid_reg'];
Constraints = [Constraints, sum(Cap_der_dn) >= Bid_res'];
% (7c) Non-negative
Constraints = [Constraints, [Cap_der_dn, Cap_der_up] >= 0];
Constraints = [Constraints, [Bid_res, Bid_reg] >= 0];

% Power balance NOFSLOTS * NOFSCEN
temp = permute(sum(P_dis - P_ch), [2, 3, 1]); % Aggregate DER power
temp = reshape(temp, NOFSLOTS, NOFSCEN);

Constraints = [Constraints, repmat(Bid_p, 1, NOFSCEN) + ...
    repmat(Bid_reg, 1, NOFSCEN) .* repmat(param.d_s(:, 1)', NOFSLOTS, 1) + ...
    repmat(Bid_res, 1, NOFSCEN) .* repmat(param.d_s(:, 2)', NOFSLOTS, 1) - temp == 0];

% Energy reserve ratio
% Discharge: d_s = (1, 1)
for scen_idx = 1 : NOFSCEN
    Constraints = [Constraints, repmat((ones(NOFDER, 1) - delta_t_req * (ones(NOFDER, 1) - param_std.theta)), 1, NOFSLOTS) ...
        .* E(:, 1 : end - 1) - delta_t_req * param_std.eta_dis * P_dis(:, :, scen_idx) + delta_t_req * param_std.eta_ch * P_ch(:, :, scen_idx) ...
        + delta_t_req * param_std.wOmiga >= param_std.energy_lower_limit(:, [1, 1 : end - 1])];

    % Charge: d_s = (-1, 0)
    Constraints = [Constraints, repmat((ones(NOFDER, 1) - delta_t_req * (ones(NOFDER, 1) - param_std.theta)), 1, NOFSLOTS) ...
        .* E(:, 1 : end - 1) - delta_t_req * param_std.eta_dis * P_dis(:, :, scen_idx) + delta_t_req * param_std.eta_ch * P_ch(:, :, scen_idx) ...
        + delta_t_req * param_std.wOmiga <= param_std.energy_upper_limit(:, [1, 1 : end - 1])];
end

% Ramp rate constraints
% Resource limit (10a)
Constraints = [Constraints, 0 <= [R_der_dn, R_der_up]];
Constraints = [Constraints, R_der_dn <= param_std.ramp_limit_dn];
Constraints = [Constraints, R_der_up <= param_std.ramp_limit_up];
% Capacity limit
Constraints = [Constraints, param.h_R * R_der_dn <= Cap_der_dn + Cap_der_up];
Constraints = [Constraints, param.h_R * R_der_up <= Cap_der_dn + Cap_der_up];
% Ramp rate demand
Constraints = [Constraints, sum(R_der_dn) >= (- param.epsilon_dn .* Bid_reg)'];
Constraints = [Constraints, sum(R_der_up) >= (param.epsilon_up .* Bid_reg + param.epsilon_res * Bid_res)']; % 0.1 /min for reserve

%% Solve
ops = sdpsettings('debug',0,'solver','gurobi','savesolveroutput',1,'savesolverinput',0,'verbose', 0);

sol = optimize(Constraints, - Profit, ops);

if sol.problem == 0 % Successful optimization
    disp("Time Slot 1: Bidding completed.")
else
    disp("Time Slot 1: Bidding failed.")
end

%% Recording
% Bids
result.Bid_reg_init = value(Bid_reg);
result.Bid_res_init = value(Bid_res);
result.Bid_p_init = value(Bid_p);
result.E_init = value(E);
result.Bid_reg_cur = value(Bid_reg(1));
result.Bid_res_cur = value(Bid_res(1));
result.Bid_p_cur = value(Bid_p(1));
result.E_cur = value(E(:, 1));
result.Income_init = value(Profit + sum(sum(param.hourly_Distribution .* Cost_deg)));

% Capabilities of the DERs
result.Cap_der_up_init = value(Cap_der_up);
result.Cap_der_dn_init = value(Cap_der_dn);
result.R_der_up_init = value(R_der_up);
result.R_der_dn_init = value(R_der_dn);
result.P_bl_init = value(P_bl);
result.Cap_der_up_rev = value(Cap_der_up);
result.Cap_der_dn_rev = value(Cap_der_dn);
result.R_der_up_rev = value(R_der_up);
result.R_der_dn_rev = value(R_der_dn);
result.P_bl_rev = value(P_bl);
result.P_ch_opt = value(P_ch);
result.P_dis_opt = value(P_dis);

% Lagrange multipliers
pi = - sol.solveroutput.result.pi; % Negative for Gurobi
result.lambda.e = pi(1 : NOFDER);

temp1 = NOFSCEN * NOFSLOTS * NOFDER;
temp2 = NOFSLOTS * NOFDER;
temp_eq = NOFDER + NOFDER * NOFSLOTS + NOFSLOTS * NOFSCEN;
result.lambda.cap_up = pi(temp_eq + temp1 * 4 + temp2 * 2 + 1 : ...
    temp_eq + temp1 * 4 + temp2 * 2 + NOFSLOTS);
result.lambda.cap_dn = pi(temp_eq + temp1 * 4 + temp2 * 2 + NOFSLOTS + 1 : ...
    temp_eq + temp1 * 4 + temp2 * 2 + 2 * NOFSLOTS);
result.lambda.R_dn = pi(end - 2 * NOFSLOTS + 1 : end - NOFSLOTS);
result.lambda.R_up = pi(end - NOFSLOTS + 1 : end);

% For future reference
result.Bid_reg_rev = value(Bid_reg);
result.Bid_res_rev = value(Bid_res);
result.Bid_p_rev = value(Bid_p);
result.E_rev = [result.E_cur, zeros(NOFDER, length(Signal_day))];
result.lambda_rev = result.lambda;

% Record the actual power
result.p_dis = zeros(NOFDER, length(Signal_day));
result.p_ch = zeros(NOFDER, length(Signal_day));
result.p_dis_cur = 0.5 * (value(P_bl(:, 1)) + abs(value(P_bl(:, 1)))); % Baseline
result.p_ch_cur = 0.5 * (- value(P_bl(:, 1)) + abs(value(P_bl(:, 1))));
result.actualMarginalCost = zeros(1, length(Signal_day));
param_std.seg_parameter = zeros(2 * NOFDER, 6);
