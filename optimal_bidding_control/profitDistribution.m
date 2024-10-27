%% Calculate and Distribute VPP Profit

%% VPP Income / Cost
% Income from the energy market
P_total = sum(result.p_dis - result.p_ch)'; % Exchanged power (energy every 2 seconds)
E_total = sum(reshape(P_total, 1800, [])) * delta_hat_t; % Exchanged hourly energy
distribution_der.vpp_income_e = E_total * param.price_e;

% Income from the ancillary market (delta_t = 1 hr)
distribution_der.vpp_income_as = param.price_reg' * result.Bid_reg_rev * param.s_perf + ...
    param.price_res' * result.Bid_res_rev;

% Response costs of the DERs
distribution_der.vpp_actualCost = sum(param_std.pr_dis' * result.p_dis) * delta_hat_t ...
    + sum(param_std.pr_ch' * result.p_ch) * delta_hat_t;

%% Distribute Income to the DERs

% Contribution of the DERs
% Capacity
distribution_der.alpha_cap = result.Cap_der_up_rev * result.lambda.cap_up + ...
    result.Cap_der_dn_rev * result.lambda.cap_dn;

% Ramping rate
distribution_der.alpha_R = result.R_der_up_rev * result.lambda.R_up + ...
    result.R_der_dn_rev * result.lambda.R_dn;

% Power balance
% Power allocation results
result.P_alloc = (result.p_dis - result.p_ch);
% Baseline output
result.command = result.P_alloc - reshape(repmat(result.P_bl_rev, 1800, 1), NOFDER, []);
% Check if the direction is consistent with the signal
temp_signal = Signal_day'; % Get the signal of the command
temp_signal(temp_signal < 0) = -1;
temp_signal(temp_signal > 0) = 1;
temp = result.command .* repmat(temp_signal, NOFDER, 1);

% Set the response in the opposite direction of the signal to 0
distribution_der.settle_response = result.command;
distribution_der.settle_response(temp < 0) = 0;

% Contribution
distribution_der.alpha_bal = (result.P_alloc - temp) * result.actualMarginalCost' * delta_hat_t;

% Revenue of the DERs
% Energy income
distribution_der.income_e = result.P_alloc * reshape(repmat(param.price_e', 1800, 1), [], 1) / 1800;

% Costs
distribution_der.actualCost = sum(repmat(param_std.pr_dis, 1, 43200) .* result.p_dis * delta_hat_t ...
    + repmat(param_std.pr_ch, 1, 43200) .* result.p_ch * delta_hat_t, 2);

distribution_der.profit = (distribution_der.vpp_income_as - distribution_der.vpp_actualCost) * ...
    (distribution_der.alpha_cap + distribution_der.alpha_R) / sum(distribution_der.alpha_cap + distribution_der.alpha_R);

% By the type of DERs
distribution_der.income_e = [distribution_der.income_e(1 : 2); ...
    sum(distribution_der.income_e(3 : end - NOFTCL)); sum(distribution_der.income_e(end - 2 : end))];
% By the type of DERs
distribution_der.actualCost = [distribution_der.actualCost(1 : 2); ...
    sum(distribution_der.actualCost(3 : end - NOFTCL)); sum(distribution_der.actualCost(end - 2 : end))];
% By the type of DERs
distribution_der.profit = [distribution_der.profit(1 : 2); ...
    sum(distribution_der.profit(3 : end - NOFTCL)); sum(distribution_der.profit(end - 2 : end))];
