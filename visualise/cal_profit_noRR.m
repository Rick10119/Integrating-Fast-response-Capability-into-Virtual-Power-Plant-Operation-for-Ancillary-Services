% Calculate the income of the resources and the VPP noRR

% Proportional allocation
for resource_idx = resource_idx_range % 5 for the VPP

    % Resource name
    temp = ["pv", "es", "ev", "tcl", ""];
    resource_name = temp(resource_idx);

    % Load data
    load("../results_basic/result_noRR_ctrl_sep_" + resource_name + ".mat");

    % Calculate the performance score
    cal_perf_score_pjm;
    % cal_perf_score_nyiso;

    % Modify the income from the AS market
    % Income from the ancillary market (delta_t = 1 hr)
    distribution_der.vpp_income_as =  (param.price_reg .* score.S .* score.Cap_mdf)' * result.Bid_reg_rev + ...
        param.price_res' * result.Bid_res_rev;

    % Update the F score
    f_der = ones(NOFDER, 1);

    % Income
    % Actual energy income
    income_e = result.P_alloc * reshape(repmat(param.price_e', 1800, 1), [], 1) / 1800;

    % Reported costs
    delta_hat_t = 1/1800;
    actualCost = sum(repmat(param_std.pr_dis, 1, 43200) .* result.p_dis * delta_hat_t ...
        + repmat(param_std.pr_ch, 1, 43200) .* result.p_ch * delta_hat_t, 2);

    % Change of income - energy
    distribution_der.v_der = orig_energy_income - orig_cost ...
        - income_e + actualCost;

    % Profit share
    distribution_der.profit = (distribution_der.vpp_income_as - sum(distribution_der.v_der)) * ...
        f_der .* (distribution_der.alpha_cap + distribution_der.alpha_R) / sum(f_der .* distribution_der.alpha_cap + f_der .* distribution_der.alpha_R);

    % Pay
    distribution_der.Pay = distribution_der.v_der + distribution_der.profit;

    % Real profit
    distribution_der.Profit_der = distribution_der.Pay - actualCost ...
        + income_e;

    % Profit change
    distribution_der.Profit_change_der = distribution_der.Pay - actualCost ...
        + income_e - orig_energy_income + orig_cost;

    % By type-noCO
    temp = income_e;
    temp = [temp(1:2); sum(temp(3 : end - NOFTCL)); ...
        sum(temp(end - NOFTCL + 1 : end)); sum(temp)];
    energy_income_by_type(resource_idx) = temp(resource_idx);

    as_income_by_type(resource_idx) = distribution_der.vpp_income_as;

    temp = actualCost;
    temp = [temp(1:2); sum(temp(3 : end - NOFTCL)); ...
        sum(temp(end - NOFTCL + 1 : end)); sum(temp)];
    cost_by_type(resource_idx) = temp(resource_idx);

    score_by_type_avg(resource_idx) = score.S_avg;
    score_by_type_min(resource_idx) = min(score.S);

end

as_profit = energy_income_by_type + as_income_by_type - cost_by_type - orig_energy_income_by_type;

a_total_table_noRR = [energy_income_by_type, score_by_type_avg, score_by_type_min, ...
    as_income_by_type, cost_by_type, as_profit];
