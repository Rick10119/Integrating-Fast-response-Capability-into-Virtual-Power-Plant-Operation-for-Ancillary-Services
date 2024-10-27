%% prepare the parameters for fast control

%% input
% obtain the L multiplier for energy state
lambda_e = result.lambda_rev.e;

% current time slot CUR_SLOT
CUR_SLOT = ceil(t_cap / 1800);% 2s for each t_hat, 1800 signals in one hour

% read the updated bid / energy / power for the current time slot
Bid_reg_cur = result.Bid_reg_rev(CUR_SLOT);
Bid_res_cur = result.Bid_res_rev(CUR_SLOT);
Bid_p_cur = result.Bid_p_rev(CUR_SLOT);
E_cur = result.E_cur;
p_dis_cur = result.p_dis_cur;
p_ch_cur = result.p_ch_cur;

% beginning of slot, set power to baseline
if delta_t_rest == 1
    p_dis_cur = 1/2 *(abs(result.P_bl_rev(:, CUR_SLOT)) + result.P_bl_rev(:, CUR_SLOT));
    p_ch_cur = 1/2 *(abs(result.P_bl_rev(:, CUR_SLOT)) - result.P_bl_rev(:, CUR_SLOT));
end

% update the segment parameters
% optimized max power
% scen_idx = 1 : NOFSCEN;
scen_idx = 1 : 22;
p_dis_minus1 = min(reshape(result.P_dis_opt(:, CUR_SLOT, scen_idx), NOFDER, [])')';
p_ch_minus1 = max(reshape(result.P_ch_opt(:, CUR_SLOT, scen_idx), NOFDER, [])')';
p_dis_1 = max(reshape(result.P_dis_opt(:, CUR_SLOT, scen_idx), NOFDER, [])')';
p_ch_1 = min(reshape(result.P_ch_opt(:, CUR_SLOT, scen_idx), NOFDER, [])')';% floor([]/2)


%% parameters
delta_hat_t = NOFTCAP_ctrl / 1800;% h

%% form the power limits

% Equ. (14)
p_dis_lower_hat_t = max([param_std.power_dis_lower_limit(:, CUR_SLOT), p_dis_minus1, ...
    p_dis_cur - param_std.ramp_limit_dn(:, CUR_SLOT) * delta_hat_t * 60], [], 2);% by the column

p_dis_upper_hat_t = min([p_dis_1, ...
    p_dis_cur + param_std.ramp_limit_up(:, CUR_SLOT) * delta_hat_t * 60], [], 2);% by the column

p_ch_lower_hat_t = max([param_std.power_ch_lower_limit(:, CUR_SLOT), p_ch_1, ...
    p_ch_cur - param_std.ramp_limit_up(:, CUR_SLOT) * delta_hat_t * 60], [], 2);% by the column

p_ch_upper_hat_t = min([p_ch_minus1, ...
    p_ch_cur + param_std.ramp_limit_dn(:, CUR_SLOT) * delta_hat_t * 60], [], 2);% by the column

% to avoid simultaneous discharging and charging
p_dis_upper_hat_t(find(p_ch_cur > 0)) = 0;
p_ch_upper_hat_t(find(p_dis_cur > 0)) = 0;

% modify for feasibility
temp = find((1/0.9 * param_std.energy_upper_limit(:, CUR_SLOT) - E_cur)<0);% state exceeding limit
p_dis_lower_hat_t(temp) = p_dis_upper_hat_t(temp);%
p_ch_upper_hat_t(temp) = p_ch_lower_hat_t(temp);

temp = find((1e-1 * param_std.energy_lower_limit(:, CUR_SLOT) - E_cur)>0);% state lower than limit
p_ch_lower_hat_t(temp) = p_ch_upper_hat_t(temp);
p_dis_upper_hat_t(temp) = p_dis_lower_hat_t(temp);%

temp = find(p_dis_upper_hat_t < p_dis_lower_hat_t);
p_dis_lower_hat_t(temp) = p_dis_upper_hat_t(temp);

temp = find(p_ch_upper_hat_t < p_ch_lower_hat_t);
p_ch_lower_hat_t(temp) = p_ch_upper_hat_t(temp);

% setting punishment for energy state lower than threshold
temp = find((0.99 * param_std.energy_upper_limit(:, CUR_SLOT) - E_cur)<0);% state exceeding limit
lambda_e(temp) = 1e3;
temp = find(1.01 * (param_std.energy_lower_limit(:, CUR_SLOT) - E_cur)>0);% state lower than limit
lambda_e(temp) = -1e1;% -1e3 for ev_ic


%% form the matrix
% entries for each row : (index, flag_ch, c_k, p_lower, p_upper)
% discharging segments
param_std.seg_parameter(1 : NOFDER, 1 : 5) = [[1 : NOFDER]', zeros(NOFDER, 1), ...
    param_std.pr_dis - param_std.eta_dis * lambda_e, ...
    p_dis_lower_hat_t, ...
    p_dis_upper_hat_t];

% charging segments
param_std.seg_parameter(NOFDER + 1 : 2 * NOFDER, 1 : 5) = [[1 : NOFDER]', ones(NOFDER, 1), ...
    - param_std.pr_ch - param_std.eta_ch * lambda_e, ...
    - p_ch_upper_hat_t, ...
    - p_ch_lower_hat_t];


%% sort by the cost

param_std.seg_parameter = sortrows(param_std.seg_parameter, 3);
